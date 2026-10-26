# %%
# Compute log-likelihood on state sequence predicted from subsample of units

# %%
# Imports

import argparse
import json
from pathlib import Path

import joblib
import numpy as np
import pandas as pd
import yaml
from scipy.special import gammaln, xlogy

from percept_hmm.fixed_hmm import bin_trial
from percept_hmm.flash_suppression import TrialData, iter_aligned
from percept_hmm.pipelines.dataio import rec_fname
from percept_hmm.pipelines.fixed_hmm import fit_hmms, predict_states
from percept_hmm.pipelines.fs_rivalry import stim_priming_responses
from percept_hmm.utils import timex

# %%
# Helper functions


def select_units_data(trials: list[TrialData], units_keep: np.ndarray) -> list[TrialData]:
    return [{**trial, 'spikes': trial['spikes'][:, units_keep].copy()} for trial in trials]


def row_modes(a: np.ndarray) -> np.ndarray:
    """Get most common value in each row of matrix a."""

    # a: (R, C) array of natural numbers (non-negative ints)
    R, C = a.shape
    n_bins = int(a.max()) + 1

    # offset row i by i * n_bins so each row occupies its own bin range
    offset = a + (np.arange(R) * n_bins)[:, None]
    counts = np.bincount(offset.ravel(), minlength=R * n_bins).reshape(R, n_bins)

    return counts.argmax(axis=1)


def bin_states(states: np.ndarray, bin_size: int) -> np.ndarray:
    """Bin state sequence."""

    # Determine number of bins
    n_bins = len(states) // bin_size

    # Trim time points off end of trial to make trial length divisible by bin size
    n_pts_trim = n_bins * bin_size
    states_trim = states[0:n_pts_trim]

    # Get state labels for each bin using majority vote
    states_rs = states_trim.reshape(n_bins, bin_size)
    states_bin = row_modes(states_rs)

    return states_bin


def poisson_loglik(spikes: np.ndarray, rates: np.ndarray) -> np.ndarray:
    """Compute log-likelihood for each spike count in matrix given each rate."""

    return xlogy(spikes, rates) - rates - gammaln(spikes + 1)


def loglik_trial(
    spikes: np.ndarray,
    states: np.ndarray,
    r_prime: np.ndarray,
    bin_size: int,
    win_start: int,
    win_stop: int,
) -> float:
    """Compute log-likelihood of spike counts given estimated state sequence."""

    # Restrict spikes and states to window
    spikes_win = spikes[win_start:win_stop, :]
    states_win = states[win_start:win_stop]

    # Bin spikes and states
    spikes_bin = bin_trial(spikes_win, bin_size)
    states_bin = bin_states(states_win, bin_size)

    # Create rate matrix for trial using state sequence
    r_bin = r_prime * bin_size
    rates_bin = np.stack([r_bin[i] for i in states_bin], axis=0)

    # Log-likelihood for each spike count
    loglik_spikes = poisson_loglik(spikes_bin, rates_bin)

    # Normalize by number of units in trial
    n_units = spikes.shape[1]
    loglik_norm = np.sum(loglik_spikes) / n_units

    return loglik_norm


def loglik_session(
    fs_data: dict[tuple[int, int], list[TrialData]],
    state_data: dict[tuple[int, int], list[dict]],
    resp_prime: dict[int, np.ndarray],
    bin_size: int,
    win_start: int,
    win_stop: int,
) -> dict[tuple[int, int], list[dict]]:

    loglik_dict = {}

    for r, c in fs_data:
        # Get response vectors and combine into single array
        r_red = resp_prime[r]
        r_cyan = resp_prime[c]
        r_prime = np.stack((r_red, r_cyan), axis=0)

        # Calculate log-likelihood of spikes given predicted state sequence for all trials (checking
        # that trial indices are the same between extracted data and state sequence)
        loglik_dict[(r, c)] = [
            {
                'trial_index': trial['trial_index'],
                'trial_vals': loglik_trial(
                    trial['spikes'], ss['stim_states'], r_prime, bin_size, win_start, win_stop
                ),
            }
            for trial, ss in iter_aligned(fs_data[(r, c)], state_data[(r, c)])
        ]

    return loglik_dict


