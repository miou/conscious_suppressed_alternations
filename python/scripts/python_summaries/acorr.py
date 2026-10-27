# %%
# Compile autocorrelations across all recordings into summary file

# %%
# Imports

import argparse
from pathlib import Path

import joblib
import numpy as np
import yaml
from percept_hmm.pipelines.dataio import rec_fname
from scipy.io import savemat

# %%
# Parse arguments

# Create parser
parser = argparse.ArgumentParser(
    description='Combine autocorrelations across sessions into summary file'
)
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

# Directory where autocorrelation results for each session are output
acorr_dir = Path(params['paths']['acorr_dir'])

# Output directory
out_dir = Path(params['paths']['python_summaries_dir'])

# %%
# Load data

# Load recordings from list
with open(rec_list_fpath) as f:
    rec_list = yaml.safe_load(f)['rec_it']

# Load autocorrelation data for each recording into a list of dicts
acorr_data = []
for rec in rec_list:

    # Load autocorrelation data from file
    acorr_fname = rec_fname(rec['session'], rec['paradigm'], rec['probes'], '.joblib')
    acorr_fpath = acorr_dir / acorr_fname
    acorr_rec = joblib.load(acorr_fpath)

    # Store recording info along with all fields from the autocorrelation file
    acorr_data.append({
        'session': rec['session'],
        'paradigm': rec['paradigm'],
        'probes': rec['probes'],
        **acorr_rec,
    })

# %%
# Collect autocorrelation data

lag_vals = []
acorr_binoc_norm = []
acorr_binoc_shuffle_norm = []
session = []
paradigm = []
probes = []

for data in acorr_data:

    # Check that this recording has a valid binocular trial autocorrelation
    if data['acorr_binoc_norm'] is not None:

        lag_vals.append(data['lags'])
        acorr_binoc_norm.append(data['acorr_binoc_norm'])
        acorr_binoc_shuffle_norm.append(data['acorr_binoc_shuffle_norm'])
        session.append(data['session'])
        paradigm.append(data['paradigm'])
        probes.append(data['probes'])

# Combine autocorrelations into 2D array
acorr_binoc_norm = np.stack(acorr_binoc_norm, axis=0)
acorr_binoc_shuffle_norm = np.stack(acorr_binoc_shuffle_norm, axis=0)

# Check that all lags are equal and then pick one
lags = lag_vals[0]
if not all(np.array_equal(lags, x) for x in lag_vals):
    raise ValueError('Some lag arrays are inconsistent')

# %%
# Compute summary statistics

# Mean and standard deviation of autocorrelation
acorr_binoc_norm_mean = np.mean(acorr_binoc_norm, axis=0)
acorr_binoc_norm_std = np.std(acorr_binoc_norm, axis=0)

# Same for autocorrelation of shuffled signal
acorr_binoc_shuffle_norm_mean = np.mean(acorr_binoc_shuffle_norm, axis=0)
acorr_binoc_shuffle_norm_std = np.std(acorr_binoc_shuffle_norm, axis=0)

# %%
# Save to output file

# Filename to save to
out_fpath = out_dir / 'acorr.mat'

# Package fields into dict and save to MAT file
out_data = {
    'lags': lags,
    'acorr_binoc_norm': acorr_binoc_norm,
    'acorr_binoc_norm_mean': acorr_binoc_norm_mean,
    'acorr_binoc_norm_std': acorr_binoc_norm_std,
    'acorr_binoc_shuffle_norm': acorr_binoc_shuffle_norm,
    'acorr_binoc_shuffle_norm_mean': acorr_binoc_shuffle_norm_mean,
    'acorr_binoc_shuffle_norm_std': acorr_binoc_shuffle_norm_std,
    'session': session,
    'paradigm': paradigm,
    'probes': probes,
}
savemat(out_fpath, out_data, do_compression=True)

# %%
