# %%
# Cross-validated state-specific decoding accuracy on FSO sessions

# %%
# Imports

from pathlib import Path
import argparse
import yaml
import joblib
import json
import numpy as np
from sklearn.model_selection import KFold
from sklearn.svm import LinearSVC

from percept_hmm.flash_suppression import iter_aligned
from percept_hmm.pipelines.dataio import rec_fname

# %%
# Helper methods

def get_trial_decoding_data(fs_data: dict[tuple[int, int], list[dict]], pred_states: dict[tuple[int, int], list[dict]]) -> list[dict]:
    """Get list of trial information dicts."""

    trial_data = []

    for r, c in fs_data.keys():

        for trial, states in iter_aligned(fs_data[(r, c)], pred_states[(r, c)]):

            # Basic trial data
            trial_index = trial['trial_index']
            spikes = trial['spikes']
            trial_type = trial['trial_type']

            # Indices of dominant and suppressed stimuli
            if trial['stim_dom'] == 0: # red stimulus is dominant
                s_dom = r
                s_sup = c
            elif trial['stim_dom'] == 1: # cyan stimulus is dominant
                s_dom = c
                s_sup = r
            else:
                raise ValueError("'stim_dom' should only be 0 or 1.")

            # Rivalry states for trial
            riv_states = states['rivalry_states']

            trial_data.append({
                'trial_index': trial_index,
                'trial_type': trial_type,
                's_dom': s_dom,
                's_sup': s_sup,
                'spikes': spikes,
                'riv_states': riv_states,
            })

    return trial_data

def get_design(trial_data: list[dict], trial_type: str, win_start: int, win_stop: int, sfreq: int) -> dict:
    """Get matrix of input vectors and labels for SVM decoding for particular trial type."""

    assert len(trial_data) > 0
    assert trial_type in ['priming', 'binocular', 'transparent', 'unambiguous']

    # Get response vectors and stimulus labels for all priming trials
    r_trial = []
    s_trial_dom = []
    s_trial_sup = []
    for x in trial_data:
        if x['trial_type'] == trial_type:

            # Compute average response vector for trial
            spikes_win = x['spikes'][win_start:win_stop, :]
            r = np.mean(spikes_win, axis=0) * sfreq

            # Add average response vector and stimulus label to lists
            r_trial.append(r)
            s_trial_dom.append(x['s_dom'])
            s_trial_sup.append(x['s_sup'])

    if len(r_trial) == 0:
        raise ValueError('No trials with matching type')

    # Design matrix
    return {
        'X': np.stack(r_trial, axis=0),
        'y_dom': np.array(s_trial_dom),
        'y_sup': np.array(s_trial_sup)
    }

def get_design_states(trial_data: list[dict], trial_type: str, win_start: int, win_stop: int, min_win_frac: float, sfreq: int) -> dict:
    """Get matrix of state-separated input vectors and labels for SVM decoding."""

    assert len(trial_data) > 0
    assert trial_type in ['priming', 'binocular', 'transparent', 'unambiguous']

    # Compute minimum size for window
    min_win_len = int((win_stop - win_start) * min_win_frac)

    # Get responses vectors
    r_trial_dom = []
    r_trial_sup = []
    r_trial_all = []
    s_trial_dom = []
    s_trial_sup = []
    for x in trial_data:
        if x['trial_type'] == trial_type:

            # Extract data from window
            spikes_win = x['spikes'][win_start:win_stop, :]
            states_win = x['riv_states'][win_start:win_stop]

            # Get spikes from dominant state time points and suppressed state time points
            spikes_dom = spikes_win[states_win == 0, :]
            spikes_sup = spikes_win[states_win == 1, :]

            # If there aren't enough time points in either dominant or suppressed state, skip trial
            if spikes_dom.shape[0] < min_win_len or spikes_sup.shape[0] < min_win_len:
                continue

            # Compute response vectors
            r_dom = np.mean(spikes_dom, axis=0) * sfreq
            r_sup = np.mean(spikes_sup, axis=0) * sfreq
            r_all = np.mean(spikes_win, axis=0) * sfreq

            # Stimulus labels
            s_dom = x['s_dom']
            s_sup = x['s_sup']

            # Add average response vectors and stimulus labels to lists
            r_trial_dom.append(r_dom)
            r_trial_sup.append(r_sup)
            r_trial_all.append(r_all)
            s_trial_dom.append(s_dom)
            s_trial_sup.append(s_sup)

    if len(r_trial_dom) == 0:
        raise ValueError('No trials with matching type')

    return {
        'X_dom': np.stack(r_trial_dom, axis=0),
        'X_sup': np.stack(r_trial_sup, axis=0),
        'X_all': np.stack(r_trial_all, axis=0),
        'y_dom': np.array(s_trial_dom),
        'y_sup': np.array(s_trial_sup),
    }