def loglik_static_trial(
    spikes: np.ndarray, r_prime: np.ndarray, bin_size: int, win_start: int, win_stop: int
) -> float:
    """Compute log-likelihood of spike counts given static response vector."""

    # Restrict spikes to window
    spikes_win = spikes[win_start:win_stop, :]

    # Bin spikes
    spikes_bin = bin_trial(spikes_win, bin_size)

    # Create rate matrix for trial
    n_bins = spikes_bin.shape[0]
    r_bin = r_prime * bin_size
    rates_bin = np.stack([r_bin] * n_bins, axis=0)

    # Log-likelihood for each spike count
    loglik_spikes = poisson_loglik(spikes_bin, rates_bin)

    # Normalize by number of units in trial
    n_units = spikes.shape[1]
    loglik_norm = np.sum(loglik_spikes) / n_units

    return loglik_norm


def loglik_mix_session(
    fs_data: dict[tuple[int, int], list[TrialData]],
    resp_prime: dict[int, np.ndarray],
    bin_size: int,
    win_start: int,
    win_stop: int,
    alpha_red: float,
) -> dict[tuple[int, int], list[dict]]:

    loglik_dict = {}

    for (r, c), trials in fs_data.items():
        # Mixed response is linear combination of red and cyan response vectors
        r_red = resp_prime[r]
        r_cyan = resp_prime[c]
        r_prime = alpha_red * r_red + (1 - alpha_red) * r_cyan

        # Calculate log-likelihood of spikes given static mixed response for all trials
        loglik_dict[(r, c)] = [
            {
                'trial_index': trial['trial_index'],
                'trial_vals': loglik_static_trial(
                    trial['spikes'], r_prime, bin_size, win_start, win_stop
                ),
            }
            for trial in trials
        ]

    return loglik_dict


def loglik_df(loglik_dict: dict[tuple[int, int], list[dict]], col_name: str) -> pd.DataFrame:
    """Create DataFrame of log-likelihood values indexed by trial."""

    rows = [
        {'trial_index': x['trial_index'], col_name: x['trial_vals']}
        for trials in loglik_dict.values()
        for x in trials
    ]

    return pd.DataFrame(rows)


# %%
# Parse arguments

# Create parser
parser = argparse.ArgumentParser(description='Fit fixed-rate HMM on subset of units for control')
parser.add_argument('--session', type=str, required=True)
parser.add_argument('--paradigm', type=str, required=True)
parser.add_argument('--probes', type=str, required=True)
parser.add_argument('-p', '--params', type=str, default='config/fixed_hmm.yaml')

# Set args manually (notebook mode)
# args = parser.parse_args(['--session', 's166', '--paradigm', 'fsm', '--probes', 'p12'])

# Parse from command line (script mode)
args = parser.parse_args()

# %%
# Parameters

# Load parameters
with open(args.params, 'r') as f:
    params = yaml.safe_load(f)

# Directory paths
extract_data_dir = Path(params['paths']['extract_data_dir'])
states_loglik_dir = Path(params['paths']['states_loglik_dir'])

# Parameters for fitting HMM
r_start = params['model']['r_start']
r_stop = params['model']['r_stop']
r_floor = params['model']['r_floor']
hmm_bin_size = params['model']['bin_size']
hmm_rng_seed = params['model']['rng_seed']

# Parameters for control analysis
units_rng_seed = params['states_loglik']['rng_seed']
frac_units_hmm = params['states_loglik']['frac_units_hmm']
ll_bin_size = params['states_loglik']['bin_size']
ll_win_start = params['states_loglik']['win_start']
ll_win_stop = params['states_loglik']['win_stop']
mix_alpha_red = params['states_loglik']['mix_alpha_red']

# %%
# Load data

in_fpath = extract_data_dir / rec_fname(args.session, args.paradigm, args.probes, '.joblib')
in_data = joblib.load(in_fpath)
fs_data = in_data['fs_data']
units_orig = in_data['units']

# %%
# Sample HMM units

