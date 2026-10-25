"""Functions for preprocessing Tsao data."""

from collections.abc import Generator

import numpy as np
from scipy.stats import pearsonr


def get_inc_units(all_units: np.ndarray, labels: dict, filter: str) -> np.ndarray:
    """Gets list of unit IDs to include in final data based on filter mode.

    Args:
        all_units: np.ndarray[int, (N,)]
            List of IDs of all units in dataset
        labels: dict
            Dictionary containing lists of units with different labels (e.g. "mua")
        filter: str
            Filter mode.

    Returns:
        inc_units: np.ndarray[int, (M,)]
            List of units from `all_units` to include in final dataset.

    """

    match filter:
        # Only include units marked 'good' that are not in safetags
        case 'good-only':
            good_units = np.setdiff1d(labels['good_units'], labels['safetags_units'])
            return np.intersect1d(all_units, good_units)

        # Include units marked 'good' and 'mua' that are not in safetags
        case 'good-and-mua':
            good_mua_units = np.union1d(labels['good_units'], labels['mua_units'])
            good_mua_units = np.setdiff1d(good_mua_units, labels['safetags_units'])
            return np.intersect1d(all_units, good_mua_units)

        case _:
            raise ValueError(f'Filter "{filter}" not supported.')


def calc_unit_pearson_corr(unit_ids, spikes, trial_times, corr_threshold=0.15, p_val=0.05):
    trial_fr = get_trial_fr(spikes, trial_times)

    num_trials, num_neurons = trial_fr.shape
    trial_numbers = np.arange(num_trials)
    unstable_neurons = []

    for idx, unit_id in enumerate(unit_ids):
        correlation, p_value = pearsonr(trial_numbers, trial_fr[:, idx])
        if p_value < p_val and np.abs(correlation) > corr_threshold:
            unstable_neurons.append(unit_id)

    print(f'pearson stability filtering: {len(unit_ids)} units {len(unstable_neurons)} unstable')
    stable_neurons = np.array(list(set(unit_ids) - set(unstable_neurons)))
    print(f'stable units {len(stable_neurons)}')
    return stable_neurons


def calc_presence_ratio(unit_ids, spikes, bin_duration=60.0, presence_ratio_th=0.9):
    """Simple implementation: define presence as spike count > 0 within a bin of length
    bin duration. Filter out units with presence_ratio < presence_ratio_th."""

    print('Calculating presence ratio...')

    paradigm_len = len(spikes[:, 0]) * 0.01
    if paradigm_len < bin_duration:
        print('Paradigm shorter than presence ratio bin length. Returning all units.')
        return unit_ids

    session_bins = np.arange(0, paradigm_len + bin_duration, bin_duration)
    unstable_neurons = []

    for idx, unit_id in enumerate(unit_ids):
        analog_spikes = (np.where(spikes[:, idx] == 1)[0]) * 0.01
        hist, _ = np.histogram(analog_spikes, session_bins)
        presence_ratio = len(hist[hist > 0]) / (len(session_bins) - 1)
        if presence_ratio < presence_ratio_th:
            unstable_neurons.append(unit_id)

    print(
        f'Presence stability filtering: {len(unit_ids)} tot units {len(unstable_neurons)} unstable units'
    )
    stable_neurons = np.array(list(set(unit_ids) - set(unstable_neurons)))
    print(f'Num stable units {len(stable_neurons)}')
    return stable_neurons


def get_stable_units(in_data: dict, presence_ratio=True):
    """Remove all unstable units either by presence ratio or Pearson correlation metric."""

    out_data = in_data.copy()

    unit_ids, spikes = out_data['unit_ids'], out_data['spikes']

    if presence_ratio:
        return calc_presence_ratio(unit_ids, spikes)
    else:
        trial_times = out_data['trial_times']
        return calc_unit_pearson_corr(unit_ids, spikes, trial_times)


