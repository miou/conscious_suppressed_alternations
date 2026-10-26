# %%
# Fit fixed-rate HMM and predict states

# %%
# Imports

from pathlib import Path
import argparse
import time
import yaml
import joblib

from percept_hmm.pipelines.dataio import rec_fname
from percept_hmm.pipelines.fs_rivalry import stim_priming_responses
from percept_hmm.pipelines.fixed_hmm import (
    fit_hmms,
    predict_states,
)

# %%
# Parse arguments

# Create parser
parser = argparse.ArgumentParser(description='Fit fixed-rate HMM and predict states')
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
pred_all_units_dir = Path(params['paths']['pred_all_units_dir'])

# Parameters for fitting HMM
r_start = params['model']['r_start']
r_stop = params['model']['r_stop']
r_floor = params['model']['r_floor']
hmm_bin_size = params['model']['bin_size']
hmm_rng_seed = params['model']['rng_seed']

# %%
# Load data

in_fpath = extract_data_dir / rec_fname(args.session, args.paradigm, args.probes, '.joblib')
in_data = joblib.load(in_fpath)
fs_data = in_data['fs_data']

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

print('Saving results...')
tic = time.perf_counter()
out_fpath = pred_all_units_dir / rec_fname(args.session, args.paradigm, args.probes, '.joblib')
out_data = {
    'pred_states': pred_states,
}
joblib.dump(out_data, out_fpath, compress=True)
toc = time.perf_counter() - tic
print(f'Done. ({toc:.2f} s)')

# %%