# Get number of HMM units to sample
n_units = units_orig.shape[0]
n_units_hmm = int(frac_units_hmm * n_units)

# Sample HMM units
print('Sampling units...')
rng = np.random.default_rng(units_rng_seed)
units_all_idx = np.arange(n_units)
units_hmm_idx = np.sort(rng.choice(units_all_idx, n_units_hmm, replace=False))
units_loglik_idx = np.setdiff1d(units_all_idx, units_hmm_idx)
print('Done.')
print(f'HMM: {len(units_hmm_idx)}/{n_units} units')
print(f'Loglik: {len(units_loglik_idx)}/{n_units} units')

# %%
# Split data by units

print('Selecting units from session...')
fs_data_hmm = {k: select_units_data(v, units_hmm_idx) for k, v in fs_data.items()}
fs_data_loglik = {k: select_units_data(v, units_loglik_idx) for k, v in fs_data.items()}
print('Done')

# %%
# Compute response vectors for both sets of units

print('Computing response vectors...')
resp_hmm = stim_priming_responses(fs_data_hmm, r_start, r_stop, r_floor)
resp_loglik = stim_priming_responses(fs_data_loglik, r_start, r_stop, r_floor)
print('Done.')

# %%
# Fit HMMs and predict states on HMM units

# Fit fixed-rate HMMs to different trial types
hmms = {}
for trial_type in ['priming', 'binocular', 'transparent', 'unambiguous']:
    with timex(f'Fitting HMMs to {trial_type} trials...'):
        hmms[trial_type] = fit_hmms(fs_data_hmm, resp_hmm, trial_type, hmm_bin_size, hmm_rng_seed)

# Predict state sequences for each trial
with timex('Predicting stimulus states...'):
    state_data = predict_states(fs_data_hmm, hmms, hmm_bin_size)

# %%
# Calculate log-likelihood on held-out unit data using predicted states

# Log-likelihood given state sequence
loglik_states = loglik_session(
    fs_data_loglik, state_data, resp_loglik, ll_bin_size, ll_win_start, ll_win_stop
)

# Log-likelihood for mixed static representation
loglik_mix = loglik_mix_session(
    fs_data_loglik, resp_loglik, ll_bin_size, ll_win_start, ll_win_stop, mix_alpha_red
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

# Create DataFrames for state and mix log-likelihood values
df_loglik_states = loglik_df(loglik_states, 'loglik')
df_loglik_mix = loglik_df(loglik_mix, 'loglik_mix')

# Merge dataframes
df = df_trial.merge(df_loglik_states, on='trial_index').merge(df_loglik_mix, on='trial_index')

# Average state log-likelihood across all trials, priming trials, and binocular trials
loglik_all = df['loglik'].mean()
loglik_prime = df[df['trial_type'] == 'priming']['loglik'].mean()
loglik_binoc = df[df['trial_type'] == 'binocular']['loglik'].mean()

# Average mix log-likelihood across all trials, priming trials, and binocular trials
loglik_mix_all = df['loglik_mix'].mean()
loglik_mix_prime = df[df['trial_type'] == 'priming']['loglik_mix'].mean()
loglik_mix_binoc = df[df['trial_type'] == 'binocular']['loglik_mix'].mean()

# %%
# Save data to JSON file

# Units (in original indexing scheme) for HMM and log-likelihood calculations
units_hmm = units_orig[units_hmm_idx].tolist()
units_loglik = units_orig[units_loglik_idx].tolist()

print('Saving results...')
out_fpath = states_loglik_dir / rec_fname(args.session, args.paradigm, args.probes, '.json')
out_data = {
    'loglik_all': loglik_all,
    'loglik_prime': loglik_prime,
    'loglik_binoc': loglik_binoc,
    'loglik_mix_all': loglik_mix_all,
    'loglik_mix_prime': loglik_mix_prime,
    'loglik_mix_binoc': loglik_mix_binoc,
    'units_hmm': units_hmm,
    'units_loglik': units_loglik,
}
with open(out_fpath, 'w') as f:
    json.dump(out_data, f)
print('Done.')

# %%
