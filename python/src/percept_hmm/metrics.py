"""Metrics for evaluating HMM models."""

import numpy as np


def nll_norm(loglik, n_pts):
    """Returns normalized negative log-likelihood.

    This metric is used to compare model fitting between datasets that might
    have different numbers of neurons or trials.

    Args:
        loglik: float
            Positive log-likelihood
        n_pts: int
            Total number of time bins in dataset multiplied by number of
            neurons. For example, a dataset with 1000 neurons and 900 time bins
            would have `n_pts = 900000`.

    Returns:
        nll_norm: float
            Normalized negative log-likelihood metric.

    """

    return -loglik / n_pts


def prediction_accuracy(states_est, states_gt):
    """Returns fraction of estimated states that match ground-truth.

    Args:
        states_est: np.ndarray (NT,)
            Estimated states
        states_gt: np.ndarray (NT,)
            Ground-truth states

    Returns:
        pred_acc: float
            Prediction accuracy metric

    """

    n_correct = np.count_nonzero(states_est == states_gt)
    n_bins_total = states_est.size

    return n_correct / n_bins_total
