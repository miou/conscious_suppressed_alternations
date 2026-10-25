"""Statistical functions"""

from typing import Iterable, Generator
import numpy as np
import numpy.random as npr
import scipy.stats as st
import scipy.signal as sig


def gamma_pdf(x: np.ndarray, alpha: float, beta: float) -> np.ndarray:
    """Compute PDF of Gamma distribution.

    Args:
        x: numpy.ndarray[float, (N,)]
            Values to compute PDF for
        alpha: float
            Alpha (concentration) parameter of Gamma distribution
        beta: float
            Beta (rate) parameter of Gamma distribution

    Returns:
        y: numpy.ndarray[float, (N,)]
            PDF values at given points

    """

    return st.gamma.pdf(x, a=alpha, scale=(1 / beta))


def sample_gamma(rng: npr.Generator, alpha: float, beta: float, size=None):
    """Sample from Gamma distribution

     Args:
        rng: numpy.random.Generator
            Random number generator
        alpha: float
            Alpha (concentration) parameter of Gamma distribution
        beta: float
            Beta (rate) parameter of Gamma distribution
        size: int or tuple of ints
            Size of returned samples (optional)

    Returns:
        x: float or numpy.ndarray
            Samples from specified distribution

    """

    return rng.gamma(alpha, size=size) / beta


def corrcoef_trials(trials_1: list[np.ndarray], trials_2: list[np.ndarray]) -> float:
    """Correlation coefficient for data with multiple trials.

    Args:
        trials_1: list[np.ndarray[(NT,)]]
            Trials of first variable
        trials_2: list[np.ndarray[(NT,)]]
            Trials of second variable

    Returns:
        corrcoef: float
            Pearson correlation coefficient of two variables
    """

    all_data_1 = np.concatenate(trials_1)
    all_data_2 = np.concatenate(trials_2)

    return np.corrcoef(all_data_1, all_data_2)[0, 1]


