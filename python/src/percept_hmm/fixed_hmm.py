"""Module for fixed-rate HMM functions."""

import numpy as np
import numpy.random as npr
from hmmlearn.hmm import PoissonHMM


def bin_trial(spikes: np.ndarray, bin_size: int) -> np.ndarray:
    """Place single trial of spikes into bins"""

    # Determine number of bins
    n_pts, n_neurons = spikes.shape
    n_bins = n_pts // bin_size

    # Trim time points off end of trial to make trial length divisible by bin size
    n_pts_trim = n_bins * bin_size
    spikes_trim = spikes[0:n_pts_trim, :]

    # Place spikes into bins
    spikes_bin = np.sum(spikes_trim.reshape(n_bins, bin_size, n_neurons), axis=1)

    return spikes_bin


def expand_trial(preds_bin: np.ndarray, bin_size: int, n_pts_rem: int) -> np.ndarray:
    """Expand single trial of binned predictions to original size."""

    # Expand preds to original timescale, repeating last state for trimmed time points
    preds_exp = np.repeat(preds_bin, bin_size)
    preds_rem = np.full(n_pts_rem, preds_bin[-1])
    preds = np.hstack([preds_exp, preds_rem])

    return preds


def bin_spikes(trials_raw: list[np.ndarray], bin_size: int) -> list[np.ndarray]:
    """Counts spikes in bins for list of trials."""

    return [bin_trial(t, bin_size) for t in trials_raw]


def set_init_params(
    model: PoissonHMM,
    rng: npr.Generator,
    n_components: int,
    n_neurons: int,
    startprob_alpha: float,
    transmat_alpha: float,
) -> None:
    """Set parameters of model object to samples from given distributions."""

    # Sample start probabilities from Dirichlet distribution
    startprob_params = np.full(n_components, startprob_alpha)
    model.startprob_ = rng.dirichlet(startprob_params)

    # Sample transition matrix from Dirichlet distribution
    transmat_params = np.full(n_components, transmat_alpha)
    model.transmat_ = rng.dirichlet(transmat_params, n_components)


def fit_fixed_hmm(
    trial_data: list[np.ndarray],
    n_components: int,
    lambdas: np.ndarray,
    prior_dist: dict | None = None,
    init_dist: dict | None = None,
    n_iter: int = 20,
    tol: float = 0.1,
    n_init: int = 3,
    rng_seed: int = 999,
) -> tuple[PoissonHMM, dict]:
    """Fit HMM to spike data using hmmlearn package."""

    # Put data into format for hmmlearn fitting
    spikes = np.concatenate(trial_data, axis=0)
    trial_lengths = np.array([x.shape[0] for x in trial_data])

    if n_init < 1:
        raise ValueError('n_init must be at least one')

    # If no value is given for prior distribution, use default values for all
    # distribution parameters
    if prior_dist is None:
        prior_dist = {
            'startprob_alpha': 1.0,
            'transmat_alpha': 1.0,
            'lambdas_alpha': 1.1,
            'lambdas_beta': 0.1,
        }

    # If no value is given for initial distribution, use default values for
    # startprob and transmat priors
    if init_dist is None:
        init_dist = {
            'startprob_alpha': 1.0,
            'transmat_alpha': 1.0,
        }

    # Get number of neurons from data
    n_neurons = spikes.shape[1]

    # Create random number generator
    rng = npr.default_rng(rng_seed)

    max_loglik = None
    model_fit = None
    loglik_vals = None

    for i in range(n_init):
        # Create model
        model = PoissonHMM(
            n_components=n_components,
            startprob_prior=prior_dist['startprob_alpha'],
            transmat_prior=prior_dist['transmat_alpha'],
            lambdas_prior=prior_dist['lambdas_alpha'],
            lambdas_weight=prior_dist['lambdas_beta'],
            n_iter=n_iter,
            tol=tol,
            params='t',
            init_params='',
        )

        # Sample initial parameters from initialization distribution
        set_init_params(model, rng, n_components, n_neurons, **init_dist)

        # Set firing rates to fixed values
        model.lambdas_ = lambdas

        # Set start probability to uniform
        model.startprob_ = np.ones(n_components) / n_components

        # Fit model with EM
        model.fit(spikes, trial_lengths)

        # Save model if it has higher log-likelihood than current best model
        ll = model.score(spikes, trial_lengths)
        if max_loglik is None or ll > max_loglik:
            model_fit = model
            loglik_vals = model.monitor_.history
            max_loglik = ll

    fit_info = {
        'n_iter': n_iter,
        'tol': tol,
        'init_dist': init_dist,
        'loglik_vals': np.array(loglik_vals),
        'loglik_final': max_loglik,
    }

    return model_fit, fit_info


def estimate_states_trial(hmm: PoissonHMM, spikes: np.ndarray, bin_size: int) -> np.ndarray:
    """Estimate HMM states on single trial."""

    # Bin spikes in trial, keeping track of number of points removed during binning
    spikes_bin = bin_trial(spikes, bin_size)
    n_rem = spikes.shape[0] - (spikes_bin.shape[0] * bin_size)

    # Predict trial state sequence from binned spike counts
    states_bin = hmm.predict(spikes_bin)

    # Expand state sequence to original size, repeating last value at the end
    states = expand_trial(states_bin, bin_size, n_rem)

    return states


def estimate_states(hmm: PoissonHMM, trials: list[np.ndarray], bin_size: int) -> list[np.ndarray]:
    """Estimate HMM states on all trials."""

    return [estimate_states_trial(hmm, t, bin_size) for t in trials]


def get_posterior_trial(hmm: PoissonHMM, spikes: np.ndarray, bin_size: int) -> np.ndarray:
    """Calculate posterior probability of each HMM state for all time points in trial."""

    # Bin spikes in trial, keeping track of number of points removed during binning
    spikes_bin = bin_trial(spikes, bin_size)
    n_rem = spikes.shape[0] - (spikes_bin.shape[0] * bin_size)

    # Calculate posterior probabilities from binned spike counts
    pos_bin_all = hmm.predict_proba(spikes_bin)

    # Expand state sequence to original size, repeating last value at the end
    pos = []
    for i in range(hmm.n_components):
        pos_bin = pos_bin_all[:, i]
        pos.append(expand_trial(pos_bin, bin_size, n_rem))
    pos = np.stack(pos, axis=1)

    return pos


def get_posterior(hmm: PoissonHMM, trials: list[np.ndarray], bin_size: int) -> list[np.ndarray]:
    """Calculate posterior probability of each HMM state for all trials."""

    return [get_posterior_trial(hmm, t, bin_size) for t in trials]
