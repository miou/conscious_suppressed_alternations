# %%
# Fit fixed-rate HMM to subset of units and predict states

# %%
# Imports

import argparse
import time
import yaml
import joblib
from pathlib import Path
import numpy as np

from percept_hmm.pipelines.dataio import rec_fname
from percept_hmm.pipelines.fs_rivalry import stim_priming_responses
from percept_hmm.pipelines.fixed_hmm import (
    fit_hmms,
    predict_states,
)

# %%
# Helper functions

def select_units_data(trials: list[dict], units_keep: np.ndarray) -> list[dict]:
    return [{**trial, 'spikes': trial['spikes'][:, units_keep].copy()} for trial in trials]

# %%
# Parse arguments

# Create parser
parser = argparse.ArgumentParser(description='Fit fixed-rate HMM on subset of units')
parser.add_argument('--session', type=str, required=True)
parser.add_argument('--paradigm', type=str, required=True)
parser.add_argument('--probes', type=str, required=True)
parser.add_argument('-p', '--params', type=str, default='config/fixed_hmm.yaml')

# Set args manually (notebook mode)
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
pred_unit_subset_dir = Path(params['paths']['pred_unit_subset_dir'])

# Parameters for fitting HMM
r_start = params['model']['r_start']
r_stop = params['model']['r_stop']
r_floor = params['model']['r_floor']
hmm_bin_size = params['model']['bin_size']
hmm_rng_seed = params['model']['rng_seed']

# Parameters for unit subset analysis
units_rng_seed = params['pred_unit_subset']['rng_seed']
frac_units_hmm = params['pred_unit_subset']['frac_units_hmm']

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
print(f'Sampling {n_units_hmm}/{n_units} units...')
rng = np.random.default_rng(units_rng_seed)
units_all_idx = np.arange(n_units)
units_hmm_idx = np.sort(rng.choice(units_all_idx, n_units_hmm, replace=False))
print('Done.')

# Decoding units are all units besides HMM units
units_decode_idx = np.setdiff1d(units_all_idx, units_hmm_idx)

# %%
# Select HMM units in session

print('Selecting units from session...')
tic = time.perf_counter()
fs_data = {k: select_units_data(v, units_hmm_idx) for k, v in fs_data.items()}
toc = time.perf_counter() - tic
print(f'Done. ({toc:.2f} s)')

# %%
# Compute response vectors

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
    hmms[trial_type] = fit_hmms(fs_data, responses_prime, trial_type, hmm_bin_size, hmm_rng_seed)
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

# Units (in original indexing scheme) for HMM and decoding
units_hmm = units_orig[units_hmm_idx]
units_decode = units_orig[units_decode_idx]

print('Saving results...')
tic = time.perf_counter()
out_fpath = pred_unit_subset_dir / rec_fname(args.session, args.paradigm, args.probes, '.joblib')
out_data = {
    'pred_states': pred_states,
    'units_hmm': units_hmm,
    'units_decode': units_decode,
}
joblib.dump(out_data, out_fpath, compress=True)
toc = time.perf_counter() - tic
print(f'Done. ({toc:.2f} s)')

# %%
