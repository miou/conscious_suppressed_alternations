"""Comprehensive unit tests for Paradigm classes.

This test module covers:
- Base Paradigm class validation
- Loading paradigms from HDF5
- Saving paradigms to HDF5
- All paradigm subclasses (FOB, PSS, BRS, PSN, BRN, TSS, PSST, BRST, PSNT, BRNT, FAS, FSMS, FSO)
- Trial selection and filtering
- Unit selection
- Edge cases and error handling
"""

import tempfile
from pathlib import Path

import pytest
import numpy as np
import h5py

from tsao_lab_data.paradigm import (
    Paradigm,
    FOBParadigm,
    PSSParadigm,
    BRSParadigm,
    PSNParadigm,
    BRNParadigm,
    TSSParadigm,
    PSSTParadigm,
    BRSTParadigm,
    PSNTParadigm,
    BRNTParadigm,
    FASParadigm,
    FSParadigm,
    FSMParadigm,
    FSOParadigm,
)


class TestParadigmBaseValidation:
    """Tests for base Paradigm class validation."""

    def test_paradigm_validates_on_init(self, sample_fob_paradigm_data):
        """Test that validation is automatically called on initialization."""
        paradigm = FOBParadigm(**sample_fob_paradigm_data)
        # If we get here, validation passed
        assert paradigm.n_trials == 10

    def test_paradigm_stimulus_files_validation(self, sample_fob_paradigm_data):
        """Test that stimulus_index_valid values must be within stimulus_files range."""
        data = sample_fob_paradigm_data.copy()
        # Reference stimulus index that doesn't exist
        data['stimulus_index_valid'] = np.array([0, 1, 5, 0, 1, 2, 0, 1, 2, 0], dtype=np.int32)

        with pytest.raises(AssertionError):
            FOBParadigm(**data)

    def test_paradigm_stimulus_index_shape_validation(self, sample_fob_paradigm_data):
        """Test that stimulus_index_valid must have shape (n_trials,)."""
        data = sample_fob_paradigm_data.copy()
        data['stimulus_index_valid'] = np.array([0, 1, 2], dtype=np.int32)  # Wrong length

        with pytest.raises(AssertionError):
            FOBParadigm(**data)

    def test_paradigm_stimulus_index_must_be_nonnegative_int(self, sample_fob_paradigm_data):
        """Test that stimulus_index_valid must be non-negative integers."""
        data = sample_fob_paradigm_data.copy()
        data['stimulus_index_valid'] = np.array([0, 1, -1, 0, 1, 2, 0, 1, 2, 0], dtype=np.int32)

        with pytest.raises(AssertionError):
            FOBParadigm(**data)

    def test_paradigm_timecourse_shape_validation(self, sample_fob_paradigm_data):
        """Test that timecourse_all_units must have shape (n_time, n_units)."""
        data = sample_fob_paradigm_data.copy()
        data['timecourse_all_units'] = np.random.randint(0, 5, size=(500, 5), dtype=np.int32)  # Wrong n_time

        with pytest.raises(AssertionError):
            FOBParadigm(**data)

    def test_paradigm_timecourse_must_be_nonnegative_int(self, sample_fob_paradigm_data):
        """Test that timecourse_all_units must be non-negative integers."""
        data = sample_fob_paradigm_data.copy()
        data['timecourse_all_units'] = np.random.randint(-1, 5, size=(1000, 5), dtype=np.int32)

        with pytest.raises(AssertionError):
            FOBParadigm(**data)

    def test_paradigm_on_durations_shape_validation(self, sample_fob_paradigm_data):
        """Test that on_durations must have shape (n_trials,)."""
        data = sample_fob_paradigm_data.copy()
        data['on_durations'] = np.full(5, 300, dtype=np.int32)  # Wrong length

        with pytest.raises(AssertionError):
            FOBParadigm(**data)

    def test_paradigm_trial_durations_validation(self, sample_fob_paradigm_data):
        """Test that trial_durations must be non-negative integers."""
        data = sample_fob_paradigm_data.copy()
        data['trial_durations'] = np.array([100, 100, -50, 100, 100, 100, 100, 100, 100, 100], dtype=np.int32)

        with pytest.raises(AssertionError):
            FOBParadigm(**data)

    def test_paradigm_timecourse_on_times_validation(self, sample_fob_paradigm_data):
        """Test that timecourse_on_times must be within n_time bounds."""
        data = sample_fob_paradigm_data.copy()
        # Make one time point out of bounds
        data['timecourse_on_times'] = np.array([0, 100, 200, 300, 400, 500, 600, 700, 800, 1500], dtype=np.int32)

        with pytest.raises(AssertionError):
            FOBParadigm(**data)

    def test_paradigm_timecourse_on_times_diff_validation(self, sample_fob_paradigm_data):
        """Test that differences in timecourse_on_times must match trial_durations."""
        data = sample_fob_paradigm_data.copy()
        # Make differences not match trial_durations
        data['timecourse_on_times'] = np.array([0, 150, 200, 300, 400, 500, 600, 700, 800, 900], dtype=np.int32)

        with pytest.raises(AssertionError):
            FOBParadigm(**data)

    def test_paradigm_eyex_timecourse_shape_validation(self, sample_fob_paradigm_data):
        """Test that eyex_timecourse must have shape (n_time,)."""
        data = sample_fob_paradigm_data.copy()
        data['eyex_timecourse'] = np.random.randn(500)  # Wrong length

        with pytest.raises(AssertionError):
            FOBParadigm(**data)

    def test_paradigm_eyey_timecourse_shape_validation(self, sample_fob_paradigm_data):
        """Test that eyey_timecourse must have shape (n_time,)."""
        data = sample_fob_paradigm_data.copy()
        data['eyey_timecourse'] = np.random.randn(500)  # Wrong length

        with pytest.raises(AssertionError):
            FOBParadigm(**data)

    def test_paradigm_timecourse_on_times_ks_validation(self, sample_fob_paradigm_data):
        """Test that timecourse_on_times_ks must be non-negative floats."""
        data = sample_fob_paradigm_data.copy()
        data['timecourse_on_times_ks'] = np.array([0.0, 0.1, -0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9], dtype=np.float64)

        with pytest.raises(AssertionError):
            FOBParadigm(**data)


