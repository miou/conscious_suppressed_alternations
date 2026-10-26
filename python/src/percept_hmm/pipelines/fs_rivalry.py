"""Functions common to all flash suppression rivalry pipelines."""

import numpy as np

from percept_hmm.flash_suppression import get_stim_priming_trials


def stim_response_from_trials(
    spike_trials: list[np.ndarray], t_start: int, t_stop: int, r_floor: int
) -> np.ndarray:
    """Computes average response from list of trials."""

    # Check that list is non-empty
    assert len(spike_trials) > 0

    # Crop trials to deal with visual delay
    crop_trials = [x[t_start:t_stop, :] for x in spike_trials]

    # Compute vector of average firing rates for stimulus
    r_vec = np.mean(np.concatenate(crop_trials, axis=0), axis=0)

    # Apply floor value
    r_vec[r_vec == 0] = r_floor

    return r_vec


def stim_priming_responses(
    fs_data: dict[tuple[int, int], dict], t_start, t_stop, r_floor
) -> dict[int, np.ndarray]:
    """Compute average response vectors for all stimuli on priming trials."""

    # Get list of priming trials for each stimulus
    stim_priming_trials = get_stim_priming_trials(fs_data)

    # Compute average priming response for each stimulus
    responses_prime = {
        s: stim_response_from_trials(x, t_start, t_stop, r_floor)
        for s, x in stim_priming_trials.items()
    }

    return responses_prime


def frac_state_agreement(states_1: np.ndarray, states_2: np.ndarray) -> float:
    """Computes fraction of time points where states are the same"""

    # Check that the states are binary
    assert np.all(np.isin(np.unique(states_1), np.array([0, 1]), assume_unique=True))
    assert np.all(np.isin(np.unique(states_2), np.array([0, 1]), assume_unique=True))

    # Mean squared error is 1 - fraction of agreeing states
    mse = np.mean((states_1.astype(np.int64) - states_2.astype(np.int64)) ** 2, axis=0)

    return 1 - mse
