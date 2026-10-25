"""Functions for selecting units from Tsao lab data."""

import numpy as np
from scipy.stats import pearsonr, linregress, kurtosis
import percept_hmm.preprocessing as proc


# TODO: Add docstring
def combine_paradigms(fr_data: dict) -> tuple[np.ndarray, np.ndarray]:

    # List of dictionaries containing `trial_unit_fr` and `trial_times_ks` entries
    pd_data = fr_data.values()

    # Get concatenated versions of these fields across all paradigms
    trial_unit_fr = np.concatenate([x['trial_unit_fr'] for x in pd_data], axis=0)
    trial_times_ks = np.concatenate([x['trial_times_ks'] for x in pd_data], axis=0)

    return trial_unit_fr, trial_times_ks


def filter_firing_rate_total(
    fr_data: dict, inc_units: np.ndarray, min_fr_hz: float
) -> np.ndarray:
    """Removes units from `inc_units` if their average firing rate is below threshold.

    Args:
        fr_data: dict[str, dict]
            Dictionary containing firing rate data for each paradigm
        inc_units: np.ndarray[(N,), int]
            List of units included in analysis
        min_fr_hz: float
            Minimum average firing rate to allow

    Returns:
        inc_units_new: np.ndarray[(M,), int]
            Filtered `inc_units` list
    """

    # Matrix of unit firing rates for each trial across all paradigms
    trial_unit_fr, _ = combine_paradigms(fr_data)

    # Average across all trials to get total average firing rate
    unit_avg_fr = np.mean(trial_unit_fr, axis=0)

    # Get average unit firing rate for units in included list
    inc_unit_avg_fr = unit_avg_fr[inc_units]

    # Only return units in list with firing rate at least minimum
    return inc_units[inc_unit_avg_fr >= min_fr_hz]


def filter_firing_rate_paradigm(
    fr_data: dict, inc_units: np.ndarray, min_fr_hz: float
) -> np.ndarray:
    """Removes units from `inc_units` if firing rate is below threshold for any paradigm.

    Args:
        fr_dict: dict[str, dict]
            Dictionary containing firing rate data for each paradigm
        inc_units: np.ndarray[(N,), int]
            List of units included in analysis
        min_fr_hz: float
            Minimum average firing rate to allow

    Returns:
        inc_units_new: np.ndarray[(M,), int]
            Filtered `inc_units` list
    """

    # Compute average unit firing rates for all paradigms
    pd_unit_fr_list = []
    for data in fr_data.values():
        pd_unit_fr_list.append(np.mean(data['trial_unit_fr'], axis=0))
    pd_unit_fr = np.vstack(pd_unit_fr_list)

    # Average unit firing rates for included units
    pd_unit_fr_inc = pd_unit_fr[:, inc_units]

    # Keep units with average firing rate greater than threshold in all paradigms
    pd_unit_gt_th = pd_unit_fr_inc >= min_fr_hz
    keep_unit = np.all(pd_unit_gt_th, axis=0)

    return inc_units[keep_unit]


def filter_firing_rate_trial(
    fr_data: dict, inc_units: np.ndarray, max_fr_hz: float
) -> np.ndarray:
    """Removes units from `inc_units` whose firing rates exceed threshold for any trial.

    Args:
        fr_data: dict[str, dict]
            Dictionary containing firing rate data for each paradigm
        inc_units: np.ndarray[(N,), int]
            List of units included in analysis
        max_fr_hz: float
            Maximum average firing rate to allow for single trial

    Returns:
        inc_units_new: np.ndarray[(M,), int]
            Filtered `inc_units` list
    """

    # Unit firing rates for each trial across all paradigms
    trial_unit_fr, _ = combine_paradigms(fr_data)

    # Restrict to included units
    trial_unit_fr_inc = trial_unit_fr[:, inc_units]

    # Only return included units with firing rates at most threshold for all trials
    inc_units_keep = np.all(trial_unit_fr_inc <= max_fr_hz, axis=0)

    return inc_units[inc_units_keep]


def filter_time_corr(
    fr_data: dict, inc_units: np.ndarray, corr_th: float, pval_th: float
) -> np.ndarray:
    """Removes units from `inc_units` if firing rate is correlated with trial time.

    If unit has Pearson correlation with trial time higher than `corr_th` with p-value
    less than `pval_th` in any paradigm in session, it will be dropped.

    Args:
        fr_data: dict[str, dict]
            Dictionary containing firing rate data for each paradigm
        inc_units: np.ndarray[(N,), int]
            List of units included in analysis
        corr_th: float
            Threshold for Pearson correlation
        pval_th: float
            Threshold for p-value

    Returns:
        inc_units_new: np.ndarray[(M,), int]
            Filtered `inc_units` list
    """

    # Unit firing rates and trial times for each trial across all paradigms
    trial_unit_fr, trial_times = combine_paradigms(fr_data)

    # Restrict to included units
    trial_unit_fr_inc = trial_unit_fr[:, inc_units]

    # Compute correlation of each unit's firing rate with trial time and store p-value
    n_units = trial_unit_fr_inc.shape[1]
    corrs = np.zeros(n_units)
    pvals = np.zeros(n_units)
    for i in range(n_units):
        res = pearsonr(trial_times, trial_unit_fr_inc[:, i])
        corrs[i] = res.statistic
        pvals[i] = res.pvalue

    # Drop all units with correlation significantly greater than threshold
    corr_gt_th = np.abs(corrs) > corr_th
    corr_significant = pvals < pval_th
    drop_units = np.logical_and(corr_gt_th, corr_significant)
    keep_unit = np.logical_not(drop_units)

    return inc_units[keep_unit]


