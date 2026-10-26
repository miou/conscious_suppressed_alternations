# %%
# Fit HMMs to disjoint subsets of units and compute fraction of state predictions that agree

# %%
# Imports

import argparse
import time
import yaml
import json
import joblib
from pathlib import Path
import numpy as np
import pandas as pd

from percept_hmm.flash_suppression import iter_aligned
from percept_hmm.pipelines.dataio import rec_fname
from percept_hmm.pipelines.fs_rivalry import (
    stim_priming_responses,
    frac_state_agreement,
)
from percept_hmm.pipelines.fixed_hmm import fit_hmms, predict_states


# %%
# Helper functions


def select_units_data(trials: list[dict], units_keep: np.ndarray) -> list[dict]:
    """Selects subset of units from spike data."""

    return [{**trial, 'spikes': trial['spikes'][:, units_keep].copy()} for trial in trials]


def get_unit_sample_states(units, fs_data, responses_prime, hmm_bin_size, hmm_rng_seed):
    """Fit HMM for particular subset of units and predict states."""

    # Select units from data and responses
    fs_data_subset = {k: select_units_data(v, units) for k, v in fs_data.items()}
    responses_subset = {k: v[units] for k, v in responses_prime.items()}

    # Fit fixed-rate HMMs to different trial types
    hmms = {}
    for trial_type in ['priming', 'binocular', 'transparent', 'unambiguous']:
        hmms[trial_type] = fit_hmms(
            fs_data_subset, responses_subset, trial_type, hmm_bin_size, hmm_rng_seed
        )

    # Predict states
    stim_state_dict = predict_states(fs_data_subset, hmms, hmm_bin_size)

    return stim_state_dict


# %%
# Parse arguments

# Create parser
parser = argparse.ArgumentParser(description='Fit HMMs on subsets of units and predict states')
parser.add_argument('--session', type=str, required=True)
parser.add_argument('--paradigm', type=str, required=True)
parser.add_argument('--probes', type=str, required=True)
parser.add_argument('-p', '--params', type=str, default='params.yaml')

# Set args manually (notebook mode)
# %cd 'data/fixed_hmm'
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
unit_subset_coherence_dir = Path(params['paths']['unit_subset_coherence_dir'])

# Parameters for fitting HMM
r_start = params['model']['r_start']
r_stop = params['model']['r_stop']
r_floor = params['model']['r_floor']
hmm_rng_seed = params['model']['rng_seed']
hmm_bin_size = params['model']['bin_size']

# Parameters for control analysis
units_rng_seed = params['unit_subset_coherence']['rng_seed']
frac_units_hmm = params['unit_subset_coherence']['frac_units_hmm']
n_samples = params['unit_subset_coherence']['n_samples']

# Check that parameters are valid
if frac_units_hmm > 0.5:
    raise ValueError('Parameter `frac_units_hmm` must be at most 0.5 for disjoint sampling.')

# %%
# Load data

in_fpath = extract_data_dir / rec_fname(args.session, args.paradigm, args.probes, '.joblib')
in_data = joblib.load(in_fpath)
fs_data = in_data['fs_data']
units_orig = in_data['units']

# %%
# Compute response vectors

print('Computing response vectors...')
tic = time.perf_counter()
responses_prime = stim_priming_responses(fs_data, r_start, r_stop, r_floor)
toc = time.perf_counter() - tic
print(f'Done. ({toc:.2f} s)')

# %%
# Sample units and compute state agreement for each trial

# Get number of HMM units to sample
n_units = units_orig.shape[0]
n_units_hmm = int(frac_units_hmm * n_units)

# Random number generator
rng = np.random.default_rng(units_rng_seed)

# List of dicts that we will convert into DataFrame
frac_agree_data = []

for smp in range(n_samples):
    # Sample units
    print('Sampling units...')
    units_all = np.arange(n_units)
    units_1 = np.sort(rng.choice(units_all, n_units_hmm, replace=False))
    units_rem = np.setdiff1d(units_all, units_1)
    units_2 = np.sort(rng.choice(units_rem, n_units_hmm, replace=False))
    print('Done.')

    # Get HMM states
    states_1 = get_unit_sample_states(units_1, fs_data, responses_prime, hmm_bin_size, hmm_rng_seed)
    states_2 = get_unit_sample_states(units_2, fs_data, responses_prime, hmm_bin_size, hmm_rng_seed)

    for r, c in fs_data.keys():
        # Iterate over trials for stimulus pair (checking that trial indices match)
        for trial, sd_1, sd_2 in iter_aligned(fs_data[(r, c)], states_1[(r, c)], states_2[(r, c)]):
            # Trial information
            t_type = trial['trial_type']
            t_index = trial['trial_index']
            t_stim = trial['stim_dom']

            # Estimated states from first and second group of units
            s_1 = sd_1['stim_states']
            s_2 = sd_2['stim_states']

            # Fraction of state agreement
            frac_agree = frac_state_agreement(s_1, s_2)

            frac_agree_data.append(
                {
                    'sample': smp,
                    'stim_red': r,
                    'stim_cyan': c,
                    'trial_index': t_index,
                    'trial_type': t_type,
                    'stim_dom': t_stim,
                    'frac_agree': frac_agree,
                }
            )

df = pd.DataFrame(frac_agree_data)

# %%
# Compute mean coherence values for all trial types

out_data = {}
trial_types = ['priming', 'binocular', 'transparent', 'unambiguous']
trial_abbrs = ['prime', 'binoc', 'trans', 'unamb']
for ttype, tabbr in zip(trial_types, trial_abbrs, strict=True):
    # Compute mean and set to None if trial type isn't present
    df_sel = df[df['trial_type'] == ttype]
    if len(df_sel) == 0:
        out_data[f'coh_mean_{tabbr}'] = None
    else:
        out_data[f'coh_mean_{tabbr}'] = float(df_sel['frac_agree'].mean())

# %%
# Save data to CSV file

print('Saving data CSV file...')
data_fpath = unit_subset_coherence_dir / f'data_{args.session}_{args.paradigm}_{args.probes}.csv'
df.to_csv(data_fpath)
print('Done.')

print('Saving results file...')
out_fpath = unit_subset_coherence_dir / rec_fname(
    args.session, args.paradigm, args.probes, '.json'
)
with open(out_fpath, 'w') as f:
    json.dump(out_data, f)
print('Done.')

# %%