def acc_multiclass(y_pred: np.ndarray, y_true: np.ndarray) -> float:
    """Multi-class decoder accuracy."""

    n_pts = len(y_true)
    n_correct = np.count_nonzero(y_pred == y_true).item()

    return n_correct / n_pts

def svm_accuracy_cv(X: np.ndarray, y: np.ndarray, n_folds_cv: int, max_iter: int, rng_seed: int):
    """Compute cross-validated SVM decoder accuracy."""

    acc_vals = []
    kf = KFold(n_splits=n_folds_cv, shuffle=True, random_state=rng_seed)
    for train_idx, test_idx in kf.split(X):

        # Training data for fold
        X_train = X[train_idx, :]
        y_train = y[train_idx]

        # Test data for fold
        X_test = X[test_idx, :]
        y_test = y[test_idx]

        # Fit model
        lin_clf = LinearSVC(multi_class='ovr', max_iter=max_iter)
        lin_clf.fit(X_train, y_train)

        # Predict and evaluate on test data
        y_test_pred = lin_clf.predict(X_test)
        acc_vals.append(acc_multiclass(y_test_pred, y_test))

    return acc_vals


# %%
# Parse arguments

# Create parser
parser = argparse.ArgumentParser(description='Fit fixed-rate HMM and predict states')
parser.add_argument('--session', type=str, required=True)
parser.add_argument('--paradigm', type=str, required=True)
parser.add_argument('--probes', type=str, required=True)
parser.add_argument('-p', '--params', type=str, default='params.yaml')

# Set args manually (notebook mode)
#%cd 'data/fixed_hmm_fs'
#args = parser.parse_args(['--session', 's133', '--paradigm', 'fsor', '--probes', 'p12'])

# Parse from command line (script mode)
args = parser.parse_args()

# %%
# Parameters

SFREQ = 1000

# Load parameters
with open(args.params, 'r') as f:
    params = yaml.safe_load(f)

# Directory paths
extract_data_dir = Path(params['paths']['extract_data_dir'])
pred_all_units_dir = Path(params['paths']['pred_all_units_dir'])
fso_decoding_dir = Path(params['paths']['fso_decoding_dir'])

# Parameters for fitting HMM
win_start = params['fso_decoding']['win_start']
win_stop = params['fso_decoding']['win_stop']
max_iter = params['fso_decoding']['max_iter']
n_folds_cv = params['fso_decoding']['n_folds_cv']
rng_seed_cv = params['fso_decoding']['rng_seed_cv']
min_win_frac = params['fso_decoding']['min_win_frac']

# %%
# Load data

fname = rec_fname(args.session, args.paradigm, args.probes, '.joblib')

# Extracted data
ext_fpath = extract_data_dir / fname
ext_data = joblib.load(ext_fpath)
fs_data = ext_data['fs_data']

# Estimated states
pred_all_units_fpath = pred_all_units_dir / fname
pred_all_units_data = joblib.load(pred_all_units_fpath)
pred_states = pred_all_units_data['pred_states']

# %%
# Index data by trial

trial_data = get_trial_decoding_data(fs_data, pred_states)

# %%
# Decode priming stimulus on priming trials

# Get design matrix
dsn = get_design(trial_data, 'priming', win_start, win_stop, SFREQ)

