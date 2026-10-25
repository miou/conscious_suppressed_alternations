"""HMM utilities for dynamax implementation."""

import numpy as np
import jax.numpy as jnp
import jax.random as jr
from jax import Array

from dynamax.hidden_markov_model import PoissonHMM
from dynamax.parameters import ParameterSet, PropertySet


def estimate_prior_from_spikes(spikes: np.ndarray) -> tuple[float, float]:
    """Estimates parameters of Gamma prior distribution from spike counts.

    This function assumes that spike counts are generated from a Poisson process
    with a firing rate generated from a Gamma distribution, and uses the method
    of moments to compute estimates for the parameters of this distribution.

    Args:
        spikes: np.ndarray(NT, NN)
            Spike count data for all trials in dataset.

    Returns:
        alpha_est: float
            Alpha parameter of Gamma distribution over firing rates
        beta_est: float
            Beta parameter of Gamma distribution over firing rates
    """

    # Average firing rates for each neuron
    lambda_est = np.mean(spikes, axis=0)

    # Mean and variance of average firing rates
    lambda_mean = np.mean(lambda_est)
    lambda_var = np.var(lambda_est)

    # Method-of-moments estimates of alpha and beta parameters
    alpha_est = lambda_mean**2 / lambda_var
    beta_est = lambda_mean / lambda_var

    return alpha_est, beta_est


def get_init_params(
        key: jr.PRNGKey, 
        hmm: PoissonHMM, 
        startprob_alpha: float,
        transmat_alpha: float,
        lambdas_alpha: float, 
        lambdas_beta: float
        ) -> tuple[ParameterSet, PropertySet]:

    # Random keys
    key_1, key_2, key_3 = jr.split(key, 3)

    # Sample start probabilities from Dirichlet distribution
    startprob_params = jnp.full(hmm.num_states, startprob_alpha)
    startprob_init = jr.dirichlet(key_1, startprob_params)

    # Sample transition matrix from Dirichlet distribution
    transmat_params = jnp.full(hmm.num_states, transmat_alpha)
    transmat_init = jr.dirichlet(key_2, transmat_params, (hmm.num_states,))

    # Sample lambdas from given Gamma distribution
    lambdas_shape = (hmm.num_states, hmm.emission_dim)
    lambdas_init = jr.gamma(key_3, lambdas_alpha, lambdas_shape) / lambdas_beta

    # Initialize model with sampled values
    params, props = hmm.initialize(
        initial_probs=startprob_init,
        transition_matrix=transmat_init,
        emission_rates=lambdas_init
    )

    return params, props


def fit_hmm(
        trial_data: Array, 
        n_components: int, 
        n_neurons: int,
        prior: dict,
        init: dict,
        n_iter: int = 20,
        n_init: int = 50, 
        rng_seed: int = 999
        ) -> tuple[PoissonHMM, ParameterSet, Array]:
    """Fit HMM to spike data using dynamax package."""

   # Create model
    hmm = PoissonHMM(
        num_states=n_components, 
        emission_dim=n_neurons,
        initial_probs_concentration=prior['startprob_alpha'],
        transition_matrix_concentration=prior['transmat_alpha'],
        emission_prior_concentration=prior['lambdas_alpha'],
        emission_prior_rate=prior['lambdas_beta'],
    )

    # Get keys for each initialization value
    key = jr.PRNGKey(rng_seed)
    fit_keys = jr.split(key, n_init)

    max_loglik = None
    params_fit = None
    loglik_vals = None

    for i in range(n_init):

        # Sample initial parameters
        p_init, props = get_init_params(fit_keys[i], hmm, **init)

        # Fit model with EM
        p_fit, ll_hist = hmm.fit_em(
            p_init, 
            props, 
            trial_data,
            num_iters=n_iter, 
            verbose=True
        )
        ll = ll_hist[-1].item()

        # Save model if it has higher log-likelihood than current best model
        if max_loglik is None or ll > max_loglik:
            params_fit = p_fit
            loglik_vals = ll_hist
            max_loglik = ll

    return hmm, params_fit, loglik_vals


def fit_hmm_default(
        trial_data: Array, 
        n_components: int, 
        n_neurons: int,
        n_iter: int = 20,
        n_init: int = 50, 
        rng_seed: int = 999
        ) -> tuple[PoissonHMM, ParameterSet, Array]:
    """Fit HMM to spike data using dynamax package (default settings)."""

    prior = {

        # Parameters for Dirichlet prior over start probability and transition
        # matrix. These prior distributions are used for both initializing their 
        # respective variables and inferring them from data.
        'startprob_alpha': 1.0,
        'transmat_alpha': 1.0,

        # Parameters for Gamma prior over lambda (firing rate) values. This 
        # distribution is not used to initialize the lambda values, just during
        # inference. The only purpose for the prior in our fitting procedure is 
        # to keep the fit lambda values from being exactly zero, as this leads 
        # to numerical instability. Otherwise, we want the prior to be as 
        # uninformative as possible. The alpha and beta value here result in a 
        # distribution that is flat over the range of firing rate values we're 
        # likely to encounter in neural data.
        'lambdas_alpha': 1.1,
        'lambdas_beta': 0.1,
    }

    # Estimate firing rate prior using method of moments
    trial_data_np = [np.array(x) for x in trial_data]
    alpha_est, beta_est = estimate_prior_from_spikes(trial_data_np)

    init = {

        # For start probability and transition matrix, initialize by sampling
        # from prior distribution
        'startprob_alpha': prior['startprob_alpha'],
        'transmat_alpha': prior['transmat_alpha'],

        # Initialize lambdas by sampling from distribution estimated from data
        'lambdas_alpha': alpha_est,
        'lambdas_beta': beta_est,
    }

    return fit_hmm(
        trial_data, 
        n_components, 
        n_neurons, 
        prior, 
        init, 
        n_iter, 
        n_init, 
        rng_seed
    )