# TODO: Determine if this function is even necessary for what we're doing
# TODO: Write tests
# TODO: Add docstring
def get_trials_ordered(pd_dict):
    ks_trials_all = []
    for pd, data in pd_dict.items():
        # Extract data
        spikes_units = data['spikes']
        trial_times = data['trial_times']
        ks_times = data['trial_times_ks_1']

        # Add (kilosort time, trial) tuples to list
        trials = list(proc.gen_trials(spikes_units, trial_times))
        for i in range(len(trials)):
            ks_trials_all.append((ks_times[i], trials[i]))

    # Sort list of tuples by first value, which is kilosort time
    ks_trials_sorted = sorted(ks_trials_all)
    ks_times_sorted = [x[0] for x in ks_trials_sorted]
    trials_sorted = [x[1] for x in ks_trials_sorted]

    return trials_sorted, ks_times_sorted


def calc_drift_ratio(ks_times, unit_fr):
    """Calculate drift ratio for single unit.

    Args:
        ks_times: np.ndarray
            Start times for each trial (sec)
        unit_fr: np.ndarray
            Unit firing rate in each trial (Hz)
    Returns:
        drift_ratio: float
            Average rate of drift (Hz/hr) divided by average firing rate
        pval: float
            P-value for regression
    """
    
    # Run linear regression
    res = linregress(ks_times, unit_fr)
    pval = res.pvalue

    # Drift ratio: drift rate (hz per hour) divided by unit average firing rate
    drift_rate_hz_hr = res.slope * 3600
    unit_fr_avg = np.mean(unit_fr) + 1e-8
    drift_ratio = np.abs(drift_rate_hz_hr) / unit_fr_avg

    return drift_ratio, pval


def filter_drift_ratio(
    fr_data: dict, inc_units: np.ndarray, drift_ratio_th: float, pval_th: float
) -> np.ndarray:
    """Removes units from `inc_units` if drift ratio exceeds threshold.

    The drift ratio for a unit is computed as the rate of drift (Hz/hr) divided by the 
    unit's average firing rate (Hz). 

    Args:
        fr_data: dict[str, dict]
            Dictionary containing firing rate data for each paradigm
        inc_units: np.ndarray[(N,), int]
            List of units included in analysis
        drift_ratio_th: float
            Threshold for drift ratio 
        pval_th: float
            Threshold for p-value

    Returns:
        inc_units_new: np.ndarray[(M,), int]
            Filtered `inc_units` list
    """

    # Unit firing rates and trial times for each trial across all paradigms
    trial_unit_fr, trial_times = combine_paradigms(fr_data)

    # Restrict to included units
    trial_unit_fr_inc = trial_unit_fr[:, inc_units]

    # Compute drift ratio for each unit
    n_units = trial_unit_fr_inc.shape[1]
    drift_ratios = np.zeros(n_units)
    pvals = np.zeros(n_units)
    for i in range(n_units):
        dr, pval = calc_drift_ratio(trial_times, trial_unit_fr_inc[:, i])
        drift_ratios[i] = dr
        pvals[i] = pval

    # Drop all units with significant drift ratio greater than threshold
    drop_unit = (drift_ratios > drift_ratio_th) & (pvals < pval_th)
    keep_unit = np.logical_not(drop_unit)

    return inc_units[keep_unit]


def filter_kurtosis_total(
    fr_data: dict, inc_units: np.ndarray, kurtosis_th: float
) -> np.ndarray:
    """Removes units from `inc_units` if their kurtosis is above threshold.

    Args:
        fr_data: dict[str, dict]
            Dictionary containing firing rate data for each paradigm
        inc_units: np.ndarray[(N,), int]
            List of units included in analysis
        kurtosis_th: float
            Maximum allowed kurtosis for firing rate distribution

    Returns:
        inc_units_new: np.ndarray[(M,), int]
            Filtered `inc_units` list
    """

    # Unit firing rates and trial times for each trial across all paradigms
    trial_unit_fr, _ = combine_paradigms(fr_data)

    # Restrict to included units
    trial_unit_fr_inc = trial_unit_fr[:, inc_units]

    # Average across paradigms
    unit_kurtosis = kurtosis(trial_unit_fr_inc, axis=0, fisher=True)

    # Only return units in list with firing rate at least minimum
    return inc_units[unit_kurtosis <= kurtosis_th]
