# %%
# Compute summary statistics across recordings

# %%
# Imports

import argparse
import glob
import json
from pathlib import Path

import pandas as pd
import yaml

from percept_hmm.pipelines.dataio import parse_rec_fname

# %%
# Parse arguments

# Create parser
parser = argparse.ArgumentParser(description='Compute summary statistics across recordings')
parser.add_argument('-p', '--params', type=str, default='params.yaml')

# Set args manually (notebook mode)
# %cd 'data/llr_fs'
# args = parser.parse_args([])

# Parse from command line (script mode)
args = parser.parse_args()

# %%
# Parameters

# Load parameters
with open(args.params, 'r') as f:
    params = yaml.safe_load(f)

# Directory paths
stats_dir = Path(params['paths']['stats_dir'])
fso_decoding_dir = Path(params['paths']['fso_decoding_dir'])
probe_coherence_dir = Path(params['paths']['probe_coherence_dir'])
states_loglik_dir = Path(params['paths']['states_loglik_dir'])
summary_stats_dir = Path(params['paths']['summary_stats_dir'])

# %%
# Load stats data from JSON files

# Load all stats files into a list
stats_data = []
for rec_fpath in glob.glob(f'{stats_dir}/*.json'):
    with open(rec_fpath, 'r') as f:
        rec_data = json.load(f)
    rec_fname = Path(rec_fpath).name
    id_data = parse_rec_fname(rec_fname)
    rec_data['session'] = id_data['session']
    rec_data['paradigm'] = id_data['paradigm']
    rec_data['probes'] = id_data['probes']
    stats_data.append(rec_data)

# Create DataFrame from list of records
stats_df = pd.DataFrame(stats_data)

# Sort DataFrame by recording identifiers
rec_cols = ['session', 'paradigm', 'probes']
stats_df = stats_df[rec_cols + [c for c in stats_df.columns if c not in rec_cols]]
stats_df = stats_df.sort_values(by=rec_cols).reset_index(drop=True)

# Add column for number of probes
stats_df['n_probes'] = stats_df['probes'].str.len() - 1

# %%
# Compute summary statistics for stats data

# Priming accuracy
priming_acc_mean = stats_df['priming_acc_mean'].mean(skipna=False)
priming_acc_median = stats_df['priming_acc_mean'].median(skipna=False)
priming_acc_max = stats_df['priming_acc_mean'].max(skipna=False)

# %%
# Load FSO decoding data from JSON files

# Load all JSON files into a list
dec_data = []
for rec_fpath in glob.glob(f'{fso_decoding_dir}/*.json'):
    with open(rec_fpath, 'r') as f:
        rec_data = json.load(f)
    rec_fname = Path(rec_fpath).name
    id_data = parse_rec_fname(rec_fname)
    rec_data['session'] = id_data['session']
    rec_data['paradigm'] = id_data['paradigm']
    rec_data['probes'] = id_data['probes']
    dec_data.append(rec_data)

# Create DataFrame from list of records
dec_df = pd.DataFrame(dec_data)

# Sort DataFrame by recording identifiers
rec_cols = ['session', 'paradigm', 'probes']
dec_df = dec_df[rec_cols + [c for c in dec_df.columns if c not in rec_cols]]
dec_df = dec_df.sort_values(by=rec_cols).reset_index(drop=True)

# Add column for number of probes
dec_df['n_probes'] = dec_df['probes'].str.len() - 1

# %%
# Compute summary statistics for FSO decoding

# Accuracy of priming decoder predicting dominant stimulus using state 1
decode_acc_dom_mean = dec_df['acc_dom_dom'].mean(skipna=False)
decode_acc_dom_median = dec_df['acc_dom_dom'].median(skipna=False)
decode_acc_dom_max = dec_df['acc_dom_dom'].max(skipna=False)

# Accuracy of priming decoder predicting suppressed stimulus using state 2
decode_acc_sup_mean = dec_df['acc_sup_sup'].mean(skipna=False)
decode_acc_sup_median = dec_df['acc_sup_sup'].median(skipna=False)
decode_acc_sup_max = dec_df['acc_sup_sup'].max(skipna=False)


# %%
# Load state log-likelihood data from JSON files

# Load all JSON files into a list
loglik_data = []
for rec_fpath in glob.glob(f'{states_loglik_dir}/*.json'):
    with open(rec_fpath, 'r') as f:
        rec_data = json.load(f)
    rec_fname = Path(rec_fpath).name
    id_data = parse_rec_fname(rec_fname)
    rec_data['session'] = id_data['session']
    rec_data['paradigm'] = id_data['paradigm']
    rec_data['probes'] = id_data['probes']
    loglik_data.append(rec_data)

# Create DataFrame from list of records
loglik_df = pd.DataFrame(loglik_data)

# Sort DataFrame by recording identifiers
rec_cols = ['session', 'paradigm', 'probes']
loglik_df = loglik_df[rec_cols + [c for c in loglik_df.columns if c not in rec_cols]]
loglik_df = loglik_df.sort_values(by=rec_cols).reset_index(drop=True)

# Add column for number of probes
loglik_df['n_probes'] = loglik_df['probes'].str.len() - 1

# %%
# Compute summary statistics for state log-likelihood

# Log-likelihood of state sequence for binocular trials
loglik_binoc_mean = loglik_df['loglik_binoc'].mean(skipna=False)
loglik_binoc_median = loglik_df['loglik_binoc'].median(skipna=False)
loglik_binoc_max = loglik_df['loglik_binoc'].max(skipna=False)

# Log-likelihood of static mixed response for binocular trials
loglik_mix_binoc_mean = loglik_df['loglik_mix_binoc'].mean(skipna=False)
loglik_mix_binoc_median = loglik_df['loglik_mix_binoc'].median(skipna=False)
loglik_mix_binoc_max = loglik_df['loglik_mix_binoc'].max(skipna=False)

# %%
# Save data to JSON file

print('Saving results...')
out_fpath = summary_stats_dir / 'summary_stats.json'
out_data = {
    # Priming accuracy
    'priming_acc_mean': float(priming_acc_mean),
    'priming_acc_median': float(priming_acc_median),
    'priming_acc_max': float(priming_acc_max),
    # Decoding accuracy
    'decode_acc_dom_mean': float(decode_acc_dom_mean),
    'decode_acc_dom_median': float(decode_acc_dom_median),
    'decode_acc_dom_max': float(decode_acc_dom_max),
    'decode_acc_sup_mean': float(decode_acc_sup_mean),
    'decode_acc_sup_median': float(decode_acc_sup_median),
    'decode_acc_sup_max': float(decode_acc_sup_max),
    # State log-likelihood
    'loglik_binoc_mean': float(loglik_binoc_mean),
    'loglik_binoc_median': float(loglik_binoc_median),
    'loglik_binoc_max': float(loglik_binoc_max),
    'loglik_mix_binoc_mean': float(loglik_mix_binoc_mean),
    'loglik_mix_binoc_median': float(loglik_mix_binoc_median),
    'loglik_mix_binoc_max': float(loglik_mix_binoc_max),
    # Probe coherence
    #     'probe_coh_prime_mean': float(probe_coh_prime_mean),
    #     'probe_coh_prime_median': float(probe_coh_prime_median),
    #     'probe_coh_prime_max': float(probe_coh_prime_max),
    #     'probe_coh_binoc_mean': float(probe_coh_binoc_mean),
    #     'probe_coh_binoc_median': float(probe_coh_binoc_median),
    #     'probe_coh_binoc_max': float(probe_coh_binoc_max),
}
with open(out_fpath, 'w') as f:
    json.dump(out_data, f)
print('Done.')

# %%