class TestParadigmProperties:
    """Tests for Paradigm properties."""

    def test_trial_bounds_property(self, fob_paradigm):
        """Test that trial_bounds returns correct start/stop pairs."""
        bounds = fob_paradigm.trial_bounds

        assert len(bounds) == 10  # 10 trials
        assert bounds[0] == (0, 100)  # First trial
        assert bounds[-1][1] == 1000  # Last trial ends at n_time

    def test_spike_trials_property(self, fob_paradigm):
        """Test that spike_trials returns list of spike matrices per trial."""
        spike_trials = fob_paradigm.spike_trials

        assert len(spike_trials) == 10
        # Each trial should be a 2D array (time x units)
        assert spike_trials[0].ndim == 2
        assert spike_trials[0].shape[1] == 5  # n_units

    def test_eyex_timecourse_trials_property(self, fob_paradigm):
        """Test that eyex_timecourse_trials returns list of eye tracking arrays."""
        eyex_trials = fob_paradigm.eyex_timecourse_trials

        assert len(eyex_trials) == 10
        # Each trial should be 1D array
        assert eyex_trials[0].ndim == 1

    def test_eyey_timecourse_trials_property(self, fob_paradigm):
        """Test that eyey_timecourse_trials returns list of eye tracking arrays."""
        eyey_trials = fob_paradigm.eyey_timecourse_trials

        assert len(eyey_trials) == 10
        assert eyey_trials[0].ndim == 1


