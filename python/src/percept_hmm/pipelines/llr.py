"""Functions for `llr` pipeline."""

import numpy as np
from tsao_lab_data.paradigm import Paradigm

from percept_hmm.flash_suppression import TrialData
from percept_hmm.models.pmm import llr_pois


def llr_win(
    spikes: np.ndarray, rates_1: np.ndarray, rates_2: np.ndarray, win_size: int
) -> np.ndarray:
    """Computes LLR in sliding window of given size. Uses convolution trick to run fast.

    The LLR is log p(spikes | rates_1) - log p(spikes | rates_2), so positive values favor
    `rates_1`. Windows are centered on each time point (`np.convolve` with `mode='same'`), so
    windows near the start and end of the trial cover fewer bins, and for even `win_size` each
    window is offset from its center by one bin.

    Args:
        spikes: Array of spikes (NT, NN)
        rates_1: Firing rates in numerator of likelihood ratio (NN,)
        rates_2: Firing rates in denominator of likelihood ratio (NN,)
        win_size: Size of sliding window

    Returns:
        llr: Sequence of log-likelihood ratio values (NT,)
    """

    # Window can't be longer than trial (`np.convolve` would return array of length `win_size`)
    if win_size > spikes.shape[0]:
        raise ValueError(
            f'Window size ({win_size}) is longer than trial ({spikes.shape[0]} time points)'
        )

    # Compute LLR for each bin in spikes
    llr_raw = llr_pois(spikes, rates_1, rates_2)

    # Convolve with box kernel to get LLR for windows of given size
    llr = np.convolve(llr_raw, np.ones(win_size), mode='same')

    return llr


def stimulus_states_trial(llr_red_cyan: np.ndarray) -> np.ndarray:
    """Compute stimulus states (red: 0, cyan: 1) from log-likelihood ratio (red - cyan).

    Args:
        llr_red_cyan: Sequence of LLR values for all time points (NT,)

    Returns:
        stim_states: Sequence of inferred states for all time points (NT,)
    """

    # Stimulus state is 0 (red) if LLR >= 0 and 1 (cyan) if LLR < 0
    stim_states = (llr_red_cyan < 0).astype(np.int8)

    return stim_states


def rivalry_states_trial(stim_states: np.ndarray, stim_dom: int) -> np.ndarray:
    """Return array where 0 corresponds to dominant state and 1 corresponds to suppressed.

    Args:
        stim_states: Sequence of stimulus states for trial (NT,)
        stim_dom: Which stimulus is dominant in trial (red: 0, cyan: 1)

    Returns:
        riv_states: Sequence of rivalry states for trial (NT,)
    """

    # If red stimulus (state 0) is dominant, then rivalry states are stimulus states
    if stim_dom == 0:
        return stim_states

    # If cyan stimulus (state 1) is dominant, then rivalry states are opposite of stimulus states
    elif stim_dom == 1:
        return 1 - stim_states

    # Dominant stimulus needs to be either 0 (red) or 1 (cyan)
    else:
        raise ValueError(f'Dominant stimulus value {stim_dom} is invalid.')


def get_llr_win(
    fs_data: dict[tuple[int, int], list[TrialData]],
    responses: dict[int, np.ndarray],
    win_size: int,
) -> dict[tuple[int, int], list[dict]]:
    """Compute log-likelihood ratio (LLR) and states for all stimulus pairs in data dict.

    Args:
        fs_data: Dict mapping stimulus pairs to lists of trials
        responses: Dict mapping stimuli to response vectors
        win_size: Size of sliding window used to compute LLR

    Returns:
        llr_dict: Dict mapping stimulus pairs to LLR and derived states

    """

    # Compute LLR for each trial in each stimulus pair
    llr_dict = {}
    for (r, c), trials in fs_data.items():
        # Response vectors for both stimuli
        r_red = responses[r]
        r_cyan = responses[c]

        # Compute LLR and states for all of this stimulus pair's trials
        recs = []
        for trial in trials:
            # Compute LLR for trial
            llr_red_cyan = llr_win(trial['spikes'], r_red, r_cyan, win_size)

            # Assign each time bin to a stimulus state (red or cyan) based on LLR
            stim_states = stimulus_states_trial(llr_red_cyan)

            # Assign each time bin to a rivalry state (dominant or suppressed)
            rivalry_states = rivalry_states_trial(stim_states, trial['stim_dom'])

            recs.append(
                {
                    'trial_index': trial['trial_index'],
                    'llr_red_cyan': llr_red_cyan,
                    'stim_states': stim_states,
                    'rivalry_states': rivalry_states,
                }
            )

        # Add trial records to dictionary
        llr_dict[(r, c)] = recs

    return llr_dict


