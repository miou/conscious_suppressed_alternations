# %%
# Compute dwell time statistics for HMM

# %%
# Imports

from pathlib import Path
from typing import Iterable, Generator
import argparse
import yaml
import json
import joblib
import numpy as np
import matplotlib.pyplot as plt

from percept_hmm.flash_suppression import iter_aligned
from percept_hmm.pipelines.dataio import rec_fname

# %%
# Helper method


def gen_runs(seq: Iterable[int]) -> Generator[tuple[int, int], None, None]:
    """Generator for runs of an integer sequence.

    A 'run' here is defined as the repitition of a particular value in the sequence, and
    its 'length' is the number of times that value appears.

    Example: `gen_runs([1, 1, 1, 0, 0, 2, 2, 2, 2])` will yield `(1, 3), (0, 2), (2, 4)`.

    Args:
        seq: np.array[int, (N,)]
            Sequence of integers to extract runs from
    Yields:
        value, length: tuple[int, int]
            Value and length of each run

    """

    # Convert sequence to Iterator so we can work with it
    seq_iter = iter(seq)

    # Get first value of sequence, and return if it's empty
    try:
        value = next(seq_iter)
    except StopIteration:
        return

    # Run length of first element in sequence is initialized to one
    length = 1

    # Move through rest of sequence and yield all runs
    for x in seq_iter:
        if x == value:
            length += 1
        else:
            yield (value, length)
            value = x
            length = 1
    yield (value, length)


def get_run_lengths_trial(seq: np.ndarray, vals: list, drop_edges=False) -> dict[int, list[int]]:
    """Collect run lengths for each value in a single trial's state sequence.

    Args:
        seq: np.array[int, (N,)]
            Sequence of integer state values for one trial.
        vals: list[int]
            State values to collect run lengths for.
        drop_edges: bool
            Whether to drop first and last run when calculating lengths.
    Returns:
        run_lengths: dict[int, list[int]]
            Maps each value in `vals` to the list of run lengths of that value
            in `seq`.

    """

    # Dict for storing run lengths for each state
    run_lengths = {v: [] for v in vals}

    # Get all runs in sequence and (optionally) drop edge runs
    run_ls = list(gen_runs(seq))
    if drop_edges:
        run_ls = run_ls[1:-1] if len(run_ls) >= 3 else []

    # Calculate run lengths
    for run_val, run_len in run_ls:
        run_lengths[int(run_val)].append(run_len)

    return run_lengths


def get_run_lengths_session(
    fs_data: dict[tuple[int, int], list[dict]],
    riv_data: dict[tuple[int, int], list[dict]],
    trial_type: str,
    t_start: int,
    t_stop: int,
    vals: list[int],
    drop_edges: bool = False,
) -> dict[int, list[int]]:
    """Get run lengths across all stimulus pairs in session."""

    # Dict for storing run lengths for each state
    run_lengths = {v: [] for v in vals}

    for r, c in fs_data.keys():
        # Iterate over trials (checking that trial indices are the same between extracted data and
        # state sequence)
        for trial, rs_trial in iter_aligned(fs_data[(r, c)], riv_data[(r, c)]):
            # Get trial type, dominant stimulus, and rivalry states for trial
            t_type = trial['trial_type']
            r_states = rs_trial['rivalry_states']

            # Extract time window from state sequence
            r_states_win = r_states[t_start:t_stop]

            if t_type == trial_type:
                # Run lengths for all values in given trial
                rlen_trial = get_run_lengths_trial(r_states_win, vals, drop_edges)

                # Add run lengths for trial to full list for each value
                for v in vals:
                    run_lengths[v] += rlen_trial[v]

    return run_lengths


def mean_or_none(vals: list) -> float | None:
    """Computes mean of values in list and returns None if list is empty."""

    if len(vals) == 0:
        return None
    else:
        return np.mean(np.array(vals)).item()


def median_or_none(vals: list) -> float | None:
    """Computes median of values in list and returns None if list is empty."""

    if len(vals) == 0:
        return None
    else:
        return np.median(np.array(vals)).item()


# %%
# Parse arguments

# Create parser
parser = argparse.ArgumentParser(description='Compute dwell time statistics for HMM')
parser.add_argument('--session', type=str, required=True)
parser.add_argument('--paradigm', type=str, required=True)
parser.add_argument('--probes', type=str, required=True)
parser.add_argument('-p', '--params', type=str, default='params.yaml')

# Set args manually (notebook mode)
# %cd 'data/fixed_hmm_fs'
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
pred_all_units_dir = Path(params['paths']['pred_all_units_dir'])
dwell_time_dir = Path(params['paths']['dwell_time_dir'])

# Analysis parameters
t_start = params['dwell_time']['t_start']
t_stop = params['dwell_time']['t_stop']
drop_edges = params['dwell_time']['drop_edges']

# %%
# Load data

# Filename used for data in DVC pipeline
fname = rec_fname(args.session, args.paradigm, args.probes, '.joblib')

# Load trial data
ext_data_fpath = extract_data_dir / fname
ext_data = joblib.load(ext_data_fpath)
fs_data = ext_data['fs_data']

# Data from fit model
pred_all_units_fpath = pred_all_units_dir / fname
state_data = joblib.load(pred_all_units_fpath)
riv_data = state_data['pred_states']

# %%
# Get run lengths and calculate means

out_data = {}
trial_types = ['priming', 'binocular', 'transparent', 'unambiguous']
trial_abbrs = ['prime', 'binoc', 'trans', 'unamb']
state_vals = [0, 1]
for ttype, tabbr in zip(trial_types, trial_abbrs, strict=True):
    # Get run lengths for given trial type
    rl = get_run_lengths_session(fs_data, riv_data, ttype, t_start, t_stop, state_vals, drop_edges)

    # Compute mean and median dwell time for both states
    for state in state_vals:
        out_data[f'dt_mean_{tabbr}_{state}'] = mean_or_none(rl[state])
        out_data[f'dt_median_{tabbr}_{state}'] = median_or_none(rl[state])

# %%
# Plot distribution of dwell times (notebook mode)

# BIN_SIZE = 20 # Set this to bin size used for model
#
# rl = get_run_lengths_session(
#     fs_data, riv_data, 'binocular', t_start, t_stop, state_vals, drop_edges)
# run_len_0 = np.array(rl[0])
# run_len_bin_0 = (run_len_0 / BIN_SIZE).astype(np.int64)
# assert np.min(run_len_bin_0) > 0
#
# p = 1 / np.mean(run_len_bin_0)
#
## Plot normalized histogram of binned run lengths
# k_max = run_len_bin_0.max()
# bins = np.arange(0.5, k_max + 1.5)
# plt.hist(run_len_bin_0, bins, density=True, alpha=0.6, label='Data')
#
## Overlay PMF of geometric distribution (support {1, 2, ...}) with parameter `p`
# k = np.arange(1, k_max + 1)
# pmf = (1 - p) ** (k - 1) * p
# plt.plot(k, pmf, 'o-', color='C1', label=f'Geometric (p={p:.3f})')
#
# plt.xlabel('Dwell time (bins)')
# plt.ylabel('Probability')
# plt.legend()
# plt.yscale('log')

# %%
# Save data to JSON file

print('Saving results...')
out_fpath = dwell_time_dir / rec_fname(args.session, args.paradigm, args.probes, '.json')
with open(out_fpath, 'w') as f:
    json.dump(out_data, f)
print('Done.')