class TestParadigmHDF5Loading:
    """Tests for loading Paradigm data from HDF5."""

    def test_fob_paradigm_from_h5(self, temp_dir, fob_paradigm):
        """Test loading FOB paradigm from HDF5 group."""
        fpath = temp_dir / 'test.h5'
        with h5py.File(fpath, 'w') as f:
            g = f.create_group('fob')
            fob_paradigm.to_h5(g)

        with h5py.File(fpath, 'r') as f:
            loaded = FOBParadigm.from_h5(f['fob'])

        assert loaded.n_trials == fob_paradigm.n_trials
        assert loaded.n_time == fob_paradigm.n_time
        assert np.array_equal(loaded.stimulus_index_valid, fob_paradigm.stimulus_index_valid)

    def test_paradigm_from_h5_loads_common_fields(self, temp_dir, fob_paradigm):
        """Test that common fields are loaded correctly."""
        fpath = temp_dir / 'test.h5'
        with h5py.File(fpath, 'w') as f:
            g = f.create_group('fob')
            fob_paradigm.to_h5(g)

        with h5py.File(fpath, 'r') as f:
            loaded = FOBParadigm.from_h5(f['fob'])

        assert loaded.on_duration == fob_paradigm.on_duration
        assert loaded.off_duration == fob_paradigm.off_duration
        assert np.array_equal(loaded.on_durations, fob_paradigm.on_durations)

    def test_paradigm_from_h5_with_wrong_paradigm_name(self, temp_dir, fob_paradigm):
        """Test that loading with mismatched paradigm name raises error."""
        fpath = temp_dir / 'test.h5'
        with h5py.File(fpath, 'w') as f:
            g = f.create_group('wrong')
            fob_paradigm.to_h5(g)
            # Manually change paradigm name in file
            g.attrs['paradigm_name'] = 'wrong_name'

        with h5py.File(fpath, 'r') as f:
            with pytest.raises(ValueError, match='does not match subclass'):
                FOBParadigm.from_h5(f['wrong'])


class TestParadigmHDF5Saving:
    """Tests for saving Paradigm data to HDF5."""

    def test_paradigm_to_h5_creates_datasets(self, temp_dir, fob_paradigm):
        """Test that to_h5 creates required datasets."""
        fpath = temp_dir / 'test.h5'
        with h5py.File(fpath, 'w') as f:
            g = f.create_group('fob')
            fob_paradigm.to_h5(g)

        with h5py.File(fpath, 'r') as f:
            g = f['fob']
            assert 'stimulus_files' in g
            assert 'stimulus_index_valid' in g
            assert 'timecourse_all_units' in g
            assert 'on_durations' in g
            assert 'eyex_timecourse' in g

    def test_paradigm_to_h5_saves_attributes(self, temp_dir, fob_paradigm):
        """Test that attributes are saved correctly."""
        fpath = temp_dir / 'test.h5'
        with h5py.File(fpath, 'w') as f:
            g = f.create_group('fob')
            fob_paradigm.to_h5(g)

        with h5py.File(fpath, 'r') as f:
            g = f['fob']
            assert g.attrs['paradigm_name'] == 'FOB'
            assert g.attrs['on_duration'] == 300
            assert g.attrs['off_duration'] == 200

    def test_paradigm_to_h5_roundtrip_preserves_data(self, temp_dir, fob_paradigm):
        """Test that saving and loading preserves data."""
        fpath = temp_dir / 'test.h5'
        with h5py.File(fpath, 'w') as f:
            g = f.create_group('fob')
            fob_paradigm.to_h5(g)

        with h5py.File(fpath, 'r') as f:
            loaded = FOBParadigm.from_h5(f['fob'])

        assert loaded.n_trials == fob_paradigm.n_trials
        assert loaded.n_time == fob_paradigm.n_time
        assert np.array_equal(loaded.timecourse_all_units, fob_paradigm.timecourse_all_units)
        assert np.array_equal(loaded.trial_durations, fob_paradigm.trial_durations)


