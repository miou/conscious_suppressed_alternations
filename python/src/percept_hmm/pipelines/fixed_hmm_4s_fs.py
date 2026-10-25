"""Functions for `fixed_hmm_4s_fs` pipeline."""

from collections.abc import Iterator

import numpy as np
from hmmlearn.hmm import PoissonHMM
from tsao_lab_data.paradigm import Paradigm

from percept_hmm.fixed_hmm import (
    bin_spikes,
    estimate_states_trial,
    fit_fixed_hmm,
    get_posterior_trial,
)
from percept_hmm.flash_suppression import TrialData


def fit_hmm_4s_stim_pair(
    trials: list[TrialData],
    resp: dict,
    trial_type: str,
    bin_size: int,
    rng_seed: int,
) -> PoissonHMM | None:
    """Fits two-state fixed-rate HMM with given state response vectors to spike data."""

    # Select trials to train on, and return None if this set is empty
    spikes = [trial['spikes'] for trial in trials if trial['trial_type'] == trial_type]
    if len(spikes) == 0:
        return None

    # Convert rates to (spikes / new bin) and create lamba matrix
    r_red_off_bin = resp['r_red_off'] * bin_size # state 0: red, off
    r_red_on_bin = resp['r_red_on'] * bin_size # state 1: red, on
    r_cyan_off_bin = resp['r_cyan_off'] * bin_size # state 2: cyan, off
    r_cyan_on_bin = resp['r_cyan_on'] * bin_size # state 3: cyan, on

    lambdas = np.stack([r_red_off_bin, r_red_on_bin, r_cyan_off_bin, r_cyan_on_bin], axis=0)

    # Bin trials
    spikes_bin = bin_spikes(spikes, bin_size)

    # Fit model
    hmm, _ = fit_fixed_hmm(spikes_bin, n_components=4, lambdas=lambdas, rng_seed=rng_seed)

    return hmm


def fit_hmms_4s(
    fs_data: dict[tuple[int, int], list[TrialData]],
    responses: dict[int, dict[str, np.ndarray]],
    trial_type: str,
    bin_size: int,
    rng_seed: int,
) -> dict[tuple[int, int], PoissonHMM]:
    """Fit fixed-rate HMMs to trials for all stimulus pairs in data dict."""

    # List of all stimulus pairs we have data for
    stim_pairs = list(fs_data.keys())

    # Fit HMM for each stimulus pair
    hmm_dict = {}
    for r, c in stim_pairs:
        # Get On and Off response vectors for both stimuli
        resp = {
            'r_red_off': responses[r]['r_off'],
            'r_red_on': responses[r]['r_on'],
            'r_cyan_off': responses[c]['r_off'],
            'r_cyan_on': responses[c]['r_on'],
        }

        # Get trial data for stimulus pair
        trials = fs_data[(r, c)]

        # Fit HMM
        hmm_dict[(r, c)] = fit_hmm_4s_stim_pair(trials, resp, trial_type, bin_size, rng_seed)

    return hmm_dict


def stimulus_states_trial(hmm_states: np.ndarray) -> np.ndarray:
    """Return array where 0 corresponds to red and 1 corresponds to cyan."""

    # 0 -> 0, 1 -> 0, 2 -> 1, 3 -> 1
    return hmm_states // 2


def on_off_states_trial(hmm_states: np.ndarray) -> np.ndarray:
    """Return array where 0 corresponds to Off and 1 corresponds to On."""

    # 0 -> 0, 1 -> 1, 2 -> 0, 3 -> 1
    return hmm_states % 2


def rivalry_states_trial(stim_states: np.ndarray, stim_dom: int) -> np.ndarray:
    """Return array where 0 corresponds to dominant state and 1 corresponds to suppressed."""

    # If red stimulus (state 0) is dominant, then rivalry states are stimulus states
    if stim_dom == 0:
        return stim_states

    # If cyan stimulus (state 1) is dominant, then rivalry states are opposite of stimulus states
    elif stim_dom == 1:
        return 1 - stim_states

    # Dominant stimulus needs to be either 0 (red) or 1 (cyan)
    else:
        raise ValueError(f'Dominant stimulus value {stim_dom} is invalid.')


