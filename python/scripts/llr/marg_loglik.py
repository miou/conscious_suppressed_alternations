# %%
# Compute marginal log-likelihood of one-state and two-state models

# %%
# Imports

import argparse
import json
from pathlib import Path

import joblib
import numpy as np
import pandas as pd
import yaml

from percept_hmm.fixed_hmm import bin_trial
from percept_hmm.flash_suppression import TrialData
from percept_hmm.models.pmm import loglik_pois
from percept_hmm.pipelines.dataio import rec_fname
from percept_hmm.pipelines.fs_rivalry import stim_priming_responses
from percept_hmm.pipelines.llr import shuffle_spikes
from percept_hmm.utils import timex

# %%
# Helper functions for calculating log-likelihood


def calc_mll_one_state(spikes: np.ndarray, rates: np.ndarray) -> float:
    """Compute marginal log-likelihood per neuron of one-state model on spikes"""

    # Get rate vector for each time bin
    nt, nn = spikes.shape
    rates_full = np.tile(rates, (nt, 1))

    # Calculate log-likelihood for each time bin given single rate vector
    loglik_time = loglik_pois(spikes, rates_full)

    # Because time bins are independent, add log-likelihoods together for trial log-likelihood
    loglik_trial = np.sum(loglik_time)

    # Normalize by number of units
    loglik_norm = loglik_trial / nn

    return loglik_norm


def calc_mll_two_state(spikes: np.ndarray, rates_1: np.ndarray, rates_2: np.ndarray) -> float:
    """Compute marginal log-likelihood per neuron of two-state model on spikes"""

    # Get rate vector for each time bin
    nt, nn = spikes.shape
    rates_full_1 = np.tile(rates_1, (nt, 1))
    rates_full_2 = np.tile(rates_2, (nt, 1))

    # Calculate marginal log-likelihood for each time bin under two-state model, assuming prior
    # probabilities are [0.5, 0.5]. Using logaddexp to avoid underflow when per-bin log-likelihoods
    # (summed across units) are large and negative.
    loglik_time_1 = loglik_pois(spikes, rates_full_1)
    loglik_time_2 = loglik_pois(spikes, rates_full_2)
    loglik_marg_time = np.logaddexp(loglik_time_1, loglik_time_2) + np.log(0.5)

    # Because time bins are independent, add log-likelihoods together for trial log-likelihood
    loglik_marg_trial = np.sum(loglik_marg_time)

    # Normalize by number of units
    loglik_marg_norm = loglik_marg_trial / nn

    return loglik_marg_norm