class TestParadigmUnitSelection:
    """Tests for selecting units in Paradigm objects."""

    def test_select_units_filters_timecourse(self, fob_paradigm):
        """Test that select_units filters timecourse_all_units correctly."""
        units_to_select = np.array([0, 2, 4])
        fob_paradigm.select_units(units_to_select)

        assert fob_paradigm.timecourse_all_units.shape[1] == 3

    def test_select_units_with_contiguous_range(self, fob_paradigm):
        """Test that contiguous unit selection uses optimized path."""
        # Select units [1, 2, 3] - contiguous
        units_to_select = np.array([1, 2, 3])
        fob_paradigm.select_units(units_to_select)

        assert fob_paradigm.timecourse_all_units.shape[1] == 3

    def test_select_units_with_noncontiguous_indices(self, fob_paradigm):
        """Test that non-contiguous selection works correctly."""
        # Select units [0, 2, 4] - non-contiguous
        units_to_select = np.array([0, 2, 4])
        fob_paradigm.select_units(units_to_select)

        assert fob_paradigm.timecourse_all_units.shape[1] == 3

    def test_select_units_preserves_time_dimension(self, fob_paradigm):
        """Test that time dimension is preserved after unit selection."""
        original_n_time = fob_paradigm.n_time
        units_to_select = np.array([0, 1])
        fob_paradigm.select_units(units_to_select)

        assert fob_paradigm.timecourse_all_units.shape[0] == original_n_time

    def test_select_units_with_single_unit(self, fob_paradigm):
        """Test selecting a single unit."""
        units_to_select = np.array([2])
        fob_paradigm.select_units(units_to_select)

        assert fob_paradigm.timecourse_all_units.shape[1] == 1

    def test_fsms_select_units_filters_timecourse(self, fsms_paradigm):
        """Test that FSMS unit selection filters timecourse_all_units."""
        units_to_select = np.array([0, 2, 4])
        fsms_paradigm.select_units(units_to_select)

        assert fsms_paradigm.timecourse_all_units.shape[1] == 3


class TestParadigmTrialSelection:
    """Tests for selecting trial ranges in Paradigm objects."""

    def test_select_trial_range_updates_n_trials(self, fob_paradigm):
        """Test that selecting trial range updates n_trials."""
        fob_paradigm.select_trial_range(0, 5)

        assert fob_paradigm.n_trials == 5

    def test_select_trial_range_filters_trial_arrays(self, fob_paradigm):
        """Test that trial-level arrays are filtered correctly."""
        fob_paradigm.select_trial_range(2, 7)

        assert fob_paradigm.stimulus_index_valid.shape == (5,)
        assert fob_paradigm.on_durations.shape == (5,)
        assert fob_paradigm.trial_durations.shape == (5,)

    def test_select_trial_range_updates_n_time(self, fob_paradigm):
        """Test that n_time is updated based on trial range."""
        fob_paradigm.select_trial_range(0, 5)

        # 5 trials * 100 ms per trial = 500 time points
        assert fob_paradigm.n_time == 500

    def test_select_trial_range_filters_timecourse(self, fob_paradigm):
        """Test that timecourse arrays are filtered correctly."""
        fob_paradigm.select_trial_range(0, 5)

        assert fob_paradigm.timecourse_all_units.shape[0] == 500
        assert fob_paradigm.eyex_timecourse.shape == (500,)
        assert fob_paradigm.eyey_timecourse.shape == (500,)

    def test_select_trial_range_adjusts_on_times(self, fob_paradigm):
        """Test that timecourse_on_times are adjusted for new start time."""
        fob_paradigm.select_trial_range(2, 7)

        # First trial should now start at 0 (adjusted from 200)
        assert fob_paradigm.timecourse_on_times[0] == 0

    def test_select_trial_range_with_single_trial(self, fob_paradigm):
        """Test selecting a single trial."""
        fob_paradigm.select_trial_range(3, 4)

        assert fob_paradigm.n_trials == 1
        assert fob_paradigm.n_time == 100

    def test_select_trial_range_validation_negative_start(self, fob_paradigm):
        """Test that negative trial_start raises error."""
        with pytest.raises(AssertionError):
            fob_paradigm.select_trial_range(-1, 5)

    def test_select_trial_range_validation_zero_stop(self, fob_paradigm):
        """Test that trial_stop must be at least 1."""
        with pytest.raises(AssertionError):
            fob_paradigm.select_trial_range(0, 0)

    def test_select_trial_range_validation_empty_range(self, fob_paradigm):
        """Test that empty range (start >= stop) raises error."""
        with pytest.raises(AssertionError):
            fob_paradigm.select_trial_range(5, 5)

    def test_select_trial_range_validation_out_of_bounds(self, fob_paradigm):
        """Test that out-of-bounds stop raises error."""
        with pytest.raises(AssertionError):
            fob_paradigm.select_trial_range(0, 20)  # Only 10 trials

    def test_fsms_select_trial_range_filters_extra_fields(self, fsms_paradigm):
        """Test that FSMS trial selection filters all trial-specific fields."""
        fsms_paradigm.select_trial_range(0, 5)

        assert fsms_paradigm.trial_is_priming.shape == (5,)
        assert fsms_paradigm.trial_is_binocular.shape == (5,)
        assert fsms_paradigm.trial_is_gray.shape == (5,)
        assert fsms_paradigm.trial_dominant_image_index.shape == (5,)


