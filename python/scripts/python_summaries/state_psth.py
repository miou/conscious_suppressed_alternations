# %%
# Create PSTH plot of fraction of time bins in state 1 for each session

# %%
# Imports

import argparse
from pathlib import Path

import joblib
import matplotlib.pyplot as plt
import numpy as np
import yaml
from percept_hmm.flash_suppression import iter_aligned
from percept_hmm.pipelines.dataio import rec_fname
from scipy.io import savemat

# %%
# Helper methods

def get_state_trials(
    fs_data: dict, state_data: dict, trial_type: str, t_flash_max: int
) -> list[np.ndarray]:
    """Get list of states for all trials with given type"""

    state_trials = []
    for r, c in fs_data:

        # Iterate over trials for stimulus pair (checking that trial indices match)
        for trial, state_trial in iter_aligned(fs_data[(r, c)], state_data[(r, c)]):
            
            # Only include trials of given type 
            if trial['trial_type'] == trial_type:

                # State time series for trial
                states = state_trial['rivalry_states']

                # For priming trials, remove beginning of trial `t_flash` time steps before flash 
                if trial_type == 'priming':
                    states_win = states[-t_flash_max:]
                # For other trials, remove end of trial `t_flash` time steps after flash
                else:
                    states_win = states[:t_flash_max]

                # Add window to list
                state_trials.append(states_win)

    return state_trials


def compute_frac_state(fs_data, state_data, state, trial_type, t_flash_max):

    # Get cropped state sequences for trial type and stack into (trials * time points) array
    state_trials_ls = get_state_trials(fs_data, state_data, trial_type, t_flash_max)
    state_trials = np.stack(state_trials_ls, axis=0)

    # Check that states are binary
    assert np.array_equal(np.unique(state_trials), np.array([0, 1]))

    # Average across time points to get fraction in state 1
    frac_1 = np.mean(state_trials, axis=0)

    # Return fraction of time points in state
    if state == 0:
        return 1 - frac_1
    elif state == 1:
        return frac_1
    else:
        raise ValueError('State must be either 0 or 1')


# %%
# Parse arguments

# Create parser
parser = argparse.ArgumentParser(description='Compile PSTH of fraction of time bins in each state')
parser.add_argument('-p', '--params', type=str, default='config/python_summaries.yaml')

# Set args manually (notebook mode)
# args = parser.parse_args([])

# Parse from command line (script mode)
args = parser.parse_args()

# %%
# Parameters

# Load parameters
with open(args.params, 'r') as f:
    params = yaml.safe_load(f)

# Path to YAML file with lists of recordings in different categories
rec_list_fpath = params['paths']['rec_list_fpath']

# Directories with extracted trial data and predicted states from `llr` pipeline
fs_data_dir = Path(params['paths']['extract_data_dir'])
state_data_dir = Path(params['paths']['pred_all_units_dir'])

# Output directory
out_dir = Path(params['paths']['python_summaries_dir'])

# Number of time points before and after flash, and whether to only use repeated stimuli
t_flash_max = params['state_psth']['t_flash_max']
select_repeat_stimuli = params['state_psth']['select_repeat_stimuli']

# %%
# Load data

# Load recordings from list
with open(rec_list_fpath) as f:
    rec_list = yaml.safe_load(f)['rec_it']

# %%
# Compile PSTHs for both priming and binocular trials

frac_dom = []
for rec in rec_list:

    # Load session data and predicted states
    fname = rec_fname(rec['session'], rec['paradigm'], rec['probes'], '.joblib')
    fs_data = joblib.load(fs_data_dir / fname)['fs_data']
    state_data = joblib.load(state_data_dir / fname)['pred_states']

    # Select repeatedly presented stimuli
    RSTIM_MAX = 60
    if select_repeat_stimuli:
        fs_data = {(r, c): d for (r, c), d in fs_data.items() if r < RSTIM_MAX and c < RSTIM_MAX}

    # Fraction of time points in state 1 for priming trials
    f_prime = compute_frac_state(fs_data, state_data, 1, 'priming', t_flash_max)

    # Fraction of time points in state 0 for binocular trials
    f_binoc = compute_frac_state(fs_data, state_data, 0, 'binocular', t_flash_max)

    # Concatenate to get fraction of time points in binocular dominant stimulus state for full trial
    f_full = np.concatenate([f_prime, f_binoc])
    frac_dom.append(f_full)

# Compile into NumPy array
frac_dom = np.stack(frac_dom, axis=0)

# Time relative to flash corresponding to rows of `frac_dom`
t_flash = np.arange(-t_flash_max, t_flash_max)

# %%
# Plot PSTH for priming trials

frac_dom_mean = np.mean(frac_dom, axis=0)
frac_dom_std = np.std(frac_dom, axis=0)

fig, ax = plt.subplots(layout='constrained')
ax.plot(t_flash, frac_dom_mean)
ax.fill_between(
    t_flash,
    frac_dom_mean - frac_dom_std,
    frac_dom_mean + frac_dom_std,
    alpha=0.3,
)
ax.set_ylim(bottom=0.0, top=1.0)
ax.set_title('Fraction of points in state 1')
ax.axvline(x=0, color='black', label='flash')
ax.axhline(y=0.5, linestyle='--', color='black')

# %%
# Save to output file

out_fpath = out_dir / 'state_psth_all.mat'

# Package fields into dict and save to MAT file
out_data = {
    't_flash': t_flash,
    'frac_dom': frac_dom,
    'frac_dom_mean': frac_dom_mean,
    'frac_dom_std': frac_dom_std,
}
savemat(out_fpath, out_data, do_compression=True)

# %%