def mll_session(
    fs_data: dict[tuple[int, int], list[TrialData]],
    resp_prime: dict[int, np.ndarray],
    bin_size: int,
    win_start: int,
    win_stop: int,
    r_floor: float,
    rng_seed: int,
) -> dict[tuple[int, int], list[dict]]:

    rng = np.random.default_rng(rng_seed)
    loglik_dict = {}
    for (r, c), trials in fs_data.items():
        # Get binocular trials with indices
        trials_binoc_full = [
            (trial['spikes'], trial['trial_index'])
            for trial in trials
            if trial['trial_type'] == 'binocular'
        ]
        if len(trials_binoc_full) < 2:
            print(
                f'Only {len(trials_binoc_full)} binocular trials for stimulus pair ({r, c}). Skipping...'
            )
            continue

        # Extract window and bin spikes (keeping indices)
        trials_binoc = []
        for spk, idx in trials_binoc_full:
            spk_win = spk[win_start:win_stop, :]
            spk_bin = bin_trial(spk_win, bin_size)
            trials_binoc.append((spk_bin, idx))

        # Split into random subsets
        rng.shuffle(trials_binoc)
        split_point = len(trials_binoc) // 2
        trials_binoc_1 = trials_binoc[:split_point]
        trials_binoc_2 = trials_binoc[split_point:]

        # Compute marginal likelihood of two-state model
        r_red = resp_prime[r] * bin_size
        r_cyan = resp_prime[c] * bin_size
        loglik_two_state = []
        for spk, idx in trials_binoc_1 + trials_binoc_2:
            ll = calc_mll_two_state(spk, r_red, r_cyan)
            loglik_two_state.append((ll, idx))

        # Compute marginal likelihood of one-state model on first set using mean from second
        loglik_one_state = []
        r_avg_1 = np.mean(np.concatenate([x[0] for x in trials_binoc_1], axis=0), axis=0)
        r_avg_2 = np.mean(np.concatenate([x[0] for x in trials_binoc_2], axis=0), axis=0)
        b_floor = r_floor * bin_size
        r_avg_1[r_avg_1 < b_floor] = b_floor
        r_avg_2[r_avg_2 < b_floor] = b_floor
        for spk, idx in trials_binoc_1:
            ll = calc_mll_one_state(spk, r_avg_2)
            loglik_one_state.append((ll, idx))
        for spk, idx in trials_binoc_2:
            ll = calc_mll_one_state(spk, r_avg_1)
            loglik_one_state.append((ll, idx))

        # Combine results from trials (need to check that we have all trial indices)
        loglik_one_state.sort(key=lambda x: x[1])
        loglik_two_state.sort(key=lambda x: x[1])
        trial_idx_1 = [x[1] for x in loglik_one_state]
        trial_idx_2 = [x[1] for x in loglik_two_state]
        if trial_idx_1 != trial_idx_2:
            raise ValueError('Trials missing!')
        trial_idx = trial_idx_1
        mll_one_state = [x[0] for x in loglik_one_state]
        mll_two_state = [x[0] for x in loglik_two_state]

        # If np.inf or np.nan is detected, raise warning and set to NaN
        mll_trials = []
        for idx, mll_1s, mll_2s in zip(trial_idx, mll_one_state, mll_two_state, strict=True):
            if np.isnan(mll_1s):
                print(f'Warning: NaN value found for one-state model at trial {idx}')
            if np.isnan(mll_2s):
                print(f'Warning: NaN value found for two-state model at trial {idx}')
            if np.isinf(mll_1s):
                print(f'Warning: np.inf value found for one-state model at trial {idx}')
                mll_1s = np.nan
            if np.isinf(mll_2s):
                print(f'Warning: np.inf value found for two-state model at trial {idx}')
                mll_2s = np.nan
            mll_trials.append(
                {'trial_index': idx, 'mll_one_state': mll_1s, 'mll_two_state': mll_2s}
            )

        # Add trial likelihoods and indices to dictionary
        loglik_dict[(r, c)] = mll_trials

    return loglik_dict


# %%
# Parse arguments

# Create parser
parser = argparse.ArgumentParser(description='Compute log-likelihood of state sequence')
parser.add_argument('--session', type=str, required=True)
parser.add_argument('--paradigm', type=str, required=True)
parser.add_argument('--probes', type=str, required=True)
parser.add_argument('-p', '--params', type=str, default='config/llr.yaml')

# Set args manually (notebook mode)
# args = parser.parse_args(['--session', 's168', '--paradigm', 'fsm', '--probes', 'p12'])

# Parse from command line (script mode)
args = parser.parse_args()

# %%
# Parameters

# Load parameters
with open(args.params, 'r') as f:
    params = yaml.safe_load(f)

# Directory paths
extract_data_dir = Path(params['paths']['extract_data_dir'])
marg_loglik_dir = Path(params['paths']['marg_loglik_dir'])

# Parameters for log-likelihood ratio model
r_start = params['model']['r_start']
r_stop = params['model']['r_stop']
r_floor = params['model']['r_floor']

# Parameters for control analysis
cval_seed = params['marg_loglik']['cval_seed']
shuffle_seed = params['marg_loglik']['shuffle_seed']
bin_size = params['marg_loglik']['bin_size']
win_start = params['marg_loglik']['win_start']
win_stop = params['marg_loglik']['win_stop']