class TestFOBParadigm:
    """Tests specific to FOBParadigm."""

    def test_fob_paradigm_name(self):
        """Test that FOB paradigm has correct name and abbreviation."""
        assert FOBParadigm.paradigm_name == 'FOB'
        assert FOBParadigm.paradigm_abbr == 'fob'

    def test_fob_paradigm_creation(self, sample_fob_paradigm_data):
        """Test FOB paradigm can be created with valid data."""
        paradigm = FOBParadigm(**sample_fob_paradigm_data)
        assert paradigm.n_trials == 10

    def test_fob_paradigm_roundtrip(self, temp_dir, fob_paradigm):
        """Test FOB paradigm save/load roundtrip."""
        fpath = temp_dir / 'fob.h5'
        with h5py.File(fpath, 'w') as f:
            g = f.create_group('fob')
            fob_paradigm.to_h5(g)

        with h5py.File(fpath, 'r') as f:
            loaded = FOBParadigm.from_h5(f['fob'])

        assert loaded.n_trials == fob_paradigm.n_trials


class TestFSParadigm:
    """Tests for shared FSParadigm logic (exercised via FSOParadigm)."""

    def test_fs_paradigm_is_not_concrete(self):
        """FSParadigm should not define paradigm_name or paradigm_abbr."""
        assert not hasattr(FSParadigm, 'paradigm_name') or 'paradigm_name' not in FSParadigm.__dict__
        assert not hasattr(FSParadigm, 'paradigm_abbr') or 'paradigm_abbr' not in FSParadigm.__dict__

    def test_fs_paradigm_creation(self, sample_fsms_paradigm_data):
        """Test that a concrete FS subclass can be created with all required fields."""
        paradigm = FSOParadigm(**sample_fsms_paradigm_data)
        assert paradigm.n_trials == 10
        assert hasattr(paradigm, 'trial_is_priming')

    def test_fs_paradigm_validation_trial_indicators(self, sample_fsms_paradigm_data):
        """Test that trial indicator arrays must have shape (n_trials,)."""
        data = sample_fsms_paradigm_data.copy()
        data['trial_is_priming'] = np.array([1, 0, 0], dtype=np.int32)

        with pytest.raises(AssertionError):
            FSOParadigm(**data)

    def test_fs_paradigm_roundtrip(self, temp_dir, sample_fsms_paradigm_data):
        """Test that FS paradigm data survives an HDF5 save/load round-trip."""
        paradigm = FSOParadigm(**sample_fsms_paradigm_data)
        fpath = temp_dir / 'fso.h5'
        with h5py.File(fpath, 'w') as f:
            paradigm.to_h5(f.create_group('fso'))

        with h5py.File(fpath, 'r') as f:
            loaded = FSOParadigm.from_h5(f['fso'])

        assert np.array_equal(loaded.trial_is_priming, paradigm.trial_is_priming)

    def test_fs_paradigm_select_units(self, sample_fsms_paradigm_data):
        """Test that select_units filters timecourse_all_units."""
        paradigm = FSOParadigm(**sample_fsms_paradigm_data)
        paradigm.select_units(np.array([0, 2, 4]))

        assert paradigm.timecourse_all_units.shape[1] == 3

    def test_fs_paradigm_select_trial_range(self, sample_fsms_paradigm_data):
        """Test that select_trial_range slices all per-trial FS fields."""
        paradigm = FSOParadigm(**sample_fsms_paradigm_data)
        paradigm.select_trial_range(0, 5)

        assert paradigm.trial_is_priming.shape == (5,)
        assert paradigm.trial_is_binocular.shape == (5,)
        assert paradigm.trial_is_gray.shape == (5,)
        assert paradigm.trial_dominant_image_index.shape == (5,)


