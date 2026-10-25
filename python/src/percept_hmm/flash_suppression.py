"""Functions for working with flash suppression data"""

from collections.abc import Iterator
from typing import TypedDict

import numpy as np
from tsao_lab_data.paradigm import FSParadigm


class TrialData(TypedDict):
    """Data for a single flash suppression trial."""

    trial_index: int
    spikes: np.ndarray
    stim_dom: int
    trial_type: str


def iter_aligned(*trial_lists: list[dict]) -> Iterator[tuple[dict, ...]]:
    """Iterate over trial records from several lists, checking that trial indices match."""

    for trials in zip(*trial_lists, strict=True):
        trial_index = trials[0]['trial_index']
        if any(t['trial_index'] != trial_index for t in trials[1:]):
            raise ValueError(f'Trial indices do not match: {[t["trial_index"] for t in trials]}')
        yield trials


def get_stim_pairs(pd: FSParadigm) -> list[tuple[int, int]]:
    """Extract list of all stimulus pairs used in paradigm."""

    # Get set of all stimulus pairs
    stim_pairs_set = set()
    for i in range(pd.n_trials):
        if pd.trial_is_priming[i] == 1:
            stim_1 = pd.trial_dominant_image_index[i].item()
            stim_2 = pd.trial_suppressed_image_index[i].item()
            if (pd.priming_stimulus_is_red[stim_1] == 1) and (
                pd.priming_stimulus_is_cyan[stim_2] == 1
            ):
                stim_pairs_set.add((stim_1, stim_2))
            elif (pd.priming_stimulus_is_cyan[stim_1] == 1) and (
                pd.priming_stimulus_is_red[stim_2] == 1
            ):
                stim_pairs_set.add((stim_2, stim_1))
            else:
                raise ValueError('Stimulus pair not red/cyan!')

    # Convert to list and sort
    stim_pairs = list(stim_pairs_set)
    stim_pairs = sorted(stim_pairs, key=lambda x: (x[0], x[1]))

    return stim_pairs


def get_stim_pair_spikes(pd: FSParadigm, stim_red: int, stim_cyan: int) -> list[TrialData]:
    """Extracts spike data for all trials belonging to given stimulus pair."""

    # Extract trials for stimulus pair with priming, binocular, transparent, or unambiguous type
    dom_index = pd.trial_dominant_image_index
    sup_index = pd.trial_suppressed_image_index
    is_red_cyan = (dom_index == stim_red) & (sup_index == stim_cyan)
    is_cyan_red = (dom_index == stim_cyan) & (sup_index == stim_red)
    is_prime = pd.trial_is_priming == 1
    is_binoc = pd.trial_is_binocular == 1
    is_trans = pd.trial_is_transparent == 1
    is_unamb = pd.trial_is_unambiguous == 1
    use_trial = (is_red_cyan | is_cyan_red) & (is_prime | is_binoc | is_trans | is_unamb)

    # Indices of trials to extract
    trial_index = np.argwhere(use_trial).flatten().tolist()

    # Extract spikes, trial type and dominant stimulus for each trial
    trials = []
    for i in trial_index:
        # Spike array for trial
        spk = pd.spike_trials[i]

        # Trial type
        if is_prime[i]:
            ttype = 'priming'
        elif is_binoc[i]:
            ttype = 'binocular'
        elif is_trans[i]:
            ttype = 'transparent'
        elif is_unamb[i]:
            ttype = 'unambiguous'
        else:
            raise ValueError(f'No type for trial {i}')

        # Dominant stimulus (out of pair) for trial
        if is_red_cyan[i]:
            s_dom = 0
        elif is_cyan_red[i]:
            s_dom = 1
        else:
            raise ValueError(f'Trial {i} does not have clear dominant stimulus.')

        # Add trial to list
        trials.append({'trial_index': i, 'spikes': spk, 'stim_dom': s_dom, 'trial_type': ttype})

    return trials


def get_stim_pair_data(pd: FSParadigm) -> dict[tuple[int, int], list[TrialData]]:
    """Returns dict mapping stimulus pairs to lists of trial data dicts."""

    stim_pairs = get_stim_pairs(pd)

    return {(r, c): get_stim_pair_spikes(pd, r, c) for r, c in stim_pairs}


def get_stim_list_from_pairs(stim_pairs: list[tuple[int, int]]) -> list[int]:
    """Get list of unique stimuli from stimulus pairs list."""

    # List of all stimuli used in paradigm
    stim_all_set = set()
    for stim_red, stim_cyan in stim_pairs:
        stim_all_set.add(stim_red)
        stim_all_set.add(stim_cyan)
    stim_all = sorted(list(stim_all_set))

    return stim_all


def get_stim_priming_trials(
    fs_data: dict[tuple[int, int], list[TrialData]],
) -> dict[int, list[np.ndarray]]:
    """Gets list of all priming trials for each stimulus."""

    stim_pairs = list(fs_data.keys())
    stim_all = get_stim_list_from_pairs(stim_pairs)

    spike_trials_prime = {s: [] for s in stim_all}
    for (r, c), trials in fs_data.items():
        # Add priming trials to lists
        for trial in trials:
            if trial['trial_type'] == 'priming':
                if trial['stim_dom'] == 0:  # Red priming trial
                    spike_trials_prime[r].append(trial['spikes'])
                elif trial['stim_dom'] == 1:  # Cyan priming trial
                    spike_trials_prime[c].append(trial['spikes'])

    return spike_trials_prime
