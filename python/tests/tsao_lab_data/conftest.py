"""Pytest configuration and shared fixtures for tsao_lab_data tests."""

import tempfile
from pathlib import Path
from datetime import datetime

import pytest
import numpy as np
import h5py

from tsao_lab_data.session import Session
from tsao_lab_data.paradigm import (
    FOBParadigm,
    FSMParadigm,
    FSOParadigm,
)


# Fixture for temporary directory
@pytest.fixture
def temp_dir():
    """Create a temporary directory for test files."""
    with tempfile.TemporaryDirectory() as tmpdir:
        yield Path(tmpdir)


# Fixture for sample Session data
@pytest.fixture
def sample_session_data():
    """Create minimal valid Session data for testing."""
    n_units = 5
    n_probes = 2
    nt_waveform = 82

    data = {
        'session_name': '210803_133520_Alfie',
        'session_index': 5,
        'animal': 'Alfie',
        'timestamp': datetime(2021, 8, 3, 13, 35, 20),
        'acquisition_software': 'OpenEphys',
        'n_probes': n_probes,
        'n_units': n_units,
        'regions': ('ML', 'AM'),
        'layer_direction': (1, -1),
        'unit_id': np.array([0, 1, 2, 3, 4], dtype=np.int32),
        'unit_channel': np.array([10, 15, 20, 25, 30], dtype=np.int32),
        'unit_probe': np.array([1, 1, 2, 2, 2], dtype=np.int32),
        'unit_quality': np.array([0.8, 0.9, 0.7, 0.85, 0.75], dtype=np.float64),
        'unit_waveform_uv': np.random.randn(nt_waveform, n_units),
        'unit_waveform_time': np.linspace(-1, 1, nt_waveform),
        'unit_waveform_norm_shift': np.random.randn(nt_waveform, n_units),
        'paradigms': {},
    }
    return data


# Fixture for sample FOB Paradigm data
@pytest.fixture
def sample_fob_paradigm_data():
    """Create minimal valid FOB Paradigm data for testing."""
    n_trials = 10
    n_time = 1000
    n_units = 5

    data = {
        'n_trials': n_trials,
        'n_time': n_time,
        'stimulus_files': ['stim_0.png', 'stim_1.png', 'stim_2.png'],
        'stimulus_index_valid': np.array([0, 1, 2, 0, 1, 2, 0, 1, 2, 0], dtype=np.int32),
        'timecourse_all_units': np.random.randint(0, 5, size=(n_time, n_units), dtype=np.int32),
        'on_duration': 300,
        'off_duration': 200,
        'on_durations': np.full(n_trials, 300, dtype=np.int32),
        'off_durations': np.full(n_trials, 200, dtype=np.int32),
        'trial_durations': np.full(n_trials, 100, dtype=np.int32),
        'timecourse_on_times': np.arange(0, n_trials * 100, 100, dtype=np.int32),
        'timecourse_off_times': np.arange(50, n_trials * 100 + 50, 100, dtype=np.int32),
        'timecourse_on_times_ks': np.arange(0, n_trials * 0.1, 0.1, dtype=np.float64),
        'eyex_timecourse': np.random.randn(n_time),
        'eyey_timecourse': np.random.randn(n_time),
    }
    return data


# Fixture for sample FSMS Paradigm data
@pytest.fixture
def sample_fsms_paradigm_data(sample_fob_paradigm_data):
    """Create minimal valid FSMS Paradigm data for testing."""
    n_trials = sample_fob_paradigm_data['n_trials']
    n_units = 5
    n_stimuli = 3

    data = sample_fob_paradigm_data.copy()
    data['trial_is_priming'] = np.array([1, 0, 0, 1, 0, 0, 1, 0, 0, 0], dtype=np.int32)
    data['trial_is_binocular'] = np.array([0, 1, 0, 0, 1, 0, 0, 1, 0, 0], dtype=np.int32)
    data['trial_is_transparent'] = np.array([0, 0, 0, 0, 0, 0, 0, 0, 0, 0], dtype=np.int32)
    data['trial_is_unambiguous'] = np.array([1, 0, 0, 1, 0, 0, 1, 0, 0, 0], dtype=np.int32)
    data['trial_is_gray'] = np.array([0, 0, 1, 0, 0, 1, 0, 0, 1, 1], dtype=np.int32)
    data['trial_dominant_image_index'] = np.array([0, 1, -1, 0, 2, -1, 1, 0, -1, -1], dtype=np.int32)
    data['trial_suppressed_image_index'] = np.array([-1, 2, -1, -1, 0, -1, -1, 1, -1, -1], dtype=np.int32)
    data['priming_stimulus_is_red'] = np.array([1, 0, 1], dtype=np.int32)
    data['priming_stimulus_is_cyan'] = np.array([0, 1, 0], dtype=np.int32)
    return data


# Fixture to create FOB paradigm
@pytest.fixture
def fob_paradigm(sample_fob_paradigm_data):
    """Create a valid FOB Paradigm instance."""
    return FOBParadigm(**sample_fob_paradigm_data)


# Fixture to create FSMS paradigm
@pytest.fixture
def fsms_paradigm(sample_fsms_paradigm_data):
    """Create a valid FSMS Paradigm instance."""
    return FSMParadigm(**sample_fsms_paradigm_data)


# Fixture to create a Session with paradigms
@pytest.fixture
def sample_session(sample_session_data, fob_paradigm):
    """Create a valid Session instance with a paradigm."""
    data = sample_session_data.copy()
    data['paradigms'] = {'fob': fob_paradigm}
    return Session(**data)


# Fixture to create HDF5 file with Session data
@pytest.fixture
def sample_h5_file(temp_dir, sample_session):
    """Create a sample HDF5 file with Session data."""
    fpath = temp_dir / 'test_session.h5'
    sample_session.to_h5(fpath)
    return fpath


# Fixture to create HDF5 file with minimal paradigm
@pytest.fixture
def minimal_h5_paradigm_group(temp_dir, fob_paradigm):
    """Create an HDF5 file with a single paradigm group for testing."""
    fpath = temp_dir / 'test_paradigm.h5'
    with h5py.File(fpath, 'w') as f:
        g = f.create_group('test_paradigm')
        fob_paradigm.to_h5(g)
    return fpath


# Fixture for empty arrays to test edge cases
@pytest.fixture
def empty_arrays():
    """Create empty numpy arrays for edge case testing."""
    return {
        'empty_int': np.array([], dtype=np.int32),
        'empty_float': np.array([], dtype=np.float64),
        'empty_2d': np.empty((0, 0), dtype=np.int32),
    }
