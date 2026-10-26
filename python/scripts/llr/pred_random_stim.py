# %%
# Compute log-likelihood ratio with random stimuli and predict states as control analysis

# %%
# Imports

import argparse
from pathlib import Path

import joblib
import numpy as np
import yaml

from percept_hmm.flash_suppression import TrialData, get_stim_list_from_pairs
from percept_hmm.pipelines.dataio import rec_fname
from percept_hmm.pipelines.fs_rivalry import stim_priming_responses
from percept_hmm.pipelines.llr import llr_win, rivalry_states_trial, stimulus_states_trial
from percept_hmm.utils import timex

# %%
# Helper methods


def get_llr_ctrl_stim(
    fs_data: dict[tuple[int, int], list[TrialData]],
    responses: dict[int, np.ndarray],
    win_size: int,
    stim_pair_to_ctrl: dict,
) -> dict[tuple[int, int], list[dict]]:
    """Compute log-likelihood ratio for all stimulus pairs in data dict with control stimuli."""

    # Compute log-likelihood for each stimulus pair, using control stimuli in place of the
    # stimuli actually shown to the animal
    llr_dict = {}
    for (r, c), trials in fs_data.items():
        # Get response vectors for control stimuli
        ctrl_red, ctrl_cyan = stim_pair_to_ctrl[(r, c)]
        r_ctrl_red = responses[ctrl_red]
        r_ctrl_cyan = responses[ctrl_cyan]

        # Compute LLR and states for all of this stimulus pair's trials
        recs = []
        for trial in trials:
            # Compute LLR for trial
            llr_red_cyan = llr_win(trial['spikes'], r_ctrl_red, r_ctrl_cyan, win_size)

            # Assign each time bin to a stimulus state (red or cyan) based on LLR
            stim_states = stimulus_states_trial(llr_red_cyan)

            # Assign each time bin to a rivalry state (conscious or suppressed)
            rivalry_states = rivalry_states_trial(stim_states, trial['stim_dom'])

            recs.append(
                {
                    'trial_index': trial['trial_index'],
                    'llr_red_cyan': llr_red_cyan,
                    'stim_states': stim_states,
                    'rivalry_states': rivalry_states,
                }
            )

        # Add trial records to dictionary
        llr_dict[(r, c)] = recs

    return llr_dict


def get_stim_and_ctrl_matrix(stim_to_ctrl: dict) -> np.ndarray:
    """Compile stimulus pairs and corresponding controls into single matrix."""

    stim_index_abcd_ls = list(stim_to_ctrl.items())
    n_stim_pairs = len(stim_index_abcd_ls)
    stim_index_abcd = np.zeros((n_stim_pairs, 4), dtype=np.int32)
    for i in range(n_stim_pairs):
        stim_a = stim_index_abcd_ls[i][0][0]
        stim_b = stim_index_abcd_ls[i][0][1]
        stim_c = stim_index_abcd_ls[i][1][0]
        stim_d = stim_index_abcd_ls[i][1][1]
        stim_index_abcd[i, :] = np.array([stim_a, stim_b, stim_c, stim_d])

    return stim_index_abcd


# %%
# Parse arguments

# Create parser
parser = argparse.ArgumentParser(description='Compute LLR with random stimuli (control)')
parser.add_argument('--session', type=str, required=True)
parser.add_argument('--paradigm', type=str, required=True)
parser.add_argument('--probes', type=str, required=True)
parser.add_argument('-p', '--params', type=str, default='config/llr.yaml')

# Set args manually (notebook mode)
# args = parser.parse_args(['--session', 's162', '--paradigm', 'fsm', '--probes', 'p12'])

# Parse from command line (script mode)
args = parser.parse_args()

# %%
# Parameters

# Load parameters
with open(args.params, 'r') as f:
    params = yaml.safe_load(f)

# Directory paths
extract_data_dir = Path(params['paths']['extract_data_dir'])
pred_random_stim_dir = Path(params['paths']['pred_random_stim_dir'])

# Parameters for computing log-likelihoods
r_start = params['model']['r_start']
r_stop = params['model']['r_stop']
r_floor = params['model']['r_floor']
win_size = params['model']['win_size']

# Parameters for control analysis
stim_rng_seed = params['pred_random_stim']['rng_seed']

# %%
# Load data

in_fpath = extract_data_dir / rec_fname(args.session, args.paradigm, args.probes, '.joblib')
in_data = joblib.load(in_fpath)
fs_data = in_data['fs_data']

# %%
# Sample control stimuli

# All stimulus pairs
stim_pairs = list(fs_data.keys())

# All unique stimuli
stim_all = get_stim_list_from_pairs(stim_pairs)

# Sample controls
rng_stim = np.random.default_rng(stim_rng_seed)
stim_pairs_control = []
for i in range(len(stim_pairs)):
    # Red and cyan stimuli actually shown to animal
    stim_red, stim_cyan = stim_pairs[i]

    # List of all stimuli not shown to animal
    ctrl_stimuli = np.array(stim_all)
    ctrl_stimuli = ctrl_stimuli[(ctrl_stimuli != stim_red) & (ctrl_stimuli != stim_cyan)]

    # Select control stimuli that are not shown to animal
    ctrl_smp_arr = rng_stim.choice(ctrl_stimuli, 2, replace=False)
    ctrl_red = ctrl_smp_arr[0].item()
    ctrl_cyan = ctrl_smp_arr[1].item()

    # Add control stimulus pair to list
    stim_pairs_control.append((ctrl_red, ctrl_cyan))

# Dict mapping stimulus pair to corresponding control pair
stim_to_ctrl = {s: c for s, c in zip(stim_pairs, stim_pairs_control, strict=True)}

# %%
# Compute log-likelihood ratio and derived states

# Average responses to priming trials
with timex('Computing response vectors...'):
    responses_prime = stim_priming_responses(fs_data, r_start, r_stop, r_floor)

# LLR and states using control stimuli
with timex('Computing log-likelihood ratio and states...'):
    llr_states = get_llr_ctrl_stim(fs_data, responses_prime, win_size, stim_to_ctrl)

# %%
# Save data to joblib file

# Matrix of stimulus pairs and controls (stim red, stim cyan, ctrl red, ctrl cyan)
stim_index_abcd = get_stim_and_ctrl_matrix(stim_to_ctrl)

with timex('Saving results...'):
    out_fname = rec_fname(args.session, args.paradigm, args.probes, '.joblib')
    out_fpath = pred_random_stim_dir / out_fname
    out_data = {
        'pred_states': llr_states,
        'stim_index_abcd': stim_index_abcd,
    }
    joblib.dump(out_data, out_fpath, compress=True)

# %%
