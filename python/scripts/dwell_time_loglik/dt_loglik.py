# %%
# Compute dwell time and log-likelihood

# %%
# Imports

import argparse
from collections.abc import Generator, Iterable
from pathlib import Path

import joblib
import numpy as np
import pandas as pd
import yaml
from percept_hmm.fixed_hmm import bin_trial
from percept_hmm.flash_suppression import TrialData, iter_aligned
from percept_hmm.pipelines.dataio import rec_fname
from percept_hmm.pipelines.fixed_hmm import fit_hmms, predict_states
from percept_hmm.pipelines.fs_rivalry import stim_priming_responses
from scipy.special import gammaln, xlogy

# %%
# Helper functions

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

    for r, c in fs_data:
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


def mean_or_nan(vals: list) -> float:
    """Computes mean of values in list and returns NaN if list is empty."""

    if len(vals) == 0:
        return np.nan
    else:
        return np.mean(np.array(vals)).item()


def median_or_nan(vals: list) -> float:
    """Computes median of values in list and returns NaN if list is empty."""

    if len(vals) == 0:
        return np.nan
    else:
        return np.median(np.array(vals)).item()


def select_units_data(trials: list[TrialData], units_keep: np.ndarray) -> list[TrialData]:
    return [{**trial, 'spikes': trial['spikes'][:, units_keep].copy()} for trial in trials]


def row_modes(a: np.ndarray) -> np.ndarray:
    """Get most common value in each row of matrix a."""

    # a: (R, C) array of natural numbers (non-negative ints)
    R, C = a.shape
    n_bins = int(a.max()) + 1

    # offset row i by i * n_bins so each row occupies its own bin range
    offset = a + (np.arange(R) * n_bins)[:, None]
    counts = np.bincount(offset.ravel(), minlength=R * n_bins).reshape(R, n_bins)

    return counts.argmax(axis=1)


def bin_states(states: np.ndarray, bin_size: int) -> np.ndarray:
    """Bin state sequence."""

    # Determine number of bins
    n_bins = len(states) // bin_size

    # Trim time points off end of trial to make trial length divisible by bin size
    n_pts_trim = n_bins * bin_size
    states_trim = states[0:n_pts_trim]

    # Get state labels for each bin using majority vote
    states_rs = states_trim.reshape(n_bins, bin_size)
    states_bin = row_modes(states_rs)

    return states_bin


def poisson_loglik(spikes: np.ndarray, rates: np.ndarray) -> np.ndarray:
    """Compute log-likelihood for each spike count in matrix given each rate."""

    return xlogy(spikes, rates) - rates - gammaln(spikes + 1)


def loglik_trial(
    spikes: np.ndarray,
    states: np.ndarray,
    r_prime: np.ndarray,
    bin_size: int,
    win_start: int,
    win_stop: int,
) -> float:
    """Compute log-likelihood of spike counts given estimated state sequence."""

    # Restrict spikes and states to window
    spikes_win = spikes[win_start:win_stop, :]
    states_win = states[win_start:win_stop]

    # Bin spikes and states
    spikes_bin = bin_trial(spikes_win, bin_size)
    states_bin = bin_states(states_win, bin_size)

    # Create rate matrix for trial using state sequence
    r_bin = r_prime * bin_size
    rates_bin = np.stack([r_bin[i] for i in states_bin], axis=0)

    # Log-likelihood for each spike count
    loglik_spikes = poisson_loglik(spikes_bin, rates_bin)

    # Normalize by number of units in trial
    n_units = spikes.shape[1]
    loglik_norm = np.sum(loglik_spikes) / n_units

    return loglik_norm


def loglik_session(
    fs_data: dict[tuple[int, int], list[TrialData]],
    state_data: dict[tuple[int, int], list[dict]],
    resp_prime: dict[int, np.ndarray],
    bin_size: int,
    win_start: int,
    win_stop: int,
) -> dict[tuple[int, int], list[dict]]:

    loglik_dict = {}

    for r, c in fs_data:
        # Get response vectors and combine into single array
        r_red = resp_prime[r]
        r_cyan = resp_prime[c]
        r_prime = np.stack((r_red, r_cyan), axis=0)

        # Calculate log-likelihood of spikes given predicted state sequence for all trials (checking
        # that trial indices are the same between extracted data and state sequence)
        loglik_dict[(r, c)] = [
            {
                'trial_index': trial['trial_index'],
                'trial_vals': loglik_trial(
                    trial['spikes'], ss['stim_states'], r_prime, bin_size, win_start, win_stop
                ),
            }
            for trial, ss in iter_aligned(fs_data[(r, c)], state_data[(r, c)])
        ]

    return loglik_dict