def predict_states(
    fs_data: dict[tuple[int, int], list[TrialData]],
    hmms: dict,
    bin_size: int,
) -> dict[tuple[int, int], list[dict]]:
    """Use HMMs to predict states and posteriors for all trials across all stimulus pairs.

    Returns dict mapping each stimulus pair to per-trial records with fields `trial_index`,
    `hmm_states` (red/off: 0, red/on: 1, cyan/off: 2, cyan/on: 3), `hmm_posterior`,
    `stim_states` (red: 0, cyan: 1), and `rivalry_states` (dominant: 0, suppressed: 1).

    """

    pred_states = {}
    for (r, c), trials in fs_data.items():
        # Compute states and posteriors for all of this stimulus pair's trials
        recs = []
        for trial in trials:
            # Get correct HMM for type of trial
            trial_type = trial['trial_type']
            model = hmms[trial_type][(r, c)]
            if model is None:
                raise ValueError(f'No HMM trained for {trial_type}, ({r}, {c})')

            # Estimate four-state HMM states and their posterior probabilities
            hmm_states = estimate_states_trial(model, trial['spikes'], bin_size)
            hmm_posterior = get_posterior_trial(model, trial['spikes'], bin_size)

            # Collapse HMM states to stimulus states (red or cyan), then rivalry states
            stim_states = stimulus_states_trial(hmm_states)
            rivalry_states = rivalry_states_trial(stim_states, trial['stim_dom'])

            recs.append(
                {
                    'trial_index': trial['trial_index'],
                    'hmm_states': hmm_states,
                    'hmm_posterior': hmm_posterior,
                    'stim_states': stim_states,
                    'rivalry_states': rivalry_states,
                }
            )

        # Add trial records to dictionary
        pred_states[(r, c)] = recs

    return pred_states


def stim_pair_dict_gen_trials(
    sp_dict: dict[tuple[int, int], list[dict]],
    field: str,
) -> Iterator[tuple[np.ndarray, int]]:
    """Generator that yields (trial values, trial index) pairs for all trials in stimulus pair dict"""

    for trials in sp_dict.values():
        for x in trials:
            yield x[field], x['trial_index']


# TODO: Consider replacing with Paradigm.trial_bounds()
def trial_bounds(pd: Paradigm, trial_index: int) -> tuple[int, int]:
    """Get start and stop times in timecourse for trial."""

    t_start = pd.timecourse_on_times[trial_index]
    if trial_index == (pd.n_trials - 1):
        t_stop = pd.n_time
    else:
        t_stop = pd.timecourse_on_times[trial_index + 1]

    return (t_start, t_stop)


def get_data_timecourse(
    pd: Paradigm, sp_dict: dict[tuple[int, int], list[dict]], field: str
) -> np.ndarray:
    """Write data from stimulus pair dict to timecourse array.

    The data for each trial should be written to the same location in the timecourse that the
    trial's spikes are found in in the paradigm's `timecourse_all_units` array.

    Args:
        pd: Paradigm to extract from
        sp_dict: Data, separated by stimulus pair and trial
        field: Name of field to extract from each trial record

    """

    # Get number of points in paradigm timecourse
    n_time = pd.n_time

    # Get shape of example data value (could be either (N,), or (N, K))
    data_shape = next(iter(sp_dict.values()))[0][field].shape

    # Determine dimensions of timecourse based on data shape
    if len(data_shape) == 1:
        tc_shape = (n_time,)
    elif len(data_shape) == 2:
        tc_shape = (n_time, data_shape[1])
    else:
        raise ValueError('Can only create timecourse for 1D or 2D arrays.')

    # Initialize empty timecourse array full of NaNs
    timecourse = np.full(tc_shape, np.nan)

    # Write data from all trials to timecourse
    for trial_data, trial_index in stim_pair_dict_gen_trials(sp_dict, field):
        # Get location in timecourse array corresponding to trial
        t_start, t_stop = trial_bounds(pd, trial_index)

        # Check that timecourse location matches first dimension of trial_data before writing
        assert trial_data.shape[0] == (t_stop - t_start)

        # Write trial data
        timecourse[t_start:t_stop] = trial_data

    return timecourse
