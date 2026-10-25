"""Functions for `llr_4s_fs` pipeline."""

from collections.abc import Iterator

import numpy as np
from tsao_lab_data.paradigm import Paradigm


def model_states_trial(ll_red_off: np.ndarray, ll_red_on: np.ndarray, ll_cyan_off: np.ndarray, ll_cyan_on: np.ndarray) -> np.ndarray:
    """Get model states (red/off: 0, red/on: 1, cyan/off: 2, cyan/on: 3) from log-likelihoods."""

    loglik_all = np.stack([ll_red_off, ll_red_on, ll_cyan_off, ll_cyan_on], axis=0)
    model_states = np.argmax(loglik_all, axis=0).astype(np.int8)

    return model_states


def stimulus_states_trial(model_states: np.ndarray) -> np.ndarray:
    """Return array where 0 corresponds to red and 1 corresponds to cyan."""

    # 0 -> 0, 1 -> 0, 2 -> 1, 3 -> 1
    return model_states // 2


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
