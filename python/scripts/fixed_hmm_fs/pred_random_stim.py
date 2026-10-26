# %%
# Fit fixed-rate HMM to random stimuli and predict states as control analysis

# %%
# Imports

import argparse
import time
import yaml
import joblib 
from pathlib import Path
import numpy as np
from hmmlearn.hmm import PoissonHMM

from percept_hmm.flash_suppression import TrialData, get_stim_list_from_pairs
from percept_hmm.pipelines.dataio import rec_fname
from percept_hmm.pipelines.fs_rivalry import stim_priming_responses
from percept_hmm.pipelines.fixed_hmm_fs import (
    fit_hmm_stim_pair,
    predict_states,
)

# %%
# Helper functions

def fit_hmms_ctrl_stim(
    fs_data: dict[tuple[int, int], list[TrialData]],
    responses: dict[int, np.ndarray],
    trial_type: str,
    bin_size: int,
    rng_seed: int,
    stim_pair_to_ctrl: dict
) -> dict[tuple[int, int], PoissonHMM]:
    """Fit fixed-rate HMMs to trials for all stimulus pairs in data dict with control stimuli."""

    # List of all stimulus pairs we have data for
    stim_pairs = list(fs_data.keys())

    # Fit HMM for each stimulus pair
    hmm_dict = {}
    for r, c in stim_pairs:

        # Get response vectors for control stimuli
        ctrl_red, ctrl_cyan = stim_pair_to_ctrl[(r, c)]
        r_ctrl_red = responses[ctrl_red]
        r_ctrl_cyan = responses[ctrl_cyan]

        # Get trial data for stimulus pair
        trials = fs_data[(r, c)]

        # Fit HMM
        hmm_dict[(r, c)] = fit_hmm_stim_pair(trials, r_ctrl_red, r_ctrl_cyan, trial_type, bin_size, rng_seed)

    return hmm_dict

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
parser = argparse.ArgumentParser(description='Fit fixed-rate HMM with random stimuli (control)')
parser.add_argument('--session', type=str, required=True)
parser.add_argument('--paradigm', type=str, required=True)
parser.add_argument('--probes', type=str, required=True)
parser.add_argument('-p', '--params', type=str, default='params.yaml')

# Set args manually (notebook mode)
#%cd 'data/fixed_hmm_fs'
#args = parser.parse_args(['--session', 's166', '--paradigm', 'fsm', '--probes', 'p12'])

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

# Parameters for fitting HMM
r_start = params['model']['r_start']
r_stop = params['model']['r_stop']
r_floor = params['model']['r_floor']
hmm_bin_size = params['model']['bin_size']
hmm_rng_seed = params['model']['rng_seed']

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
# Compute response vectors

# Compute response vectors from priming trials
print('Computing response vectors...')
tic = time.perf_counter()
responses_prime = stim_priming_responses(fs_data, r_start, r_stop, r_floor)
toc = time.perf_counter() - tic
print(f'Done. ({toc:.2f} s)')

# %%
# Fit models

# Fit fixed-rate HMMs to different trial types
hmms = {}
for trial_type in ['priming', 'binocular', 'transparent', 'unambiguous']:
    print(f'Fitting HMMs to {trial_type} trials...')
    tic = time.perf_counter()
    hmms[trial_type] = fit_hmms_ctrl_stim(fs_data, responses_prime, trial_type, hmm_bin_size, hmm_rng_seed, stim_to_ctrl)
    toc = time.perf_counter() - tic
    print(f'Done. ({toc:.2f} s)')

# %%
# Get states, posterior, and partition for all trials

print('Predicting states and posteriors...')
tic = time.perf_counter()
pred_states = predict_states(fs_data, hmms, hmm_bin_size)
toc = time.perf_counter() - tic
print(f'Done. ({toc:.2f} s)')

# %%
# Save data to joblib file

# Matrix of stimulus pairs and controls (stim red, stim cyan, ctrl red, ctrl cyan)
stim_index_abcd = get_stim_and_ctrl_matrix(stim_to_ctrl)

print('Saving results...')
tic = time.perf_counter()
out_fpath = pred_random_stim_dir / rec_fname(args.session, args.paradigm, args.probes, '.joblib')
out_data = {
    'pred_states': pred_states,
    'stim_index_abcd': stim_index_abcd,
}
joblib.dump(out_data, out_fpath, compress=True)
toc = time.perf_counter() - tic
print(f'Done. ({toc:.2f} s)')

# %%