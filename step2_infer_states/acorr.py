# %%
# Compute autocorrelation of LLR

# %%
# Imports

import argparse
from pathlib import Path

import joblib
import numpy as np
import yaml

from percept_hmm.flash_suppression import iter_aligned
from percept_hmm.pipelines.dataio import rec_fname
from percept_hmm.stats import acorr_trials

# %%
# Helper methods


def get_llr_trials(
    fs_data: dict, llr_data: dict, trial_type: str, t_start: int, t_stop: int
) -> list[np.ndarray]:
    """Get list of LLR time series for all trials with given type"""

    llr_trials = []
    for r, c in fs_data:
        for trial, llr_trial in iter_aligned(fs_data[(r, c)], llr_data[(r, c)]):
            # Only include trials of given type
            if trial['trial_type'] == trial_type:
                # Log-likelihood ratio time series for trial
                llr = llr_trial['llr_red_cyan']

                # Extract window and add to list
                llr_win = llr[t_start:t_stop]
                llr_trials.append(llr_win)

    return llr_trials


# %%
# Parse arguments

# Create parser
parser = argparse.ArgumentParser(description='Autocorrelation of LLR signal')
parser.add_argument('--session', type=str, required=True)
parser.add_argument('--paradigm', type=str, required=True)
parser.add_argument('--probes', type=str, required=True)
parser.add_argument('-p', '--params', type=str, default='params.yaml')

# Set args manually (notebook mode)
# %cd 'data/llr_fs'
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
pred_all_units_dir = Path(params['paths']['pred_all_units_dir'])
pred_shuffle_dir = Path(params['paths']['pred_shuffle_dir'])
acorr_dir = Path(params['paths']['acorr_dir'])

# Analysis-specific parameters
max_lag = params['acorr']['max_lag']
t_start = params['acorr']['t_start']
t_stop = params['acorr']['t_stop']

# %%
# Load data from all stages

# Filename used for data in DVC pipeline
fname = rec_fname(args.session, args.paradigm, args.probes, '.joblib')

# Extracted data (need for trial type labels)
ext_fpath = extract_data_dir / fname
ext_data = joblib.load(ext_fpath)
fs_data = ext_data['fs_data']

# Data from LLR model
llr_fpath = pred_all_units_dir / fname
llr_data = joblib.load(llr_fpath)['pred_states']

# Data from LLR spike-shuffle control model
llr_shuffle_fpath = pred_shuffle_dir / fname
llr_shuffle_data = joblib.load(llr_shuffle_fpath)['pred_states']

# %%
# Compute autocorrelation of LLR for binocular trials

# Select LLR binocular trials (real and spike-shuffle control)
llr_trials_binoc = get_llr_trials(fs_data, llr_data, 'binocular', t_start, t_stop)
llr_shuffle_trials_binoc = get_llr_trials(fs_data, llr_shuffle_data, 'binocular', t_start, t_stop)

# If there are no binocular trials, set fields to None
if len(llr_trials_binoc) == 0:
    acorr_binoc = None
    acorr_binoc_shuffle = None
    acorr_binoc_norm = None
    acorr_binoc_shuffle_norm = None
    lags = None

# Otherwise, compute LLR
else:
    # Subtract mean LLR from each trial
    llr_trials_binoc_ctr = [x - np.mean(x) for x in llr_trials_binoc]
    llr_shuffle_trials_binoc_ctr = [x - np.mean(x) for x in llr_shuffle_trials_binoc]

    # Compute autocorrelation for real data
    acorr_binoc, lags_binoc = acorr_trials(llr_trials_binoc_ctr, max_lag)

    # Compute autocorrelation for spike-shuffle control
    acorr_binoc_shuffle, lags_binoc_shuffle = acorr_trials(llr_shuffle_trials_binoc_ctr, max_lag)

    # Check that all lags agree
    lags = lags_binoc
    lags_arr = [lags_binoc, lags_binoc_shuffle]
    if not all([np.array_equal(lags, x) for x in lags_arr]):
        raise ValueError('Some lag arrays are inconsistent')

    # Normalize autocorrelations
    acorr_binoc_norm = acorr_binoc / acorr_binoc[0]
    acorr_binoc_shuffle_norm = acorr_binoc_shuffle / acorr_binoc_shuffle[0]

# %%
# Plot autocorrelation (notebook mode)

# fig, ax = plt.subplots(layout='constrained')
# ax.plot(lags, acorr_binoc_norm, label='binocular')
# ax.plot(lags, acorr_binoc_shuffle_norm, label='binocular shuffle')
# ax.set_xlabel('Lag (ms)')
# ax.set_ylabel('Autocorrelation (normalized)')
# ax.set_title('Log-likelihood ratio autocorrelation')
# ax.legend()

# %%
# Example trial (notebook mode)

# TRIAL_PLT = 6
# llr = llr_trials_binoc[TRIAL_PLT]
# llr_shuffle = llr_shuffle_trials_binoc[TRIAL_PLT]

# # Mean-center
# llr = llr - np.mean(llr)
# llr_shuffle = llr_shuffle - np.mean(llr_shuffle)

# # Compute autocorrelation
# ac_trial, lags_trial = acorr_trials([llr], max_lag)
# ac_shuffle, lags_shuffle = acorr_trials([llr_shuffle], max_lag)

# # Normalize
# ac_norm = ac_trial / ac_trial[0]
# ac_shuffle_norm = ac_shuffle / ac_trial[0]

# fig, ax = plt.subplots(layout='constrained')
# ax.plot(lags_trial, ac_norm, label='acorr (single trial)')
# ax.plot(lags_shuffle, ac_shuffle_norm, label='acorr shuffle (single trial)')
# ax.set_xlabel('Lag (ms)')
# ax.set_ylabel('Autocorrelation (normalized)')
# ax.set_title('Log-likelihood ratio autocorrelation (example trial)')
# ax.legend()

# %%
# Save data to joblib file

print('Saving results...')
out_fpath = acorr_dir / rec_fname(args.session, args.paradigm, args.probes, '.joblib')
out_data = {
    'acorr_binoc': acorr_binoc,
    'acorr_binoc_shuffle': acorr_binoc_shuffle,
    'acorr_binoc_norm': acorr_binoc_norm,
    'acorr_binoc_shuffle_norm': acorr_binoc_shuffle_norm,
    'lags': lags,
}

joblib.dump(out_data, out_fpath, compress=True)
print('Done.')

# %%