# %%
# Load data

in_fpath = extract_data_dir / rec_fname(args.session, args.paradigm, args.probes, '.joblib')
in_data = joblib.load(in_fpath)
fs_data = in_data['fs_data']
units_orig = in_data['units']

# Select repeatedly presented stimuli in FSM paradigms
RSTIM_MAX = 60
if args.paradigm in ['fsm', 'fsmt']:
    print('Selecting repeat stimuli...')
    fs_data = {(r, c): d for (r, c), d in fs_data.items() if r < RSTIM_MAX and c < RSTIM_MAX}
    print('Done.')

# %%
# Calculate marginal log-likelihood of one- and two-state models on real data

# Average priming responses for all stimuli
r_prime = stim_priming_responses(fs_data, r_start, r_stop, r_floor)

# Marginal log-likelihoods of both models
with timex('Computing marginal log-likelihoods on real data...'):
    mll_real = mll_session(fs_data, r_prime, bin_size, win_start, win_stop, r_floor, cval_seed)

# %%
# Shuffle spikes and recompute marginal log-likelihoods

# Random number generator for shuffling
rng_shuffle = np.random.default_rng(shuffle_seed)

# Shuffle spikes in time independently for each unit within the analysis window
with timex('Shuffling spikes...'):
    fs_data_shuffle = shuffle_spikes(fs_data, win_start, win_stop, rng_shuffle)

# Marginal log-likelihoods of both models
with timex('Computing marginal log-likelihoods on shuffled data...'):
    mll_shuffle = mll_session(
        fs_data_shuffle, r_prime, bin_size, win_start, win_stop, r_floor, cval_seed
    )

# %%
# Compute average log-likelihood across trials

# Create DataFrame for trial information
rows_trial = []
for (r, c), trials in fs_data.items():
    for trial in trials:
        rows_trial.append(
            {
                'trial_index': trial['trial_index'],
                'stim_red': r,
                'stim_cyan': c,
                'trial_type': trial['trial_type'],
                'stim_dom': trial['stim_dom'],
            }
        )
df_trial = pd.DataFrame(rows_trial)

# DataFrame for marginal log-likelihood values computed on real data
rows_mll_real = []
for trials in mll_real.values():
    for x in trials:
        rows_mll_real.append(
            {
                'trial_index': x['trial_index'],
                'mll_1s': x['mll_one_state'],
                'mll_2s': x['mll_two_state'],
            }
        )
df_mll_real = pd.DataFrame(rows_mll_real)

# DataFrame for marginal log-likelihood values computed on shuffled data
rows_mll_shuffle = []
for trials in mll_shuffle.values():
    for x in trials:
        rows_mll_shuffle.append(
            {
                'trial_index': x['trial_index'],
                'mll_1s_shuffle': x['mll_one_state'],
                'mll_2s_shuffle': x['mll_two_state'],
            }
        )
df_mll_shuffle = pd.DataFrame(rows_mll_shuffle)

# Merge dataframes
df = df_trial.merge(df_mll_real, on='trial_index').merge(df_mll_shuffle, on='trial_index')

# Compute average marginal log-likelihood across trials on real and shuffled data
mll_1s = df['mll_1s'].mean()
mll_2s = df['mll_2s'].mean()
mll_1s_shuffle = df['mll_1s_shuffle'].mean()
mll_2s_shuffle = df['mll_2s_shuffle'].mean()

# %%
# Save data to JSON file

print('Saving results...')
out_fpath = marg_loglik_dir / rec_fname(args.session, args.paradigm, args.probes, '.json')
out_data = {
    'mll_1s': mll_1s,
    'mll_2s': mll_2s,
    'mll_1s_shuffle': mll_1s_shuffle,
    'mll_2s_shuffle': mll_2s_shuffle,
}
with open(out_fpath, 'w') as f:
    json.dump(out_data, f)
print('Done.')

# %%
