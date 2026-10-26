# %%
# Compute summary statistics for each session

# %%
# Imports

from pathlib import Path
import argparse
import math
import yaml
import json
import pandas as pd

from percept_hmm.pipelines.dataio import parse_rec_fname

# %%
# Helper methods


def load_files_df(data_dir: Path, fnames: list[str]):
    """Load data files into Pandas DataFrame indexed by recording identifiers"""

    # Load values from files into list of row entries
    rows = []
    for fname in fnames:
        # Load file
        with open(data_dir / fname, 'r') as f:
            data = json.load(f)

        # Parse recording identifiers from filename
        id_data = parse_rec_fname(fname)
        data['session'] = id_data['session']
        data['paradigm'] = id_data['paradigm']
        data['probes'] = id_data['probes']

        # Add ot list
        rows.append(data)

    # Create DataFrame from list
    df = pd.DataFrame(rows)

    # Sort DataFrame by recording identifiers
    rec_cols = ['session', 'paradigm', 'probes']
    df = df[rec_cols + [c for c in df.columns if c not in rec_cols]]
    df = df.sort_values(by=rec_cols).reset_index(drop=True)

    # Add column for number of probes
    df['n_probes'] = df['probes'].str.len() - 1

    return df


def clean_float_dict_json(data: dict) -> dict:
    """Convert NaN floats to None so the output is valid JSON."""

    return {k: (None if math.isnan(v) else float(v)) for k, v in data.items()}


# %%
# Parse arguments

# Create parser
parser = argparse.ArgumentParser(description='Compute summary statistics for each session')
parser.add_argument('-p', '--params', type=str, default='params.yaml')

# Set args manually (notebook mode)
# %cd 'data/fixed_hmm_fs'
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
unit_subset_coherence_dir = Path(params['paths']['unit_subset_coherence_dir'])
probe_coherence_dir = Path(params['paths']['probe_coherence_dir'])
dwell_time_dir = Path(params['paths']['dwell_time_dir'])
states_loglik_dir = Path(params['paths']['states_loglik_dir'])
summary_stats_dir = Path(params['paths']['summary_stats_dir'])

# %%
# Get list of data file names

# Look in stats directory and get names of all JSON files
fnames = sorted([fpath.name for fpath in stats_dir.glob('*.json')])

# %%
# Compute summary statistics for stats data

# Load files from stats directory
stats_df = load_files_df(stats_dir, fnames)

# Priming accuracy (fraction of time points in "dominant" state during priming trials)
priming_acc_mean = float(stats_df['frac_dom_prime'].mean())
priming_acc_std = float(stats_df['frac_dom_prime'].std())

# %%
# Compute summary statistics for FSO decoding

# FSO decoding uses different set of recordings
fnames_fso = sorted([fpath.name for fpath in fso_decoding_dir.glob('*.json')])

# Load files from FSO decoding directory
dec_df = load_files_df(fso_decoding_dir, fnames_fso)

# Accuracy of priming decoder predicting dominant stimulus using state 1
decode_acc_dom_mean = float(dec_df['acc_dom_dom'].mean())
decode_acc_dom_std = float(dec_df['acc_dom_dom'].std())

# Accuracy of priming decoder predicting suppressed stimulus using state 2
decode_acc_sup_mean = float(dec_df['acc_sup_sup'].mean())
decode_acc_sup_std = float(dec_df['acc_sup_sup'].std())

# %%
# Compute summary statistics for unit subset coherence

# Load files from unit subset coherence directory
sub_coh_df = load_files_df(unit_subset_coherence_dir, fnames)

# Unit subset coherence for priming trials
subset_coh_prime_mean = float(sub_coh_df['coh_mean_prime'].mean())
subset_coh_prime_std = float(sub_coh_df['coh_mean_prime'].std())

# Unit subset coherence for binocular trials
subset_coh_binoc_mean = float(sub_coh_df['coh_mean_binoc'].mean())
subset_coh_binoc_std = float(sub_coh_df['coh_mean_binoc'].std())

# %%
# Compute summary statistics for probe coherence

# Probe coherence uses different set of recordings
fnames_pc = sorted([fpath.name for fpath in probe_coherence_dir.glob('*.json')])

# Load files from probe coherence directory
probe_coh_df = load_files_df(probe_coherence_dir, fnames_pc)

# Probe coherence for priming trials
probe_coh_prime_mean = float(probe_coh_df['coh_12_prime'].mean())
probe_coh_prime_std = float(probe_coh_df['coh_12_prime'].std())

