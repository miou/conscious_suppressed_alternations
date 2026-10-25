"""Functions common to all flash suppression rivalry pipelines."""

import numpy as np

from percept_hmm.flash_suppression import get_stim_priming_trials
from percept_hmm.on_off_model import OnOffModel


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


def stim_priming_responses_on_off(
    fs_data: dict[tuple[int, int], dict],
    bin_size: int,
    r_start: int,
    r_stop: int,
    r_floor: float,
    rng_seed: int,
    sfreq: int = 1000,
) -> dict[int, dict[str, np.ndarray]]:
    """Compute average Off and On response vectors for all stimuli on priming trials.

    A single On-Off model is fit to the priming trials of all stimuli, and then used to
    split each stimulus' priming spikes into Off and On time points. The average response
    is computed separately over each set.

    Returns:
        responses: dict[int, dict[str, np.ndarray]]
            Maps each stimulus to its 'r_off' and 'r_on' average response vectors.

    """

    # Get list of priming trials for all stimuli
    stim_priming_trials = get_stim_priming_trials(fs_data)
    priming_trials_ls = [s for spike_trials in stim_priming_trials.values() for s in spike_trials]

    # Fit On-Off model to all priming trials
    model = OnOffModel(sfreq=sfreq, bin_size=bin_size)
    model.fit(priming_trials_ls, rng_seed=rng_seed)

    # Compute responses for On and Off states separately
    responses = {}
    for s, spike_trials in stim_priming_trials.items():
        # Get lists of On and Off spike arrays for each trial
        off_trials = []
        on_trials = []
        for spikes in spike_trials:
            # Estimate On-Off states
            states = model.estimate_states_trial(spikes)

            # Crop trials to account for visual delay
            spikes_crop = spikes[r_start:r_stop, :]
            states_crop = states[r_start:r_stop]

            # Add On and Off spikes for trial to respective arrays
            off_trials.append(spikes_crop[states_crop == 0])
            on_trials.append(spikes_crop[states_crop == 1])

        # Combine all spikes from Off and On states across trials
        spikes_off = np.concatenate(off_trials, axis=0)
        spikes_on = np.concatenate(on_trials, axis=0)

        # If we have spikes for both states, compute responses the way we typically would
        if spikes_off.shape[0] > 0 and spikes_on.shape[0] > 0:
            r_off = np.mean(spikes_off, axis=0)
            r_off[r_off == 0] = r_floor
            r_on = np.mean(spikes_on, axis=0)
            r_on[r_on == 0] = r_floor

        # If Off state has no spikes, make this response vector all floor value
        elif spikes_off.shape[0] == 0 and spikes_on.shape[0] != 0:
            r_on = np.mean(spikes_on, axis=0)
            r_on[r_on == 0] = r_floor
            r_off = np.full_like(r_on, r_floor)

        # If On state has no spikes, make this response vector all floor value
        elif spikes_on.shape[0] == 0 and spikes_off.shape[0] != 0:
            r_off = np.mean(spikes_off, axis=0)
            r_off[r_off == 0] = r_floor
            r_on = np.full_like(r_off, r_floor)

        # If both states have no spikes, raise error (this should never happen)
        else:
            raise ValueError('Both states have no spikes for stimulus')

        responses[s] = {'r_off': r_off, 'r_on': r_on}

    return responses


def frac_state_agreement(states_1: np.ndarray, states_2: np.ndarray) -> float:
    """Computes fraction of time points where states are the same"""

    # Check that the states are binary
    assert np.all(np.isin(np.unique(states_1), np.array([0, 1]), assume_unique=True))
    assert np.all(np.isin(np.unique(states_2), np.array([0, 1]), assume_unique=True))

    # Mean squared error is 1 - fraction of agreeing states
    mse = np.mean((states_1.astype(np.int64) - states_2.astype(np.int64)) ** 2, axis=0)

    return 1 - mse
