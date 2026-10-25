# %%
# Compute summary statistics for each session

# %%
# Imports

import argparse
import json
from pathlib import Path

import joblib
import numpy as np
import pandas as pd
import yaml

from percept_hmm.flash_suppression import iter_aligned
from percept_hmm.pipelines.dataio import rec_fname
from percept_hmm.stats import get_run_lengths

# %%
# Helper methods

# %%
# Parse arguments

# Create parser
parser = argparse.ArgumentParser(description='Compute recording-specific statistics')
parser.add_argument('--session', type=str, required=True)
parser.add_argument('--paradigm', type=str, required=True)
parser.add_argument('--probes', type=str, required=True)
parser.add_argument('-p', '--params', type=str, default='params.yaml')

# Set args manually (notebook mode)
# %cd 'data/llr_gain_fs'
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
stats_dir = Path(params['paths']['stats_dir'])

# Parameters for computing stats
priming_acc_t_start = params['stats']['priming_acc_t_start']

# %%
# Load data

# Filename used for data in DVC pipeline
fname = rec_fname(args.session, args.paradigm, args.probes, '.joblib')

# Extracted data
ext_fpath = extract_data_dir / fname
ext_data = joblib.load(ext_fpath)
fs_data = ext_data['fs_data']

# Estimated states
pred_all_units_fpath = pred_all_units_dir / fname
pred_all_units_data = joblib.load(pred_all_units_fpath)
llr_states = pred_all_units_data['pred_states']

# %%
# Compute priming accuracy

acc_data = []
for r, c in fs_data:
    for trial, llr in iter_aligned(fs_data[(r, c)], llr_states[(r, c)]):
        # Only compute accuracy for priming trials
        if trial['trial_type'] == 'priming':
            # Compute mean accuracy
            is_correct = llr['stim_states'] == trial['stim_dom']
            is_correct_crop = is_correct[priming_acc_t_start:]
            acc = np.count_nonzero(is_correct_crop) / is_correct_crop.shape[0]

            # Add entry for trial
            acc_data.append(
                {
                    'trial_index': trial['trial_index'],
                    'stim_dom': trial['stim_dom'],
                    'stim_red': r,
                    'stim_cyan': c,
                    'acc': acc,
                }
            )
df = pd.DataFrame(acc_data)

# Mean priming accuracies
acc_mean_all = df['acc'].mean()
acc_mean_red = df[df['stim_dom'] == 0]['acc'].mean()
acc_mean_cyan = df[df['stim_dom'] == 1]['acc'].mean()

# %%
# Compute dwell statistics


# Get stimulus and rivalry states for binocular trials
stim_state_binoc = []
rivalry_state_binoc = []
for r, c in fs_data:
    for trial, llr in iter_aligned(fs_data[(r, c)], llr_states[(r, c)]):
        if trial['trial_type'] == 'binocular':
            stim_state_binoc.append(llr['stim_states'])
            rivalry_state_binoc.append(llr['rivalry_states'])

# TODO: Add window to restrict calculations to (i.e. only binocular trials 300-1000 ms)

if len(stim_state_binoc) > 0:
    # Occupancy proportions for red and cyan states
    stim_state_all = np.concatenate(stim_state_binoc, axis=0)
    frac_red = np.count_nonzero(stim_state_all == 0) / stim_state_all.shape[0]
    frac_cyan = np.count_nonzero(stim_state_all == 1) / stim_state_all.shape[0]

    # Occupancy proportions for rivalry states
    rivalry_state_all = np.concatenate(rivalry_state_binoc, axis=0)
    frac_dom = np.count_nonzero(rivalry_state_all == 0) / rivalry_state_all.shape[0]
    frac_sup = np.count_nonzero(rivalry_state_all == 1) / rivalry_state_all.shape[0]

    # Mean and median dwell times for stimulus states
    stim_run_len = get_run_lengths(stim_state_binoc, 2)
    run_lengths_red = stim_run_len[0]
    run_lengths_cyan = stim_run_len[1]
    dwell_time_red_mean = np.mean(run_lengths_red)
    dwell_time_red_median = np.median(run_lengths_red)
    dwell_time_cyan_mean = np.mean(run_lengths_cyan)
    dwell_time_cyan_median = np.median(run_lengths_cyan)

    # Mean and median dwell times for rivalry states
    rivalry_run_len = get_run_lengths(rivalry_state_binoc, 2)
    run_lengths_dom = rivalry_run_len[0]
    run_lengths_sup = rivalry_run_len[1]
    dwell_time_dom_mean = np.mean(run_lengths_dom)
    dwell_time_dom_median = np.median(run_lengths_dom)
    dwell_time_sup_mean = np.mean(run_lengths_sup)
    dwell_time_sup_median = np.median(run_lengths_sup)

# If there aren't any binocular trials in this recording, set all stats to None
else:
    frac_red = None
    frac_cyan = None
    frac_sup = None
    frac_dom = None
    dwell_time_red_mean = None
    dwell_time_red_median = None
    dwell_time_cyan_mean = None
    dwell_time_cyan_median = None
    dwell_time_dom_mean = None
    dwell_time_dom_median = None
    dwell_time_sup_mean = None
    dwell_time_sup_median = None


# %%
# Save data to JSON file

print('Saving results...')
out_fpath = stats_dir / rec_fname(args.session, args.paradigm, args.probes, '.json')
out_data = {
    'priming_acc_mean': acc_mean_all,
    'priming_acc_red_mean': acc_mean_red,
    'priming_acc_cyan_mean': acc_mean_cyan,
    'frac_red': frac_red,
    'frac_cyan': frac_cyan,
    'frac_sup': frac_sup,
    'frac_dom': frac_dom,
    'dwell_time_red_mean': dwell_time_red_mean,
    'dwell_time_red_median': dwell_time_red_median,
    'dwell_time_cyan_mean': dwell_time_cyan_mean,
    'dwell_time_cyan_median': dwell_time_cyan_median,
    'dwell_time_dom_mean': dwell_time_dom_mean,
    'dwell_time_dom_median': dwell_time_dom_median,
    'dwell_time_sup_mean': dwell_time_sup_mean,
    'dwell_time_sup_median': dwell_time_sup_median,
}
with open(out_fpath, 'w') as f:
    json.dump(out_data, f)
print('Done.')

# %%