def filter_units(in_data: dict, inc_units: np.ndarray, stability_filter='skip') -> dict:
    """Removes all units with IDs not in list from data.

    Args:
        in_data: dict including fields:
            'unit_ids': np.ndarray[int, (N,)]
                IDs for all units in dataset
            'spikes': np.ndarrray[int, (T, N)]
                Binary spike matrix
        inc_units: np.ndarray[int, (M,)]
            Units to include in final dataset
        stability_filter: string
            "skip" - don't filter by stability; "presence_ratio/pearsonr" - filter by
            stability using the specified calculation

    Returns:
        out_data: dict including fields:
            'unit_ids': np.ndarray[int, (M,)]
                IDs for all units in dataset
            'spikes': np.ndarrray[int, (T, M)]
                Binary spike matrix

    """
    # Copy dictionary before modifying it
    out_data = in_data.copy()

    # Select included units from data
    inc_units_idx = np.isin(out_data['unit_ids'], inc_units).flatten()
    out_data['unit_ids'] = out_data['unit_ids'][inc_units_idx]
    out_data['spikes'] = out_data['spikes'][:, inc_units_idx]

    # Optionally filter stability
    match stability_filter:
        case 'skip':
            return out_data

        case 'presence_ratio' | 'pearsonr':
            use_presence_ratio = stability_filter == 'presence_ratio'
            stable_units = get_stable_units(out_data, presence_ratio=use_presence_ratio)
            stable_units_idx = np.isin(out_data['unit_ids'], stable_units).flatten()
            out_data['unit_ids'] = out_data['unit_ids'][stable_units_idx]
            out_data['spikes'] = out_data['spikes'][:, stable_units_idx]
            return out_data

        case '_':
            raise ValueError(f'Stability filter "{stability_filter}" not supported.')


def get_probe_data(all_data: np.ndarray, neuron_probes: np.ndarray, probe: int) -> np.ndarray:
    """Extracts data for given probe from trials.

    Args:
        all_data: np.ndarray[int,(NT, NN)]
            Spikes from all neurons for all trials
        neuron_probes: np.ndarray[int, (NN,)]
            Index of probe that each neuron was recorded from (e.g. if
            neuron_probes[5] = 2, then neuron 5 was recorded from probe 2)
        probe: int
            Probe to extract data for

    Returns:
        probe_data: np.ndarray[int,(NT, NP)]]
            Spikes for given probe for all trials
    """

    # Boolean index selecting neurons for probe
    neurons = np.argwhere(neuron_probes == probe).flatten()

    return all_data[:, neurons]


def get_runs(gap_times: np.ndarray, gap_threshold: float, min_length: int) -> list[tuple[int, int]]:
    """Computes start and stop indices of runs in trial sequence.

    Args:
        gap_times: np.ndarray[float, (NT - 1)]
            Length of gaps between trials in Kilosort time
        gap_threshold: float
            Maximum value above which trials are split into different segments
        min_length: int
            Minimum number of trials for segment to be considered a run

    Returns:
        run_idx: list[tuple[int, int]]
            List of start and stop trials for each run, in order

    """

    # Find indices of trials immediately following gaps larger than threshold
    post_split_idx = np.nonzero(gap_times > gap_threshold)[0] + 1

    # Get start and stop indices for runs
    run_start_idx = [0] + list(post_split_idx)
    run_stop_idx = list(post_split_idx) + [gap_times.size + 1]
    run_idx_all = list(zip(run_start_idx, run_stop_idx))

    # Remove runs shorter than minimum length
    run_idx = [x for x in run_idx_all if x[1] - x[0] >= min_length]

    return run_idx


def trim_run(run_idx: tuple[int, int], trim_idx: tuple[int, int]) -> tuple[int, int]:
    """Trims run by indices to get subset of trials.

    Args:
        run_idx: tuple[int, int]
            Trial indices for original run. Start index is 'run_idx[0]' and stop
            (exclusive) is 'run_idx[1]'.
        trim_idx: tuple[int, int]
            Trimming indices relative to run. Trimmed run will start at 'run_idx[0] +
            trim_idx[0]' and stop at 'run_idx[0] + trim_idx[1]'.

    Returns:
        run_idx_new: tuple[int, int ]
            Start and stop indices of trimmed run.

    """

    start_new = run_idx[0] + trim_idx[0]
    stop_new = run_idx[0] + trim_idx[1]

    if stop_new > run_idx[1]:
        raise ValueError('Trimmed run is longer than original')

    return (start_new, stop_new)


def get_trial(data: np.ndarray, trial_times: np.ndarray, idx: int) -> np.ndarray:
    """Return data for trial with given index.

     Args:
        data: numpy.ndarray
            Data for all trials. Can be 1D, like eye tracking or population
            spike, or 2D, like spike matrix, as long as first dimension
            corresponds to time.
        trial_times: numpy.ndarray[int, (NR,)]
            Number of time bins per trial
        idx: int
            Index of trial to extract

    Returns:
        trial: numpy.ndarray
            Spikes for trial

    """

    n_pts = data.shape[0]
    n_trials = trial_times.shape[0]
    t_start = trial_times[idx]
    t_stop = trial_times[idx + 1] if idx < (n_trials - 1) else n_pts

    return data[t_start:t_stop]


