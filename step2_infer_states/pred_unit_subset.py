# %%
# Compute log-likelihood ratio on subset of units and predict states

# %%
# Imports

import argparse
from pathlib import Path

import joblib
import numpy as np
import yaml

from percept_hmm.pipelines.dataio import rec_fname
from percept_hmm.pipelines.fs_rivalry import stim_priming_responses
from percept_hmm.pipelines.llr_fs import get_llr_win, select_units_data
from percept_hmm.utils import timex

# %%
# Parse arguments

# Create parser
parser = argparse.ArgumentParser(description='Compute LLR on subset of units')
parser.add_argument('--session', type=str, required=True)
parser.add_argument('--paradigm', type=str, required=True)
parser.add_argument('--probes', type=str, required=True)
parser.add_argument('-p', '--params', type=str, default='params.yaml')

# Set args manually (notebook mode)
# %cd 'data/llr_fs'
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
pred_unit_subset_dir = Path(params['paths']['pred_unit_subset_dir'])

# Parameters for computing log-likelihoods
r_start = params['model']['r_start']
r_stop = params['model']['r_stop']
r_floor = params['model']['r_floor']
win_size = params['model']['win_size']

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
# Select random subset of units to fit LLR model to

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

# Select HMM units in session
with timex('Selecting units from session...'):
    fs_data = {k: select_units_data(v, units_hmm_idx) for k, v in fs_data.items()}

# %%
# Compute log-likelihood ratio and derived states

# Average responses to priming trials
with timex('Computing response vectors...'):
    responses_prime = stim_priming_responses(fs_data, r_start, r_stop, r_floor)

# LLR and states
with timex('Computing log-likelihood ratio and states...'):
    llr_states = get_llr_win(fs_data, responses_prime, win_size)

# %%
# Save data to joblib file

# Units (in original indexing scheme) for HMM and decoding
units_hmm = units_orig[units_hmm_idx]
units_decode = units_orig[units_decode_idx]

with timex('Saving results...'):
    out_fname = rec_fname(args.session, args.paradigm, args.probes, '.joblib')
    out_fpath = pred_unit_subset_dir / out_fname
    out_data = {
        'pred_states': llr_states,
        'units_hmm': units_hmm,
        'units_decode': units_decode,
    }
    joblib.dump(out_data, out_fpath, compress=True)

# %%
