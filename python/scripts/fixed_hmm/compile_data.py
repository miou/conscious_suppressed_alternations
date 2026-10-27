# %%
# Compile data into MAT file to send to Janis

# %%
# Imports

import argparse
import yaml
from pathlib import Path
from scipy.io import savemat
import numpy as np
import joblib

from tsao_lab_data.session import Session
from percept_hmm.pipelines.dataio import rec_fname
from percept_hmm.pipelines.fixed_hmm import get_data_timecourse

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
data_dir = Path(params['paths']['data_dir'])
extract_data_dir =  Path(params['paths']['extract_data_dir'])
pred_all_units_dir = Path(params['paths']['pred_all_units_dir'])
pred_random_stim_dir = Path(params['paths']['pred_random_stim_dir'])
pred_unit_subset_dir = Path(params['paths']['pred_unit_subset_dir'])
compile_data_dir = Path(params['paths']['compile_data_dir'])
mat_export_dir = Path(params['paths']['mat_export_dir'])

# %%
# Load data from all stages

# Load session and paradigm
session_fpath = data_dir /  f'{args.session}.h5'
session = Session.from_h5(session_fpath)
session_full_name = session.session_name
pd = session.paradigms[args.paradigm]

# Filename used for data in pipeline
fname = rec_fname(args.session, args.paradigm, args.probes, '.joblib')

# Data from fit model
pred_all_units_fpath = pred_all_units_dir / fname
pred_all_units_data = joblib.load(pred_all_units_fpath)

# Data from random stimulus control
pred_random_stim_fpath = pred_random_stim_dir / fname
pred_random_stim_data = joblib.load(pred_random_stim_fpath)

# Data from subset of units
pred_unit_subset_fpath = pred_unit_subset_dir / fname
pred_unit_subset_data = joblib.load(pred_unit_subset_fpath)

# %%
# Convert to timecourses

tc_fields = ['stim_states', 'stim_posterior', 'rivalry_states']
fixed_hmm_timecourses = {k: get_data_timecourse(pd, pred_all_units_data['pred_states'], k) for k in tc_fields}
pred_random_stim_timecourses = {k: get_data_timecourse(pd, pred_random_stim_data['pred_states'], k) for k in tc_fields}
pred_unit_subset_timecourses = {k: get_data_timecourse(pd, pred_unit_subset_data['pred_states'], k) for k in tc_fields}

# %%
# Convert to MATLAB indexing and package into dicts

# Real model predicted states, posterior, and partition
fixed_hmm_matlab = {
    'red_cyan_states': fixed_hmm_timecourses['stim_states'] + 1,
    'red_cyan_posterior': fixed_hmm_timecourses['stim_posterior'],
    'dom_sup_partition': fixed_hmm_timecourses['rivalry_states'] + 1
}

# Control model using random stimuli for rate vectors
pred_random_stim_matlab = {
    'red_cyan_states': pred_random_stim_timecourses['stim_states'] + 1,
    'red_cyan_posterior': pred_random_stim_timecourses['stim_posterior'],
    'dom_sup_partition': pred_random_stim_timecourses['rivalry_states'] + 1,
    'stim_index_abcd': pred_random_stim_data['stim_index_abcd'] + 1,
}

# Control model fitting HMM to random subset of units
pred_unit_subset_matlab = {
    'red_cyan_states': pred_unit_subset_timecourses['stim_states'] + 1,
    'red_cyan_posterior': pred_unit_subset_timecourses['stim_posterior'],
    'dom_sup_partition': pred_unit_subset_timecourses['rivalry_states'] + 1,
    'units_hmm': pred_unit_subset_data['units_hmm'] + 1,
    'units_decode': pred_unit_subset_data['units_decode'] + 1,
}

# Full dict
out_data = {
    'session': session_full_name,
    'paradigm': args.paradigm,
    'probes': args.probes,
    'fixed_hmm': fixed_hmm_matlab,
    'random_stim_control': pred_random_stim_matlab,
    'unit_subset_control': pred_unit_subset_matlab,
}

# %%
# Save to MAT file in pipeline directory

# Save to MAT file
out_fpath = compile_data_dir / rec_fname(args.session, args.paradigm, args.probes, '.mat')
savemat(out_fpath, out_data, do_compression=True)

# Save to export directory, using the filename MATLAB loads states from (see
# matlab/attach_states/state_method_hmm.m): 'hmm_data_<session name>_<probes>.mat'
out_fpath_2 = mat_export_dir / f'hmm_data_{session_full_name}_{args.probes}.mat'
savemat(out_fpath_2, out_data, do_compression=True)