def gen_trials(data: np.ndarray, trial_times: np.ndarray) -> Generator[np.ndarray, None, None]:
    """Splits data into trials using trial 'on times'.

    Args:
        data: numpy.ndarray
            Data for all trials. Can be 1D, like eye tracking or population
            spike, or 2D, like spike matrix, as long as first dimension
            corresponds to time.
        trial_times: numpy.ndarray[int, (NR,)]
            List of time bins where each trial starts

    Returns:
        trials: generator[numpy.ndarray]
            List of trial arrays

    """

    for i in range(trial_times.size):
        yield get_trial(data, trial_times, i)


def trim_trial(spikes: np.ndarray, bin_size: int) -> np.ndarray:
    """Removes time points at the end of trial that can't be fit in bin.

    Args:
        spikes: np.ndarray of shape (NT, NN)
            Spike counts for each neuron in trial
        bin_size: int
            Size of bin to use

    Returns:
        trimmed_spikes: np.ndarray of shape (NS, NN)
            Spike counts with final NT mod `bin_size` time points removed.

    """

    n_pts_orig = spikes.shape[0]
    n_pts_new = n_pts_orig - n_pts_orig % bin_size

    return spikes[0:n_pts_new, :]


def bin_spikes(spikes: np.ndarray, bin_size: int) -> np.ndarray:
    """Counts spikes in bins for each neuron.

    Args:
        spikes: np.ndarray of shape (NT, NN)
            Spike counts for each neuron
        bin_size: int
            Size of bin to use for spikes

    Returns:
        binned_spikes: np.ndarray of shape (NT / bin size, NN)
            Total number of spikes in bin for each neuron

    """

    n_pts, n_neurons = spikes.shape
    n_bins = n_pts // bin_size

    return np.sum(spikes.reshape(n_bins, bin_size, n_neurons), axis=1)


def bin_spike_trials(
    spikes: np.ndarray, trial_times: np.ndarray, bin_size: int
) -> tuple[np.ndarray, np.ndarray]:
    """Counts spikes in bins while respecting trial boundaries.

    Args:
        spikes: numpy.ndarray[int, (NT, NN)]
            Spike data with NT time bins and NN neurons.
        trial_times: numpy.ndarray[int, (NR,)]
            Time points where trials start.
        bin_size: int
            Size of bin to use for spikes

    Returns:
        spikes_bin: numpy.ndarray[int, (NT, NN)]
            Spike data with NB time bins and NN neurons
        trial_times_bin: numpy.ndarray[int, (NR,)]
            Time points where trials start in new binned data

    """

    # Split spike data into trials
    trials_raw = list(gen_trials(spikes, trial_times))

    # Trim trials to nearest multiple of bin ratio so they can be evenly binned
    trials_trim = [trim_trial(trial, bin_size) for trial in trials_raw]

    # Apply binning to each trial individually
    trials_bin = [bin_spikes(trial, bin_size) for trial in trials_trim]

    # Compute new trial end times in bin units
    trial_len_bin = np.array([t.shape[0] for t in trials_bin])
    trial_end_times_bin = np.cumsum(trial_len_bin)
    trial_times_bin = np.hstack([[0], trial_end_times_bin[:-1]])

    # Combine trials into single matrix
    spikes_bin = np.concatenate(trials_bin, axis=0)

    return spikes_bin, trial_times_bin


def bin_spike_trials_list(trials_raw: list[np.ndarray], bin_size: int) -> list[np.ndarray]:
    """Counts spikes in bins for list of trials.

    Args:
        trials_raw: list[numpy.ndarray]
            List of matrices containing spikes for each trial (number of time bins
            * number of neurons)
        bin_size: int
            Size of bin to use for spikes

    Returns:
        bin_trials: list[numpy.ndarray]
            List of matrices containing binned spikes for each trial
    """

    # Trim trials to nearest multiple of bin ratio so they can be evenly binned
    trials_trim = [trim_trial(trial, bin_size) for trial in trials_raw]

    # Apply binning to each trial individually
    trials_bin = [bin_spikes(trial, bin_size) for trial in trials_trim]

    return trials_bin


