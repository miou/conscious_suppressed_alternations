# %%
# Compute coherence between states from two probes

# %%
# Imports

from pathlib import Path
import argparse
import yaml
import json
import joblib
import numpy as np
import pandas as pd

from percept_hmm.flash_suppression import iter_aligned
from percept_hmm.pipelines.dataio import rec_fname, get_probe_list
from percept_hmm.pipelines.fs_rivalry import frac_state_agreement

# %%
# Helper functions


def compute_coherence(
    states_1: np.ndarray, states_2: np.ndarray, t_start: int, t_stop: int, lag: int
) -> float:
    """Compute coherence between state sequences from two probes."""

    # States need to be either 0 or 1
    assert np.all(np.isin(np.unique(states_1), [0, 1]))
    assert np.all(np.isin(np.unique(states_2), [0, 1]))

    # Crop states using start and stop time
    states_crop_1 = states_1[t_start:t_stop]
    states_crop_2 = states_2[t_start:t_stop]

    # Align state sequences using lag
    nt = states_crop_1.shape[0]
    assert 0 <= lag < nt, f'`lag` must be in [0, {nt}) for cropped window, got {lag}'
    states_align_1 = states_crop_1[: (nt - lag)]  # For upstream probe, trim end of sequence
    states_align_2 = states_crop_2[lag:]  # For downstream probe, shift forward by `lag`

    # Coherence is fraction of time points where states agree
    coherence = frac_state_agreement(states_align_1, states_align_2)

    return coherence


# %%
# Parse arguments

# Create parser
parser = argparse.ArgumentParser(description='Compute coherence between states from two probes')
parser.add_argument('--session', type=str, required=True)
parser.add_argument('--paradigm', type=str, required=True)
parser.add_argument('--probes', type=str, required=True)
parser.add_argument('-p', '--params', type=str, required=True)

# Set args manually (notebook mode)
# args = parser.parse_args(
#     ['--session', 's168', '--paradigm', 'fsm', '--probes', 'p12', '-p', 'config/fixed_hmm.yaml']
# )

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
probe_coherence_dir = Path(params['paths']['probe_coherence_dir'])

# Parameters for computing coherence
lag = params['probe_coherence']['lag']
t_start = params['probe_coherence']['t_start']
t_stop = params['probe_coherence']['t_stop']

# %%
# Load data

probe_ls = get_probe_list(args.probes, 2)
probe_1_str = f'p{probe_ls[0]}'
probe_2_str = f'p{probe_ls[1]}'

# Filenames for recordings to load
fname_12 = rec_fname(args.session, args.paradigm, args.probes, '.joblib')
fname_1 = rec_fname(args.session, args.paradigm, probe_1_str, '.joblib')
fname_2 = rec_fname(args.session, args.paradigm, probe_2_str, '.joblib')

# Extracted data for both probes
ext_fpath = extract_data_dir / fname_12
fs_data = joblib.load(ext_fpath)['fs_data']

# Estimated states for both probes
fixed_hmm_fpath_12 = pred_all_units_dir / fname_12
fixed_hmm_data_12 = joblib.load(fixed_hmm_fpath_12)
states_12 = fixed_hmm_data_12['pred_states']

# Estimated states for probe 1
fixed_hmm_fpath_1 = pred_all_units_dir / fname_1
fixed_hmm_data_1 = joblib.load(fixed_hmm_fpath_1)
states_1 = fixed_hmm_data_1['pred_states']

# Estimated states for probe 2
fixed_hmm_fpath_2 = pred_all_units_dir / fname_2
fixed_hmm_data_2 = joblib.load(fixed_hmm_fpath_2)
states_2 = fixed_hmm_data_2['pred_states']

# %%
# Calculate coherence

stim_pairs = list(fs_data.keys())

coherence_data = []
for r, c in stim_pairs:
    # Iterate over trial data and rivalry states for stimulus pair (verifying that trial index
    # matches across dictionaries)
    trials_aligned = iter_aligned(
        fs_data[(r, c)], states_1[(r, c)], states_2[(r, c)], states_12[(r, c)]
    )
    for trial, s_trial_1, s_trial_2, s_trial_12 in trials_aligned:
        # Get rivalry states
        ss_1 = s_trial_1['rivalry_states']
        ss_2 = s_trial_2['rivalry_states']
        ss_12 = s_trial_12['rivalry_states']

        # Coherence between probe 1 and probe 2 with lag
        coh_12 = compute_coherence(ss_1, ss_2, t_start=t_start, t_stop=t_stop, lag=lag)

        # Coherence between probe 1 and both probes (no lag)
        coh_1_all = compute_coherence(ss_1, ss_12, t_start=t_start, t_stop=t_stop, lag=0)

        # Coherence between probe 2 and both probes (no lag)
        coh_2_all = compute_coherence(ss_2, ss_12, t_start=t_start, t_stop=t_stop, lag=0)

        coherence_data.append(
            {
                'stim_red': r,
                'stim_cyan': c,
                'trial_index': trial['trial_index'],
                'trial_type': trial['trial_type'],
                'stim_dom': trial['stim_dom'],
                'coh_12': coh_12,
                'coh_1_all': coh_1_all,
                'coh_2_all': coh_2_all,
            }
        )

df = pd.DataFrame(coherence_data)

# %%
# Compute summary statistics

out_data = {}
trial_types = ['priming', 'binocular', 'transparent', 'unambiguous']
trial_abbrs = ['prime', 'binoc', 'trans', 'unamb']
for ttype, tabbr in zip(trial_types, trial_abbrs, strict=True):
    # Compute mean coherence values and set to None if trial type isn't present
    df_sel = df[df['trial_type'] == ttype]
    if len(df_sel) == 0:
        out_data[f'coh_12_{tabbr}'] = None
        out_data[f'coh_1_all_{tabbr}'] = None
        out_data[f'coh_2_all_{tabbr}'] = None
    else:
        out_data[f'coh_12_{tabbr}'] = float(df_sel['coh_12'].mean())
        out_data[f'coh_1_all_{tabbr}'] = float(df_sel['coh_1_all'].mean())
        out_data[f'coh_2_all_{tabbr}'] = float(df_sel['coh_2_all'].mean())

# %%
# Save data to JSON file

print('Saving results...')
out_fpath = probe_coherence_dir / rec_fname(args.session, args.paradigm, args.probes, '.json')
with open(out_fpath, 'w') as f:
    json.dump(out_data, f)
print('Done.')

# %%