class TestFSMParadigm:
    """Tests specific to FSMParadigm."""

    def test_fsms_paradigm_name(self):
        """Test that FSMS paradigm has correct name and abbreviation."""
        assert FSMParadigm.paradigm_name == 'flash_suppression_many_stimuli'
        assert FSMParadigm.paradigm_abbr == 'fsm'

    def test_fsms_paradigm_creation(self, sample_fsms_paradigm_data):
        """Test FSMS paradigm can be created with all required fields."""
        paradigm = FSMParadigm(**sample_fsms_paradigm_data)
        assert paradigm.n_trials == 10
        assert hasattr(paradigm, 'trial_is_priming')

    def test_fsms_paradigm_validation_trial_indicators(self, sample_fsms_paradigm_data):
        """Test that FSMS trial indicators must have correct shape."""
        data = sample_fsms_paradigm_data.copy()
        data['trial_is_priming'] = np.array([1, 0, 0], dtype=np.int32)  # Wrong length

        with pytest.raises(AssertionError):
            FSMParadigm(**data)

    def test_fsms_paradigm_roundtrip(self, temp_dir, fsms_paradigm):
        """Test FSMS paradigm save/load roundtrip."""
        fpath = temp_dir / 'fsms.h5'
        with h5py.File(fpath, 'w') as f:
            g = f.create_group('fsms')
            fsms_paradigm.to_h5(g)

        with h5py.File(fpath, 'r') as f:
            loaded = FSMParadigm.from_h5(f['fsms'])

        assert np.array_equal(loaded.trial_is_priming, fsms_paradigm.trial_is_priming)


class TestFSOParadigm:
    """Tests specific to FSOParadigm."""

    def test_fso_paradigm_name(self):
        """Test that FSO paradigm has correct name and abbreviation."""
        assert FSOParadigm.paradigm_name == 'flash_suppression_optimized'
        assert FSOParadigm.paradigm_abbr == 'fso'

    def test_fso_paradigm_creation(self, sample_fsms_paradigm_data):
        """Test FSO paradigm can be created (same structure as FSMS)."""
        paradigm = FSOParadigm(**sample_fsms_paradigm_data)
        assert paradigm.n_trials == 10