def get_continuous_on_times(on_times: np.ndarray, prev_trial_valid: np.ndarray) -> np.ndarray:
    """Gets on times for continuous trials.

    Args:
        on_times: np.ndarray[int, (NT,)]
            On times for original trials
        prev_trial_valid: np.ndarray[int, (NT,)]
            Indicator of whether original trial is "stitched" (0) or continuous
            with previous trial (0)

    Returns:
        on_times_cont: np.ndarray[int, (NS,)]
            On times for continuous trials

    """

    return on_times[prev_trial_valid == 0]


def get_stimulus_trials(
    all_trials: list[np.ndarray], trial_is_face: np.ndarray, stimulus: str
) -> list[np.ndarray]:
    """Extracts trials with given physical stimulus.

    This function is used on data from the physical switches (ps-static)
    paradigm, where each trial is associated with the presentation of an
    unambiguous stimulus in both eyes.

    Args:
        all_trials: list[np.ndarray[int,(NT, NN)]] of length NK
            List of trials containing spikes from all neurons
        trial_is_face: np.ndarray[int, (NK,)] with values 0 and 1
            Binary array encoding whether trial is a face or object stimuli. If
            trial_is_face[k] == 0, then trial k is an object trial, and if
            trial_is_face[k] == 1, then trial k is a face trial.
        stimulus: str['face', 'object']
            Stimulus to extract trials for

    Returns:
        stim_trials: list[np.ndarray[int,(NT, NN)]]
            List of trials for given stimulus

    """

    labeled_trials = zip(all_trials, trial_is_face, strict=True)

    match stimulus:
        case 'object':
            return [t for t, s in labeled_trials if s == 0]
        case 'face':
            return [t for t, s in labeled_trials if s == 1]
        case _:
            raise ValueError('Stimulus must be "face" or "object"')


def get_avg_fr(spikes: np.ndarray, bin_size_sec=0.001) -> np.ndarray:
    """Computes average firing rates of all neurons in Hz.

    Args:
        spikes: np.ndarray[int, (NT, NN)]
            Matrix containing spike counts. The number of spikes for neuron i
            and time bin j is spikes[i,j].
        bin_size_sec: float
            Size of time bins in seconds (default=0.001)

    Returns:
        frate: np.ndarray[float, (NN,)]
            Vector of average firing rates.

    """

    return np.mean(spikes, axis=0) / bin_size_sec


def get_trial_fr(spikes: np.ndarray, trial_times: np.ndarray, bin_size=0.001) -> np.ndarray:
    """Calculate average firing rate of all neurons per trial in Hz.

    Args:
        spikes: np.ndarray of shape (NT, NN)
            Spike counts for each neuron in ms for paradigm
        trial_times: numpy.ndarray[int, (NR,)]
            List of time bins where each trial starts
        bin_size: float
            Size of bin to use (sec)

    Returns:
        firing rate matrix: np.ndarray of shape (N trials , NN)
    """
    spikes_trials = gen_trials(spikes, trial_times)
    trial_fr_rates = []

    for idx, i in enumerate(spikes_trials):
        time_duration = i.shape[0]  # trial duration in number of bins
        total_spikes_per_neuron = np.sum(i, axis=0)
        fr_rates = total_spikes_per_neuron / (time_duration * bin_size)
        trial_fr_rates.append(fr_rates)

    return np.array(trial_fr_rates)


def gen_spike_windows(spikes: np.ndarray, win_size: int):
    """Generator for sliding time windows in array of spikes.

    Args:
        spikes: np.ndarray[int, (NT, NN)]
            Matrix containing spike counts. The number of spikes for neuron i
            and time bin j is spikes[i,j].
        win_size: int
            Size of sliding window in time bins.

    Yields:
        win: np.ndarray[int, (`win_size`, NN)]
            Spike matrix for each time window.

    """

    nt = spikes.shape[0]
    nn = spikes.shape[1]

    n_pad_pre = win_size // 2
    n_pad_post = win_size - n_pad_pre - 1
    n_full = nt - (n_pad_pre + n_pad_post)

    for n_pad in range(n_pad_pre, 0, -1):
        n_real = win_size - n_pad
        pad = np.zeros((n_pad, nn), dtype=int)
        real = spikes[0:n_real, :]
        yield np.vstack((pad, real))

    for t_start in range(n_full):
        t_stop = t_start + win_size
        yield spikes[t_start:t_stop, :]

    for n_pad in range(1, n_pad_post + 1):
        n_real = win_size - n_pad
        real = spikes[-n_real:,]
        pad = np.zeros((n_pad, nn), dtype=int)
        yield np.vstack((real, pad))