# Probe coherence for binocular trials
probe_coh_binoc_mean = float(probe_coh_df['coh_12_binoc'].mean())
probe_coh_binoc_std = float(probe_coh_df['coh_12_binoc'].std())

# %%
# Compute summary statistics for dwell time

# Load files from dwell time directory
dwell_df = load_files_df(dwell_time_dir, fnames)

# Priming trials dwell time for states 0 and 1
dt_prime_0_mean = float(dwell_df['dt_mean_prime_0'].mean())
dt_prime_0_std = float(dwell_df['dt_mean_prime_0'].std())
dt_prime_1_mean = float(dwell_df['dt_mean_prime_1'].mean())
dt_prime_1_std = float(dwell_df['dt_mean_prime_1'].std())

# Binocular trials dwell time for states 0 and 1
dt_binoc_0_mean = float(dwell_df['dt_mean_binoc_0'].mean())
dt_binoc_0_std = float(dwell_df['dt_mean_binoc_0'].std())
dt_binoc_1_mean = float(dwell_df['dt_mean_binoc_1'].mean())
dt_binoc_1_std = float(dwell_df['dt_mean_binoc_1'].std())

# %%
# Compute summary statistics for state sequence log-likelihood

# Load files from states log-likelihood directory
loglik_df = load_files_df(states_loglik_dir, fnames)

# Log-likelihood of state response for priming trials
loglik_prime_mean = float(loglik_df['loglik_prime'].mean())
loglik_prime_std = float(loglik_df['loglik_prime'].std())

# Log-likelihood of state response for binocular trials
loglik_binoc_mean = float(loglik_df['loglik_binoc'].mean())
loglik_binoc_std = float(loglik_df['loglik_binoc'].std())

# Log-likelihood of static mixed response for priming trials
loglik_mix_prime_mean = float(loglik_df['loglik_mix_prime'].mean())
loglik_mix_prime_std = float(loglik_df['loglik_mix_prime'].std())

# Log-likelihood of static mixed response for binocular trials
loglik_mix_binoc_mean = float(loglik_df['loglik_mix_binoc'].mean())
loglik_mix_binoc_std = float(loglik_df['loglik_mix_binoc'].std())

# %%
# Save data to JSON file

print('Saving results...')
out_fpath = summary_stats_dir / 'summary_stats.json'
out_data = clean_float_dict_json({
    # Priming accuracy
    'priming_acc_mean': priming_acc_mean,
    'priming_acc_std': priming_acc_std,
    # Decoding accuracy
    'decode_acc_dom_mean': decode_acc_dom_mean,
    'decode_acc_dom_std': decode_acc_dom_std,
    'decode_acc_sup_mean': decode_acc_sup_mean,
    'decode_acc_sup_std': decode_acc_sup_std,
    # Unit subset coherence
    'subset_coh_prime_mean': subset_coh_prime_mean,
    'subset_coh_prime_std': subset_coh_prime_std,
    'subset_coh_binoc_mean': subset_coh_binoc_mean,
    'subset_coh_binoc_std': subset_coh_binoc_std,
    # Probe coherence
    'probe_coh_prime_mean': probe_coh_prime_mean,
    'probe_coh_prime_std': probe_coh_prime_std,
    'probe_coh_binoc_mean': probe_coh_binoc_mean,
    'probe_coh_binoc_std': probe_coh_binoc_std,
    # Dwell time
    'dt_prime_0_mean': dt_prime_0_mean,
    'dt_prime_0_std': dt_prime_0_std,
    'dt_prime_1_mean': dt_prime_1_mean,
    'dt_prime_1_std': dt_prime_1_std,
    'dt_binoc_0_mean': dt_binoc_0_mean,
    'dt_binoc_0_std': dt_binoc_0_std,
    'dt_binoc_1_mean': dt_binoc_1_mean,
    'dt_binoc_1_std': dt_binoc_1_std,
    # State sequence log-likelihood
    'loglik_prime_mean': loglik_prime_mean,
    'loglik_prime_std': loglik_prime_std,
    'loglik_binoc_mean': loglik_binoc_mean,
    'loglik_binoc_std': loglik_binoc_std,
    'loglik_mix_prime_mean': loglik_mix_prime_mean,
    'loglik_mix_prime_std': loglik_mix_prime_std,
    'loglik_mix_binoc_mean': loglik_mix_binoc_mean,
    'loglik_mix_binoc_std': loglik_mix_binoc_std,
})
with open(out_fpath, 'w') as f:
    json.dump(out_data, f)
print('Done.')

# %%