def loglik_static_trial(
    spikes: np.ndarray, r_prime: np.ndarray, bin_size: int, win_start: int, win_stop: int
) -> float:
    """Compute log-likelihood of spike counts given static response vector."""

    # Restrict spikes to window
    spikes_win = spikes[win_start:win_stop, :]

    # Bin spikes
    spikes_bin = bin_trial(spikes_win, bin_size)

    # Create rate matrix for trial
    n_bins = spikes_bin.shape[0]
    r_bin = r_prime * bin_size
    rates_bin = np.stack([r_bin] * n_bins, axis=0)

    # Log-likelihood for each spike count
    loglik_spikes = poisson_loglik(spikes_bin, rates_bin)

    # Normalize by number of units in trial
    n_units = spikes.shape[1]
    loglik_norm = np.sum(loglik_spikes) / n_units

    return loglik_norm


def loglik_mix_session(
    fs_data: dict[tuple[int, int], list[TrialData]],
    resp_prime: dict[int, np.ndarray],
    bin_size: int,
    win_start: int,
    win_stop: int,
    alpha_red: float,
) -> dict[tuple[int, int], list[dict]]:

    loglik_dict = {}

    for (r, c), trials in fs_data.items():
        # Mixed response is linear combination of red and cyan response vectors
        r_red = resp_prime[r]
        r_cyan = resp_prime[c]
        r_prime = alpha_red * r_red + (1 - alpha_red) * r_cyan

        # Calculate log-likelihood of spikes given static mixed response for all trials
        loglik_dict[(r, c)] = [
            {
                'trial_index': trial['trial_index'],
                'trial_vals': loglik_static_trial(
                    trial['spikes'], r_prime, bin_size, win_start, win_stop
                ),
            }
            for trial in trials
        ]

    return loglik_dict


def loglik_df(loglik_dict: dict[tuple[int, int], list[dict]], col_name: str) -> pd.DataFrame:
    """Create DataFrame of log-likelihood values indexed by trial."""

    rows = [
        {'trial_index': x['trial_index'], col_name: x['trial_vals']}
        for trials in loglik_dict.values()
        for x in trials
    ]

    return pd.DataFrame(rows)


def get_dwell_times(hmm_bin_size, fs_data, params_model, t_start, t_stop):

    # Parameters for fitting HMM
    r_start = params_model['r_start']
    r_stop = params_model['r_stop']
    r_floor = params_model['r_floor']
    hmm_rng_seed = params_model['rng_seed']

    # Compute response vectors
    r_prime = stim_priming_responses(fs_data, r_start, r_stop, r_floor)

    # Fit fixed-rate HMMs to different trial types
    hmms = {}
    for trial_type in ['priming', 'binocular', 'transparent', 'unambiguous']:
        hmms[trial_type] = fit_hmms(fs_data, r_prime, trial_type, hmm_bin_size, hmm_rng_seed)

    # Get states, posterior, and partition for all trials
    pred_states = predict_states(fs_data, hmms, hmm_bin_size)

    # Get run lengths and calculate means
    dt_data = {}
    trial_types = ['priming', 'binocular', 'transparent', 'unambiguous']
    trial_abbrs = ['prime', 'binoc', 'trans', 'unamb']
    state_vals = [0, 1]
    for ttype, tabbr in zip(trial_types, trial_abbrs, strict=True):
        # Get run lengths for given trial type
        rl = get_run_lengths_session(fs_data, pred_states, ttype, t_start, t_stop, state_vals, False)

        # Compute mean and median dwell time for both states
        for state in state_vals:
            dt_data[f'dt_mean_{tabbr}_{state}'] = mean_or_nan(rl[state])
            dt_data[f'dt_median_{tabbr}_{state}'] = median_or_nan(rl[state])

    return dt_data


