"""Functions for two-state Poisson mixture models (PMMs)."""

import numpy as np
from scipy.special import gammaln, xlogy


def loglik_pois(spike_counts: np.ndarray, rates: np.ndarray) -> float | np.ndarray:
    """Computes Poisson log-likelihood of spike counts given a firing rate vector.

    Args:
        spike_counts: np.ndarray[int, (NN,) or (NT, NN)]
            Spike counts for each unit, either a single count vector or one count vector per row
        rates: np.ndarray[float, (NN,) or (NT, NN)]
            Expected spike count for each unit. Must be on the same timescale as `spike_counts`
            (e.g. per-bin rates for per-bin counts, or rates scaled by window length for counts
            summed over windows)

    Returns:
        loglik: float or np.ndarray[float, (NT,)]
            Log-likelihood summed across units: a scalar for a single count vector, or one value
            per row for a count matrix

    """

    # Log-likelihood for each unit, using log-gamma function for numerical stability. Using
    # xlogy(k, r) instead of k * log(r) gives 0 (not NaN) when both count and rate are zero.
    loglik_units = xlogy(spike_counts, rates) - rates - gammaln(spike_counts + 1)

    # Assume units are conditionally independent, so log-likelihood is sum across units
    loglik_all = np.sum(loglik_units, axis=-1)

    return loglik_all


def llr_pois(spike_counts: np.ndarray, rates_1: np.ndarray, rates_2: np.ndarray) -> np.ndarray:
    """Compute Poisson log-likelihood ratio of spike counts given rate vectors."""

    # Check that rates are positive (they always should be)
    if not (np.all(rates_1 > 0) and np.all(rates_2 > 0)):
        raise ValueError('Rates must be positive (apply a floor before computing the LLR).')

    # LLR formula can be expressed as dot product between weights and spike counts, plus offset
    w = np.log(rates_1) - np.log(rates_2)
    b = np.sum(rates_2) - np.sum(rates_1)

    return spike_counts @ w + b
