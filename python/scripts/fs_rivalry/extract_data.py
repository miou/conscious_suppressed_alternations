# %%
# Extract flash suppression data from session file and save in joblib file

# %%
# Imports

import argparse
import json
from pathlib import Path

import joblib
import numpy as np
import yaml
from tsao_lab_data.session import Session

from percept_hmm.flash_suppression import get_stim_pair_data
from percept_hmm.pipelines.dataio import get_probe_list, get_units_select, rec_fname
from percept_hmm.utils import timex

# %%
# Parse arguments

# Create parser
parser = argparse.ArgumentParser(description='Extract flash suppression data needed for fixed HMM')
parser.add_argument('--session', type=str, required=True)
parser.add_argument('--paradigm', type=str, required=True)
parser.add_argument('--probes', type=str, required=True)
parser.add_argument('-p', '--params', type=str, default='params.yaml')

# Set args manually (notebook mode)
# %cd 'data/fixed_hmm_fs'
# args = parser.parse_args(['--session', 's166', '--paradigm', 'fsm', '--probes', 'p12'])

# Parse from command line (script mode)
args = parser.parse_args()

# %%
# Parameters

# Load parameters
with open(args.params, 'r') as f:
    params = yaml.safe_load(f)

# Directory paths
data_dir = Path(params['paths']['data_dir'])
extract_data_dir = Path(params['paths']['extract_data_dir'])

# Parameters for data extraction
select_repeat_stimuli = params['extract_data']['select_repeat_stimuli']

# %%
# Load data

# Load session information
print('Loading session info...')
session_fpath = data_dir / f'{args.session}/session.h5'
session_info = Session.from_h5(session_fpath, load_paradigms=False)
print('Done.')

# List of probes to fit to
probes = get_probe_list(args.probes, session_info.n_probes)

# List of units to select
units_keep = get_units_select(session_info, probes, [])

# Load session file (only load selected units if we need to)
with timex('Loading session file...'):
    if np.array_equal(units_keep, np.arange(session_info.n_units)):
        session = Session.from_h5(session_fpath)
    else:
        session = Session.from_h5(session_fpath, units=units_keep)

# %%
# Extract data

# Extract data for stimulus pairs
with timex('Extracting data...'):
    pd = session.paradigms[args.paradigm]
    fs_data = get_stim_pair_data(pd)

# Select repeatedly presented stimuli in FSM paradigms
RSTIM_MAX = 60
if select_repeat_stimuli and (args.paradigm in ['fsm', 'fsmt']):
    print('Selecting repeat stimuli...')
    fs_data = {(r, c): d for (r, c), d in fs_data.items() if r < RSTIM_MAX and c < RSTIM_MAX}
    print('Done.')

# %%
# Save to file

with timex('Saving results...'):
    out_fpath = extract_data_dir / rec_fname(args.session, args.paradigm, args.probes, '.joblib')
    out_data = {
        'session': args.session,
        'paradigm': args.paradigm,
        'probes': args.probes,
        'units': units_keep,
        'fs_data': fs_data,
    }
    joblib.dump(out_data, out_fpath, compress=True)

# %%