# Cross-validated linear decoding on priming stimuli
acc_vals = svm_accuracy_cv(dsn['X'], dsn['y_dom'], n_folds_cv, max_iter, rng_seed_cv)
acc_cv_prime = float(np.mean(acc_vals))
print(f'acc_cv_prime: {acc_cv_prime:.4f}')

# %%
# Decode dominant and suppressed stimului from binocular trials

# Get design matrix
dsn = get_design(trial_data, 'binocular', win_start, win_stop, SFREQ)

# SVM decoding: Predict dominant stimulus from binocular trials
acc_vals = svm_accuracy_cv(dsn['X'], dsn['y_dom'], n_folds_cv, max_iter, rng_seed_cv)
acc_cv_binoc_dom = float(np.mean(acc_vals))
print(f'acc_cv_binoc_dom: {acc_cv_binoc_dom:.4f}')

# SVM decoding: Predict suppressed stimulus from binocular trials
acc_vals = svm_accuracy_cv(dsn['X'], dsn['y_sup'], n_folds_cv, max_iter, rng_seed_cv)
acc_cv_binoc_sup = float(np.mean(acc_vals))
print(f'acc_cv_binoc_sup: {acc_cv_binoc_sup:.4f}')

# %%
# Train decoder on priming data and evaluate it on state-separated binocular trials

# Fit SVM classifier to priming data
dsn_prime = get_design(trial_data, 'priming', win_start, win_stop, SFREQ)
svm_prime = LinearSVC(multi_class='ovr', max_iter=max_iter)
svm_prime.fit(dsn_prime['X'], dsn_prime['y_dom'])

# Get design separated by states
dsn_state = get_design_states(trial_data, 'binocular', win_start, win_stop, min_win_frac, SFREQ)

# Print number of dropped trials
n_trials_orig = len([x for x in trial_data if x['trial_type'] == 'binocular'])
n_trials_final = int(dsn_state['X_all'].shape[0])
print(f'{n_trials_final}/{n_trials_orig} binocular trials used.')

# Predict dominant and suppressed stimuli from all time points
y_pred_all = svm_prime.predict(dsn_state['X_all'])
acc_all_dom = acc_multiclass(y_pred_all, dsn_state['y_dom'])
acc_all_sup = acc_multiclass(y_pred_all, dsn_state['y_sup'])
print(f'acc_all_dom: {acc_all_dom}')
print(f'acc_all_sup: {acc_all_sup}')

# Predict dominant and suppressed stimuli from time points labeled 'dominant'
y_pred_dom = svm_prime.predict(dsn_state['X_dom'])
acc_dom_dom = acc_multiclass(y_pred_dom, dsn_state['y_dom'])
acc_dom_sup = acc_multiclass(y_pred_dom, dsn_state['y_sup'])
print(f'acc_dom_dom: {acc_dom_dom}')
print(f'acc_dom_sup: {acc_dom_sup}')

# Predict dominant and suppressed stimuli from time points labeled 'suppressed'
y_pred_sup = svm_prime.predict(dsn_state['X_sup'])
acc_sup_sup = acc_multiclass(y_pred_sup, dsn_state['y_sup'])
acc_sup_dom = acc_multiclass(y_pred_sup, dsn_state['y_dom'])
print(f'acc_sup_sup: {acc_sup_sup}')
print(f'acc_sup_dom: {acc_sup_dom}')

# %%
# Save results

print('Saving results...')
out_fpath = fso_decoding_dir / rec_fname(args.session, args.paradigm, args.probes, '.json')
out_data = {
    'acc_cv_prime': acc_cv_prime,
    'acc_cv_binoc_dom': acc_cv_binoc_dom,
    'acc_cv_binoc_sup': acc_cv_binoc_sup,
    'acc_all_dom': acc_all_dom,
    'acc_all_sup': acc_all_sup,
    'acc_dom_dom': acc_dom_dom,
    'acc_dom_sup': acc_dom_sup,
    'acc_sup_sup': acc_sup_sup,
    'acc_sup_dom': acc_sup_dom,
    'n_trials_orig': n_trials_orig,
    'n_trials_final': n_trials_final,
}
with open(out_fpath, 'w') as f:
    json.dump(out_data, f)
print('Done.')

# %%