def xcorr_trials(
    trials_1: list[np.ndarray], trials_2: list[np.ndarray], max_lag: int
) -> tuple[np.ndarray, np.ndarray]:
    """Cross-covariance for data with multiple trials (per-lag averaged).

    Cross-covariance is computed assuming that trials are independent. At each
    lag the summed lag products are divided by the number of overlapping sample
    pairs contributing to that lag, so the result estimates the cross-covariance
    without the triangular taper that a raw summed cross-correlation carries.

    Args:
        trials_1: list[np.ndarray[(NT,)]]
            Trials of first variable
        trials_2: list[np.ndarray[(NT,)]]
            Trials of second variable
        max_lag: int
            Maximum lag value

    Returns:
        xcorr: np.ndarray[float, (`max_lag` * 2 + 1,)]
            Cross-covariance values
        lags: np.ndarray[int, (`max_lag` * 2 + 1,)]
            Lags corresponding to values in `xcorr`

    """

    # Compute mean of both signals
    all_data_1 = np.concatenate(trials_1)
    all_data_2 = np.concatenate(trials_2)
    mu_1 = np.mean(all_data_1)
    mu_2 = np.mean(all_data_2)

    # Accumulate summed lag products and per-lag overlap counts across trials
    xc_sum = np.zeros(2 * max_lag + 1)
    count_sum = np.zeros(2 * max_lag + 1)
    lags = np.arange(-max_lag, max_lag + 1)
    for t1, t2 in zip(trials_1, trials_2):
        # Number of points should be the same for both trials
        n_pts_trial = t1.size

        # Subtract mean from trials
        n1 = t1 - mu_1
        n2 = t2 - mu_2

        # Compute autocorrelation for trial, restricted to (-max_lag, max_lag)
        xc_full = sig.correlate(n1, n2)
        lags_full = sig.correlation_lags(n_pts_trial, n_pts_trial)
        in_range = np.abs(lags_full) <= max_lag
        xc_trial = xc_full[in_range]

        # Number of overlapping sample pairs contributing to each lag
        count_trial = (n_pts_trial - np.abs(lags_full))[in_range]

        # If max_lag is larger than full lags for trial, pad with zeros
        if (diff := xc_sum.size - xc_trial.size) > 0:
            pad = np.zeros(diff // 2)
            xc_trial = np.concatenate([pad, xc_trial, pad])
            count_trial = np.concatenate([pad, count_trial, pad])

        # Increment summed products and overlap counts
        xc_sum += xc_trial
        count_sum += count_trial

    # Divide by per-lag overlap counts to remove the triangular taper. Lags with
    # no overlapping samples in any trial stay zero rather than dividing by zero.
    xc_total = np.divide(xc_sum, count_sum, out=np.zeros_like(xc_sum), where=count_sum > 0)

    return xc_total, lags


def xcorr_trials_norm(
    trials_1: list[np.ndarray], trials_2: list[np.ndarray], max_lag: int
) -> tuple[np.ndarray, np.ndarray]:
    """Cross-correlation for signals with multiple trials (normalized).

    Cross-correlation is computed assuming that trials are independent. Result
    is normalized by dividing by the geometric mean of the lag-zero
    autocorrelations of the two signals, which bounds the values to [-1, 1].

    Args:
        trials_1: list[np.ndarray[(NT,)]]
            Trials of first variable
        trials_2: list[np.ndarray[(NT,)]]
            Trials of second variable
        max_lag: int
            Maximum lag value

    Returns:
        xcorr: np.ndarray[float, (`max_lag` * 2 + 1,)]
            Cross-correlation values
        lags: np.ndarray[int, (`max_lag` * 2 + 1,)]
            Lags corresponding to values in `xcorr`

    """

    # Non-normalized cross-correlation
    xcorr, lags = xcorr_trials(trials_1, trials_2, max_lag)

    # Normalize by dividing by geometric mean of lag-zero autocorrelations
    var_1 = xcorr_trials(trials_1, trials_1, 0)[0][0]
    var_2 = xcorr_trials(trials_2, trials_2, 0)[0][0]
    norm = np.sqrt(var_1 * var_2)
    xcorr_norm = xcorr / norm

    return xcorr_norm, lags


def acorr_trials(
    trials: list[np.ndarray], max_lag: int
) -> tuple[np.ndarray, np.ndarray]:
    """Autocovariance on mean-subtracted data with multiple trials.

    Trials of signal are assumed to be independent. Values are averaged per lag
    by the number of overlapping sample pairs (see `xcorr_trials`), so the result
    estimates the autocovariance without a triangular taper but is not scaled to
    1.0 at lag zero. Lags range from 0 to `max_lag`.

    Args:
        trials: list[np.ndarray[(NT,)]]
            Trials of signal
        max_lag: int
            Maximum lag value

    Returns:
        acorr: np.ndarray[float, (`max_lag` + 1,)]
            Autocovariance values
        lags: np.ndarray[int, (`max_lag` + 1,)]
            Lags corresponding to values in `acorr`

    """

    # Per-lag averaged cross-covariance of the signal with itself
    xcorr_full, lags_full = xcorr_trials(trials, trials, max_lag)

    # Only return values for lags from zero to max
    lag_zero_idx = np.where(lags_full >= 0)
    acorr = xcorr_full[lag_zero_idx]
    lags = lags_full[lag_zero_idx]

    return acorr, lags


def acorr_trials_norm(
    trials: list[np.ndarray], max_lag: int
) -> tuple[np.ndarray, np.ndarray]:
    """Autocorrelation on mean-subtracted data with multiple trials (normalized).

    Trials of signal are assumed to be independent. Lags range from 0 to
    `max_lag`.

    Args:
        trials: list[np.ndarray[(NT,)]]
            Trials of signal
        max_lag: int
            Maximum lag value

    Returns:
        acorr_norm: np.ndarray[float, (`max_lag` + 1,)]
            Autocorrelation values
        lags: np.ndarray[int, (`max_lag` + 1,)]
            Lags corresponding to values in `acorr_norm`

    """

    # Get raw autocorrelation for trial list
    acorr, lags = acorr_trials(trials, max_lag)

    # Normalize autocorrelation by value at lag=0
    acorr_norm = acorr / acorr[0]

    return acorr_norm, lags


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


def get_run_lengths(seq_ls: list[np.ndarray], n_vals: int) -> dict[int, np.ndarray]:
    """Returns dict mapping values in sequence to lengths of all runs."""

    run_lengths = {i: [] for i in range(n_vals)}
    for seq in seq_ls:
        for run_val, run_len in gen_runs(seq):
            run_lengths[int(run_val)].append(run_len)

    return {i: np.array(x) for i, x in run_lengths.items()}


def avg_run_lengths(seq: np.ndarray) -> np.ndarray:
    """Compute average run length for each value in sequence.

    Args:
        seq: np.array([int, (N,)]) 
            Sequence whose distinct values are consecutive integers starting at
            zero (e.g. `[0, 1, 1, 2, 0]`, whose distinct values are 0, 1, 2)
    Returns:
        len_avg: np.array([float, (K,)])
            Average run length for each distinct value, indexed by that value
    
    """

    seq_vals = np.unique(seq)
    n_vals = seq_vals.size
    if not np.array_equal(seq_vals, np.arange(n_vals)):
        raise ValueError('Sequence values must be consecutive integers starting at zero')

    total_length = np.zeros(n_vals)
    n_runs = np.zeros(n_vals)
    for run_value, run_length in gen_runs(seq):
        total_length[run_value] += run_length
        n_runs[run_value] += 1

    return total_length / n_runs
