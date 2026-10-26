# %%
# Compute summary statistics for each session

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
from percept_hmm.pipelines.dataio import rec_fname

# %%
# Helper methods


def get_frac_trial(seq: np.ndarray, val: int) -> float:
    """Get fraction of points in state sequence equal to given state value."""

    if seq.ndim != 1:
        raise ValueError('State sequence must be 1-D')
    if len(seq) == 0:
        raise ValueError('Sequence cannot be empty')

    return np.count_nonzero(seq == val) / len(seq)


def get_frac_state_data(
    fs_data: dict[tuple[int, int], list[dict]], state_data: dict, t_start: int, t_stop: int
) -> pd.DataFrame:
    """Get DataFrame with state occupancy fractions for each trial."""

    rows = []
    for r, c in fs_data.keys():
        # Iterate over trials (checking that trial indices are the same between extracted data and
        # state sequences)
        trials_aligned = iter_aligned(
            fs_data[(r, c)], state_data['pred_states'][(r, c)]
        )
        for trial, pred in trials_aligned:
            # Get data for trial
            t_index = trial['trial_index']
            t_type = trial['trial_type']
            stim_dom = trial['stim_dom']
            s_states = pred['stim_states']
            r_states = pred['rivalry_states']

            # Extract time window from state sequences
            s_states_win = s_states[t_start:t_stop]
            r_states_win = r_states[t_start:t_stop]

            # Fraction of time bins in 'red' state
            frac_red = get_frac_trial(s_states_win, 0)

            # Fraction of time bins in 'dominant' state ("state 0")
            frac_dom = get_frac_trial(r_states_win, 0)

            # Add row for trial
            rows.append(
                {
                    'trial_index': t_index,
                    'trial_type': t_type,
                    'stim_red': r,
                    'stim_cyan': c,
                    'stim_dom': stim_dom,
                    'color_dom': 'red' if stim_dom == 0 else 'cyan',
                    'frac_red': frac_red,
                    'frac_dom': frac_dom,
                }
            )

    return pd.DataFrame(rows)


def clean_float_dict_json(data: dict) -> dict:
    """Converts all NumPy floats to JSON-serializable values in [str, float] dict."""

    clean_data = {}
    for k, v in data.items():
        if np.isnan(v):
            v_clean = None
        else:
            v_clean = float(v)
        clean_data[k] = v_clean

    return clean_data


# %%
# Parse arguments

# Create parser
parser = argparse.ArgumentParser(description='Compute summary statistics for each session')
parser.add_argument('--session', type=str, required=True)
parser.add_argument('--paradigm', type=str, required=True)
parser.add_argument('--probes', type=str, required=True)
parser.add_argument('-p', '--params', type=str, default='params.yaml')

# Set args manually (notebook mode)
# %cd 'data/fixed_hmm'
# args = parser.parse_args(['--session', 's166', '--paradigm', 'fsm', '--probes', 'p12'])

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
stats_dir = Path(params['paths']['stats_dir'])

# Parameters for computing stats
t_start = params['stats']['t_start']
t_stop = params['stats']['t_stop']

# %%
# Load data

# Filename used for data in pipeline
fname = rec_fname(args.session, args.paradigm, args.probes, '.joblib')

# Extracted data
ext_fpath = extract_data_dir / fname
ext_data = joblib.load(ext_fpath)
fs_data = ext_data['fs_data']

# Estimated states (fixed HMM)
pred_all_units_fpath = pred_all_units_dir / fname
pred_all_units_data = joblib.load(pred_all_units_fpath)

# %%
# Compute state occupancy fraction statistics

# State occupancy fractions for each trial
df = get_frac_state_data(fs_data, pred_all_units_data, t_start, t_stop)

# All trials
frac_red_all = df['frac_red'].mean()
frac_dom_all = df['frac_dom'].mean()

# Priming trials
frac_red_prime = df[df['trial_type'] == 'priming']['frac_red'].mean()
frac_dom_prime = df[df['trial_type'] == 'priming']['frac_dom'].mean()

# Binocular trials
frac_red_binoc = df[df['trial_type'] == 'binocular']['frac_red'].mean()
frac_dom_binoc = df[df['trial_type'] == 'binocular']['frac_dom'].mean()

# Priming trials (by color)
frac_red_prime_red = df[(df['trial_type'] == 'priming') & (df['color_dom'] == 'red')][
    'frac_red'
].mean()
frac_red_prime_cyan = df[(df['trial_type'] == 'priming') & (df['color_dom'] == 'cyan')][
    'frac_red'
].mean()
frac_dom_prime_red = df[(df['trial_type'] == 'priming') & (df['color_dom'] == 'red')][
    'frac_dom'
].mean()
frac_dom_prime_cyan = df[(df['trial_type'] == 'priming') & (df['color_dom'] == 'cyan')][
    'frac_dom'
].mean()

# %%
# Save data to JSON file

print('Saving results...')
out_fpath = stats_dir / rec_fname(args.session, args.paradigm, args.probes, '.json')
out_data = clean_float_dict_json(
    {
        'frac_red_all': frac_red_all,
        'frac_dom_all': frac_dom_all,
        'frac_red_prime': frac_red_prime,
        'frac_dom_prime': frac_dom_prime,
        'frac_red_binoc': frac_red_binoc,
        'frac_dom_binoc': frac_dom_binoc,
        'frac_red_prime_red': frac_red_prime_red,
        'frac_red_prime_cyan': frac_red_prime_cyan,
        'frac_dom_prime_red': frac_dom_prime_red,
        'frac_dom_prime_cyan': frac_dom_prime_cyan,
    }
)
with open(out_fpath, 'w') as f:
    json.dump(out_data, f)
print('Done.')

# %%
