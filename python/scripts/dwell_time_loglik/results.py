# %%
# Aggregate dwell time log-likelihood results across recordings

# %%
# Imports

import argparse
from pathlib import Path

import joblib
import matplotlib.pyplot as plt
import numpy as np
import pandas as pd
import yaml
from percept_hmm.pipelines.dataio import rec_fname
from scipy import stats as st
from scipy.io import savemat

# %%
# Parse arguments

# Create parser
parser = argparse.ArgumentParser(description='Aggregate dwell time log-likelihood results')
parser.add_argument('-p', '--params', type=str, default='config/dwell_time_loglik.yaml')

# Set args manually (notebook mode)
# args = parser.parse_args([])

# Parse from command line (script mode)
args = parser.parse_args()

# %%
# Parameters

# Load parameters
with open(args.params, 'r') as f:
    params = yaml.safe_load(f)

# Path to YAML file with lists of recordings in different categories
rec_list_fpath = params['paths']['rec_list_fpath']

# Directory where dwell time log-likelihood results are stored
dt_loglik_dir = Path(params['paths']['dt_loglik_dir'])

# Output directory
results_dir = Path(params['paths']['results_dir'])

# Edges of median dwell time bins for log-likelihood curves
bin_edges = np.array(params['results']['bin_edges'])

# %%
# Load data into DataFrame

# Load recordings from list
with open(rec_list_fpath) as f:
    rec_list = yaml.safe_load(f)['rec_plot_it']

# Load results for each recording
rows = []
for rec in rec_list:
    fpath = dt_loglik_dir / rec_fname(rec['session'], rec['paradigm'], rec['probes'], '.joblib')
    data = joblib.load(fpath)
    bin_size_vals = data['bin_size_vals']
    dwell_time_0 = data['dwell_time_0']
    dwell_time_1 = data['dwell_time_1']
    rel_loglik = data['rel_loglik']
    rel_loglik_norm = data['rel_loglik_norm']

    for i, bin_size in enumerate(bin_size_vals):
        rows.append(
            {
                'rec': fpath.stem,
                'session': rec['session'],
                'paradigm': rec['paradigm'],
                'probes': rec['probes'],
                'bin_size': bin_size,
                'dwell_time_0': dwell_time_0[i],
                'dwell_time_1': dwell_time_1[i],
                'rel_loglik': rel_loglik[i],
                'rel_loglik_norm': rel_loglik_norm[i],
            }
        )

df = pd.DataFrame(rows)

# %%
# Curve of binned values with error bars


def get_binned_curve(dwell_times, loglik, bin_edges, n_smps_min=2):
    """Mean and SEM of log-likelihood in each dwell time bin (NaN for bins with too few points)."""

    bins = np.digitize(dwell_times, bin_edges)

    bin_center = []
    loglik_mean = []
    loglik_sem = []
    for bin_idx in range(1, len(bin_edges)):
        bin_ctr = (bin_edges[bin_idx - 1] + bin_edges[bin_idx]) / 2
        in_bin = bins == bin_idx

        # Keep every bin so curves for both states share the same bin centers
        if np.count_nonzero(in_bin) >= n_smps_min:
            ll_mean = np.mean(loglik[in_bin])
            ll_sem = st.sem(loglik[in_bin], ddof=1)
        else:
            ll_mean = np.nan
            ll_sem = np.nan
        bin_center.append(bin_ctr)
        loglik_mean.append(ll_mean)
        loglik_sem.append(ll_sem)

    bin_center = np.array(bin_center)
    loglik_mean = np.array(loglik_mean)
    loglik_sem = np.array(loglik_sem)

    return bin_center, loglik_mean, loglik_sem


# Extract series
dwell_time_0 = df['dwell_time_0'].to_numpy()
dwell_time_1 = df['dwell_time_1'].to_numpy()
rel_loglik_norm = df['rel_loglik_norm'].to_numpy()

bin_center_0, ll_mean_0, ll_sem_0 = get_binned_curve(dwell_time_0, rel_loglik_norm, bin_edges)
bin_center_1, ll_mean_1, ll_sem_1 = get_binned_curve(dwell_time_1, rel_loglik_norm, bin_edges)

bin_center = bin_center_0

fig, ax = plt.subplots(layout='constrained')
ax.errorbar(x=bin_center, y=ll_mean_0, yerr=ll_sem_0, fmt='o-', capsize=3, label='state 1')
ax.errorbar(x=bin_center, y=ll_mean_1, yerr=ll_sem_1, fmt='o-', capsize=3, label='state 2')
ax.legend()
ax.set_xlabel('median dwell time (ms)')
ax.set_ylabel('log-likelihood (relative)')

# %%
# Save to output file

# Path to save MAT file to
out_fpath = results_dir / 'hmm_loglik_dwell.mat'

# Bin size values (common to all sessions)
bin_size_vals = np.sort(df['bin_size'].unique())

# Session names
sessions = df['session'].unique().tolist()

# Log-likelihood relative to one-state model and median dwell times for state 1 and state 2
loglik_rel = np.zeros((len(sessions), len(bin_size_vals)))
dt_median_1 = np.zeros((len(sessions), len(bin_size_vals)))
dt_median_2 = np.zeros((len(sessions), len(bin_size_vals)))
for i, s in enumerate(sessions):
    df_session = df[df['session'] == s].sort_values('bin_size')
    loglik_rel[i, :] = df_session['rel_loglik_norm'].to_numpy()
    dt_median_1[i, :] = df_session['dwell_time_0'].to_numpy()
    dt_median_2[i, :] = df_session['dwell_time_1'].to_numpy()

# Package fields into dict and save to MAT file
out_data = {
    'hist_bin_edges': bin_edges,
    'hist_bin_centers': bin_center,
    'hist_loglik_mean_1': ll_mean_0,
    'hist_loglik_sem_1': ll_sem_0,
    'hist_loglik_mean_2': ll_mean_1,
    'hist_loglik_sem_2': ll_sem_1,
    'bin_size_vals': bin_size_vals,
    'loglik_rel': loglik_rel,
    'dt_median_1': dt_median_1,
    'dt_median_2': dt_median_2,
    'sessions': sessions,
}
savemat(out_fpath, out_data, do_compression=True)