def select_units_data(trials: list[TrialData], units_keep: np.ndarray) -> list[TrialData]:
    """Restrict spikes in stimulus pair data to subset of units.

    Args:
        trials: List of trial records
        units_keep: Positional indices of units (columns of `spikes`) to keep, not unit IDs

    Returns:
        List of trials with units selected from spikes and all other fields unchanged.

    """

    # All fields besides `spikes` are unchanged (indexing with an array already returns a copy)
    return [{**trial, 'spikes': trial['spikes'][:, units_keep]} for trial in trials]


def shuffle_spikes_win(
    spikes: np.ndarray, win_start: int, win_stop: int, rng: np.random.Generator
) -> np.ndarray:
    """Shuffle spikes in time window independently for each neuron.

    Args:
        spikes: Array of spikes (NT, NN)
        win_start: Start time of window to shuffle inside
        win_stop: End time of window to shuffle inside
        rng: Random number generator for shuffling

    Returns:
        spikes_shuffled: Array of shuffled spikes (NT, NN)
    """

    # Extract window
    spikes_win = spikes[win_start:win_stop, :]

    # Shuffle spikes within this window
    spikes_shuffled = spikes.copy()
    spikes_shuffled[win_start:win_stop, :] = rng.permuted(spikes_win, axis=0)

    return spikes_shuffled


def shuffle_spikes(
    fs_data: dict[tuple[int, int], list[TrialData]],
    win_start: int,
    win_stop: int,
    rng: np.random.Generator,
) -> dict[tuple[int, int], list[TrialData]]:
    """Shuffle spikes in time window independently for each neuron in all trials.

    Args:
        fs_data: Dict mapping stimulus pairs to lists of trials
        win_start: Start time of window to shuffle inside
        win_stop: End time of window to shuffle inside
        rng: Random number generator for shuffling

    Returns:
        fs_data_shuffled: Dict mapping stimulus pairs to lists of trials with shuffled spikes and
            all other fields unchanged
    """

    fs_data_shuffled = {}
    for (r, c), trials in fs_data.items():
        # Shuffle all spikes for this stimulus pair (all fields are unchanged except for `spikes`)
        fs_data_shuffled[(r, c)] = [
            {**trial, 'spikes': shuffle_spikes_win(trial['spikes'], win_start, win_stop, rng)}
            for trial in trials
        ]

    return fs_data_shuffled


def get_data_timecourse(
    pd: Paradigm, sp_dict: dict[tuple[int, int], list[dict]], field: str
) -> np.ndarray:
    """Write data from stimulus pair dict to timecourse array.

    The data for each trial should be written to the same location in the timecourse that the
    trial's spikes are found in in the paradigm's `timecourse_all_units` array.

    Args:
        pd: Paradigm to extract from
        sp_dict: Data, separated by stimulus pair and trial
        field: Name of field to extract from dict

    Returns:
        timecourse: Timecourse array containing trial data

    """

    # Get shape of example data value (could be either (N,), or (N, K))
    data_shape = next(iter(sp_dict.values()))[0][field].shape
    if len(data_shape) not in (1, 2):
        raise ValueError('Can only create timecourse for 1D or 2D arrays.')

    # Initialize empty timecourse array full of NaNs, with time as first dimension
    timecourse = np.full((pd.n_time, *data_shape[1:]), np.nan)

    # Start and stop times of all trials (property rebuilds list on each access, so get it once)
    trial_bounds = pd.trial_bounds

    # Loop through all trials in stimulus pair dict and write data to timecourse
    for sp_trials in sp_dict.values():
        for trial in sp_trials:

            # Extract field to write and index from each trial
            trial_data = trial[field]
            trial_index = trial['trial_index']

            # Get location in timecourse array corresponding to trial
            t_start, t_stop = trial_bounds[trial_index]

            # Write trial data
            if trial_data.shape[0] == (t_stop - t_start):
                timecourse[t_start:t_stop] = trial_data
            else:
                raise ValueError(
                    f'Trial {trial_index}: data length {trial_data.shape[0]} does not match '
                    f'timecourse interval length {t_stop - t_start}'
                )

    return timecourse
