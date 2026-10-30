# %%
# Summary of difference between one-state and two-state model likelihood

# %%
# Imports

import argparse
import json
from pathlib import Path

import pandas as pd
import yaml
from percept_hmm.pipelines.dataio import rec_fname
from scipy.io import savemat
from scipy.stats import ttest_1samp

# %%
# Parse arguments

# Create parser
parser = argparse.ArgumentParser(description='Summarize marginal log-likelihood difference')
parser.add_argument('-p', '--params', type=str, default='config/python_summaries.yaml')

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

# Directory to load marginal log-likelihood values from
marg_loglik_dir = Path(params['paths']['marg_loglik_dir'])

# Output directory
out_dir = Path(params['paths']['python_summaries_dir'])

# %%
# Load data

# Load recordings from list
with open(rec_list_fpath) as f:
    rec_list = yaml.safe_load(f)['rec_it']

# Load marginal log-likelihood values for each recording
rows = []
for rec in rec_list:
    fpath = marg_loglik_dir / rec_fname(rec['session'], rec['paradigm'], rec['probes'], '.json')
    with open(fpath, 'r') as f:
        data = json.load(f)
    rows.append({'rec': fpath.stem, **data})
df = pd.DataFrame(rows)

# Difference in marginal log-likelihood per unit (two-state - one-state)
df['diff_real'] = df['mll_2s'] - df['mll_1s']
print(df[['rec', 'diff_real']])

# %%
# Test whether two-state model outperforms one-state model

print(f'n = {len(df)} recordings')
print(f'Median diff (real): {df["diff_real"].median():.4f}')

# One-sided one-sample t-test: is mean of real difference greater than zero?
t_real, p_real = ttest_1samp(df['diff_real'], 0, alternative='greater')
print(f'Mean diff (real): {df["diff_real"].mean():.4f}')
print(f'One-sample t-test (real > 0): t({len(df) - 1}) = {t_real:.2f}, p = {p_real:.3g}')

# %%
# Save data

out_fpath = out_dir / 'marg_loglik.mat'

# Extract from DataFrame
rec = df['rec'].tolist()
mll_1s = df['mll_1s'].to_numpy()
mll_2s = df['mll_2s'].to_numpy()
diff_real = df['diff_real'].to_numpy()

# Package fields into dict and save to MAT file
out_data = {
    'rec': rec,
    'mll_1s': mll_1s,
    'mll_2s': mll_2s,
    'diff_real': diff_real,
}
savemat(out_fpath, out_data, do_compression=True)