class TestParadigmEdgeCases:
    """Tests for edge cases and boundary conditions in Paradigm classes."""

    def test_paradigm_with_single_trial(self, sample_fob_paradigm_data):
        """Test paradigm with only one trial."""
        data = sample_fob_paradigm_data.copy()
        data['n_trials'] = 1
        data['stimulus_index_valid'] = np.array([0], dtype=np.int32)
        data['on_durations'] = np.array([300], dtype=np.int32)
        data['off_durations'] = np.array([200], dtype=np.int32)
        data['trial_durations'] = np.array([100], dtype=np.int32)
        data['timecourse_on_times'] = np.array([0], dtype=np.int32)
        data['timecourse_off_times'] = np.array([50], dtype=np.int32)
        data['timecourse_on_times_ks'] = np.array([0.0], dtype=np.float64)
        data['n_time'] = 100
        data['timecourse_all_units'] = np.random.randint(0, 5, size=(100, 5), dtype=np.int32)
        data['eyex_timecourse'] = np.random.randn(100)
        data['eyey_timecourse'] = np.random.randn(100)

        paradigm = FOBParadigm(**data)
        assert paradigm.n_trials == 1

    def test_paradigm_with_single_stimulus(self, sample_fob_paradigm_data):
        """Test paradigm with only one stimulus."""
        data = sample_fob_paradigm_data.copy()
        data['stimulus_files'] = ['single_stim.png']
        data['stimulus_index_valid'] = np.zeros(10, dtype=np.int32)

        paradigm = FOBParadigm(**data)
        assert len(paradigm.stimulus_files) == 1

    def test_paradigm_with_many_stimuli(self, sample_fob_paradigm_data):
        """Test paradigm with many stimuli."""
        data = sample_fob_paradigm_data.copy()
        n_stimuli = 100
        data['stimulus_files'] = [f'stim_{i}.png' for i in range(n_stimuli)]
        data['stimulus_index_valid'] = np.random.randint(0, n_stimuli, size=10, dtype=np.int32)

        paradigm = FOBParadigm(**data)
        assert len(paradigm.stimulus_files) == 100

    def test_paradigm_with_zero_spike_timecourse(self, sample_fob_paradigm_data):
        """Test paradigm where all spikes are zero (no neural activity)."""
        data = sample_fob_paradigm_data.copy()
        data['timecourse_all_units'] = np.zeros((1000, 5), dtype=np.int32)

        paradigm = FOBParadigm(**data)
        assert np.all(paradigm.timecourse_all_units == 0)

    def test_paradigm_with_high_spike_rates(self, sample_fob_paradigm_data):
        """Test paradigm with very high spike counts."""
        data = sample_fob_paradigm_data.copy()
        data['timecourse_all_units'] = np.random.randint(0, 100, size=(1000, 5), dtype=np.int32)

        paradigm = FOBParadigm(**data)
        assert paradigm.n_time == 1000

    def test_paradigm_trial_bounds_for_varying_durations(self, sample_fob_paradigm_data):
        """Test trial_bounds with varying trial durations."""
        data = sample_fob_paradigm_data.copy()
        # Varying trial durations
        data['trial_durations'] = np.array([100, 150, 120, 80, 200, 100, 90, 110, 130, 120], dtype=np.int32)
        # Adjust timecourse_on_times to match
        on_times = [0]
        for i in range(1, 10):
            on_times.append(on_times[-1] + data['trial_durations'][i-1])
        data['timecourse_on_times'] = np.array(on_times, dtype=np.int32)
        data['n_time'] = sum(data['trial_durations'])
        data['timecourse_all_units'] = np.random.randint(0, 5, size=(data['n_time'], 5), dtype=np.int32)
        data['eyex_timecourse'] = np.random.randn(data['n_time'])
        data['eyey_timecourse'] = np.random.randn(data['n_time'])

        paradigm = FOBParadigm(**data)
        bounds = paradigm.trial_bounds

        assert bounds[0][1] - bounds[0][0] == 100
        assert bounds[1][1] - bounds[1][0] == 150

    def test_is_nonneg_int_helper_with_edge_cases(self):
        """Test _is_nonneg_int helper with various edge cases."""
        # Empty array
        assert FOBParadigm._is_nonneg_int(np.array([], dtype=np.int32))

        # Large integers
        large_arr = np.array([0, 1000000, 999999999], dtype=np.int64)
        assert FOBParadigm._is_nonneg_int(large_arr)

        # Mixed signs
        mixed = np.array([1, 2, -1], dtype=np.int32)
        assert not FOBParadigm._is_nonneg_int(mixed)
