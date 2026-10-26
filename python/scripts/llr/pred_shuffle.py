# %%
# Compute log-likelihood and predict rivalry states

# %%
# Imports

import argparse
from pathlib import Path

import joblib
import numpy as np
import yaml

from percept_hmm.pipelines.dataio import rec_fname
from percept_hmm.pipelines.fs_rivalry import stim_priming_responses
from percept_hmm.pipelines.llr import get_llr_win, shuffle_spikes
from percept_hmm.utils import timex

# %%
# Parse arguments

# Create parser
parser = argparse.ArgumentParser(description='Compute log-likelihood and predict states')
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
pred_shuffle_dir = Path(params['paths']['pred_shuffle_dir'])

# Parameters for computing log-likelihoods
r_start = params['model']['r_start']
r_stop = params['model']['r_stop']
r_floor = params['model']['r_floor']
win_size = params['model']['win_size']

# Parameters for control analysis
rng_seed = params['pred_shuffle']['rng_seed']
win_start = params['pred_shuffle']['win_start']
win_stop = params['pred_shuffle']['win_stop']

# %%
# Load data

in_fpath = extract_data_dir / rec_fname(args.session, args.paradigm, args.probes, '.joblib')
in_data = joblib.load(in_fpath)
fs_data = in_data['fs_data']

# %%
# Compute response vectors

with timex('Computing response vectors...'):
    responses_prime = stim_priming_responses(fs_data, r_start, r_stop, r_floor)

# %%
# Shuffle data

rng = np.random.default_rng(rng_seed)
with timex('Shuffling spikes...'):
    fs_data_shuffle = shuffle_spikes(fs_data, win_start, win_stop, rng)

# %%
# Compute log-likelihood ratio and derived states

# LLR and states
with timex('Computing log-likelihood ratio and states...'):
    llr_states = get_llr_win(fs_data_shuffle, responses_prime, win_size)

# %%
# Save data to joblib file

with timex('Saving results...'):
    out_fpath = pred_shuffle_dir / rec_fname(args.session, args.paradigm, args.probes, '.joblib')
    out_data = {
        'pred_states': llr_states,
    }
    joblib.dump(out_data, out_fpath, compress=True)

# %%