def get_rel_loglik(hmm_bin_size, fs_data, params_model, params_loglik, t_start, t_stop):

    # Parameters for fitting HMM
    r_start = params_model['r_start']
    r_stop = params_model['r_stop']
    r_floor = params_model['r_floor']
    hmm_rng_seed = params_model['rng_seed']

    # Parameters for log-likelihood calculation
    units_rng_seed = params_loglik['rng_seed']
    frac_units_hmm = params_loglik['frac_units_hmm']
    ll_bin_size = params_loglik['bin_size']
    mix_alpha_red = params_loglik['mix_alpha_red']

    # Get number of HMM units to sample
    n_units = next(iter(fs_data.values()))[0]['spikes'].shape[1]
    n_units_hmm = int(frac_units_hmm * n_units)

    # Sample HMM units
    rng = np.random.default_rng(units_rng_seed)
    units_all_idx = np.arange(n_units)
    units_hmm_idx = np.sort(rng.choice(units_all_idx, n_units_hmm, replace=False))
    units_loglik_idx = np.setdiff1d(units_all_idx, units_hmm_idx)

    # Split data by units
    fs_data_hmm = {k: select_units_data(v, units_hmm_idx) for k, v in fs_data.items()}
    fs_data_loglik = {k: select_units_data(v, units_loglik_idx) for k, v in fs_data.items()}

    # Compute response vectors for both sets of units
    resp_hmm = stim_priming_responses(fs_data_hmm, r_start, r_stop, r_floor)
    resp_loglik = stim_priming_responses(fs_data_loglik, r_start, r_stop, r_floor)

    # Fit fixed-rate HMMs to different trial types
    hmms = {}
    for trial_type in ['priming', 'binocular', 'transparent', 'unambiguous']:
        hmms[trial_type] = fit_hmms(fs_data_hmm, resp_hmm, trial_type, hmm_bin_size, hmm_rng_seed)

    # Predict state sequences for each trial
    state_data = predict_states(fs_data_hmm, hmms, hmm_bin_size)

    # Log-likelihood given state sequence
    loglik_states = loglik_session(
        fs_data_loglik, state_data, resp_loglik, ll_bin_size, t_start, t_stop
    )

    # Log-likelihood for mixed static representation
    loglik_mix = loglik_mix_session(
        fs_data_loglik, resp_loglik, ll_bin_size, t_start, t_stop, mix_alpha_red
    )

    # Compute average log-likelihood across trials
    rows_trial = []
    for (r, c), trials in fs_data.items():
        for trial in trials:
            rows_trial.append(
                {
                    'trial_index': trial['trial_index'],
                    'stim_red': r,
                    'stim_cyan': c,
                    'trial_type': trial['trial_type'],
                    'stim_dom': trial['stim_dom'],
                }
            )
    df_trial = pd.DataFrame(rows_trial)

    # Create DataFrames for state and mix log-likelihood values
    df_loglik_states = loglik_df(loglik_states, 'loglik')
    df_loglik_mix = loglik_df(loglik_mix, 'loglik_mix')

    # Merge dataframes
    df = df_trial.merge(df_loglik_states, on='trial_index').merge(df_loglik_mix, on='trial_index')

    # Average state log-likelihood across all trials, priming trials, and binocular trials
    loglik_all = df['loglik'].mean()
    loglik_prime = df[df['trial_type'] == 'priming']['loglik'].mean()
    loglik_binoc = df[df['trial_type'] == 'binocular']['loglik'].mean()

    # Average mix log-likelihood across all trials, priming trials, and binocular trials
    loglik_mix_all = df['loglik_mix'].mean()
    loglik_mix_prime = df[df['trial_type'] == 'priming']['loglik_mix'].mean()
    loglik_mix_binoc = df[df['trial_type'] == 'binocular']['loglik_mix'].mean()

    # Relative log-likelihoods
    rel_loglik_all = loglik_all - loglik_mix_all
    rel_loglik_prime = loglik_prime - loglik_mix_prime
    rel_loglik_binoc = loglik_binoc - loglik_mix_binoc

    return {
        'rel_loglik_all': rel_loglik_all,
        'rel_loglik_prime': rel_loglik_prime,
        'rel_loglik_binoc': rel_loglik_binoc,
    }


# %%
# Parse arguments

# Create parser
parser = argparse.ArgumentParser(description='Compute dwell time and log-likelihood')
parser.add_argument('--session', type=str, required=True)
parser.add_argument('--paradigm', type=str, required=True)
parser.add_argument('--probes', type=str, required=True)
parser.add_argument('-p', '--params', type=str, default='config/dwell_time_loglik.yaml')

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
dt_loglik_dir = Path(params['paths']['dt_loglik_dir'])

# Parameters for fitting HMM and computing log-likelihood
params_model = params['model']
params_loglik = params['loglik']

# Window to use
t_start = params['dt_loglik']['t_start']
t_stop = params['dt_loglik']['t_stop']

# Bin size values to use
bin_size_vals = params['dt_loglik']['bin_size_vals']

# %%
# Load data

in_fpath = extract_data_dir / rec_fname(args.session, args.paradigm, args.probes, '.joblib')
in_data = joblib.load(in_fpath)
fs_data = in_data['fs_data']

# %%
# Compute median dwell time and log-likelihood for all bin sizes in range

dwell_time_0 = []
dwell_time_1 = []
rel_loglik = []

for bin_size in bin_size_vals:

    # Compute median dwell times during binocular trials
    dt_data = get_dwell_times(bin_size, fs_data, params_model, t_start, t_stop)
    dwell_time_0.append(dt_data['dt_median_binoc_0'])
    dwell_time_1.append(dt_data['dt_median_binoc_1'])

    # Compute relative log-likelihood during binocular trials
    ll_data = get_rel_loglik(bin_size, fs_data, params_model, params_loglik, t_start, t_stop)
    rel_loglik.append(ll_data['rel_loglik_binoc'])

dwell_time_0 = np.array(dwell_time_0)
dwell_time_1 = np.array(dwell_time_1)
rel_loglik = np.array(rel_loglik)

# Compute normalized relative log-likelihood
rel_loglik_norm = (rel_loglik - rel_loglik.min()) / (rel_loglik.max() - rel_loglik.min())


# %%
# Save to file

out_fpath = dt_loglik_dir / rec_fname(args.session, args.paradigm, args.probes, '.joblib')
out_data = {
    'bin_size_vals': np.array(bin_size_vals),
    'dwell_time_0': dwell_time_0,
    'dwell_time_1': dwell_time_1,
    'rel_loglik': rel_loglik,
    'rel_loglik_norm': rel_loglik_norm,
}
joblib.dump(out_data, out_fpath, compress=True)
