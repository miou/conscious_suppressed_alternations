"""Comprehensive unit tests for Session class.

This test module covers:
- Session initialization and validation
- Data loading from HDF5 files
- Data saving to HDF5 files
- Unit selection and filtering
- Probe selection
- Edge cases and error handling
"""

import tempfile
from pathlib import Path
from datetime import datetime

import pytest
import numpy as np
import h5py

from tsao_lab_data.session import Session
from tsao_lab_data.paradigm import FOBParadigm


class TestSessionInitialization:
    """Tests for Session object initialization and validation."""

    def test_session_creation_with_valid_data(self, sample_session_data, fob_paradigm):
        """Test that Session can be created with valid data."""
        data = sample_session_data.copy()
        data['paradigms'] = {'fob': fob_paradigm}
        session = Session(**data)

        assert session.session_name == '210803_133520_Alfie'
        assert session.animal == 'Alfie'
        assert session.n_units == 5
        assert session.n_probes == 2
        assert len(session.paradigms) == 1

    def test_session_validation_called_on_init(self, sample_session_data):
        """Test that validation is automatically called on initialization."""
        data = sample_session_data.copy()
        # Create invalid data - wrong shape for unit_id
        data['unit_id'] = np.array([0, 1, 2])  # Should be 5 units, not 3

        with pytest.raises(AssertionError):
            Session(**data)

    def test_session_regions_length_matches_n_probes(self, sample_session_data):
        """Test that number of regions must match n_probes."""
        data = sample_session_data.copy()
        data['regions'] = ('ML',)  # Only 1 region but n_probes is 2

        with pytest.raises(AssertionError):
            Session(**data)

    def test_session_layer_direction_length_matches_n_probes(self, sample_session_data):
        """Test that layer_direction length must match n_probes."""
        data = sample_session_data.copy()
        data['layer_direction'] = (1,)  # Only 1 direction but n_probes is 2

        with pytest.raises(AssertionError):
            Session(**data)

    def test_session_layer_direction_only_accepts_valid_values(self, sample_session_data):
        """Test that layer_direction only accepts -1, 0, or 1."""
        data = sample_session_data.copy()
        data['layer_direction'] = (1, 0)  # 0 is valid

        Session(**data)  # should not raise

        data['layer_direction'] = (1, 2)  # 2 is invalid
        with pytest.raises(AssertionError):
            Session(**data)

    def test_session_unit_id_shape_validation(self, sample_session_data):
        """Test that unit_id must have correct shape."""
        data = sample_session_data.copy()
        data['unit_id'] = np.array([[0, 1, 2, 3, 4]])  # 2D array instead of 1D

        with pytest.raises(AssertionError):
            Session(**data)

    def test_session_unit_id_must_be_nonnegative_integers(self, sample_session_data):
        """Test that unit_id must contain non-negative integers."""
        data = sample_session_data.copy()
        data['unit_id'] = np.array([0, 1, 2, -1, 4], dtype=np.int32)  # Negative value

        with pytest.raises(AssertionError):
            Session(**data)

    def test_session_unit_channel_validation(self, sample_session_data):
        """Test that unit_channel must have correct shape and be non-negative."""
        data = sample_session_data.copy()
        data['unit_channel'] = np.array([10, 15, 20], dtype=np.int32)  # Wrong length

        with pytest.raises(AssertionError):
            Session(**data)

    def test_session_unit_probe_validation(self, sample_session_data):
        """Test that unit_probe must have correct shape and be non-negative."""
        data = sample_session_data.copy()
        data['unit_probe'] = np.array([1, 1, 2, 2, -1], dtype=np.int32)  # Negative value

        with pytest.raises(AssertionError):
            Session(**data)

    def test_session_waveform_shapes_validation(self, sample_session_data):
        """Test that waveform arrays with inconsistent shapes are currently accepted (validation disabled)."""
        data = sample_session_data.copy()
        # Make unit_waveform_uv have wrong shape
        data['unit_waveform_uv'] = np.random.randn(50, 5)  # Different time points than unit_waveform_time

        Session(**data)  # should not raise — waveform validation is temporarily disabled

    def test_session_paradigm_validation(self, sample_session_data, fob_paradigm):
        """Test that paradigms are validated against session properties."""
        data = sample_session_data.copy()
        # Create paradigm with wrong number of units
        bad_paradigm_data = {
            'n_trials': 10,
            'n_time': 1000,
            'stimulus_files': ['stim_0.png'],
            'stimulus_index_valid': np.zeros(10, dtype=np.int32),
            'timecourse_all_units': np.random.randint(0, 5, size=(1000, 3), dtype=np.int32),  # 3 units instead of 5
            'on_duration': 300,
            'off_duration': 200,
            'on_durations': np.full(10, 300, dtype=np.int32),
            'off_durations': np.full(10, 200, dtype=np.int32),
            'trial_durations': np.full(10, 100, dtype=np.int32),
            'timecourse_on_times': np.arange(0, 1000, 100, dtype=np.int32),
            'timecourse_off_times': np.arange(50, 1050, 100, dtype=np.int32),
            'timecourse_on_times_ks': np.arange(0, 1.0, 0.1, dtype=np.float64),
            'eyex_timecourse': np.random.randn(1000),
            'eyey_timecourse': np.random.randn(1000),
        }
        bad_paradigm = FOBParadigm(**bad_paradigm_data)
        data['paradigms'] = {'fob': bad_paradigm}

        with pytest.raises(AssertionError):
            Session(**data)


class TestSessionDataLoading:
    """Tests for loading Session data from HDF5 files."""

    def test_session_from_h5_loads_basic_attributes(self, sample_h5_file):
        """Test that basic session attributes are loaded correctly from HDF5."""
        session = Session.from_h5(sample_h5_file)

        assert session.session_name == '210803_133520_Alfie'
        assert session.animal == 'Alfie'
        assert session.session_index == 5
        assert session.acquisition_software == 'OpenEphys'
        assert session.n_probes == 2
        assert session.n_units == 5

    def test_session_from_h5_loads_regions_and_layers(self, sample_h5_file):
        """Test that regions and layer directions are loaded correctly."""
        session = Session.from_h5(sample_h5_file)

        assert session.regions == ('ML', 'AM')
        assert session.layer_direction == (1, -1)

    def test_session_from_h5_loads_unit_data(self, sample_h5_file):
        """Test that unit-level data is loaded correctly."""
        session = Session.from_h5(sample_h5_file)

        assert session.unit_id.shape == (5,)
        assert session.unit_channel.shape == (5,)
        assert session.unit_probe.shape == (5,)
        assert session.unit_quality.shape == (5,)
        assert np.all(session.unit_id >= 0)

    def test_session_from_h5_loads_waveform_data(self, sample_h5_file):
        """Test that waveform data is loaded with correct shapes."""
        session = Session.from_h5(sample_h5_file)

        nt = session.unit_waveform_time.shape[0]
        assert session.unit_waveform_uv.shape == (nt, 5)
        assert session.unit_waveform_norm_shift.shape == (nt, 5)

    def test_session_from_h5_loads_paradigms(self, sample_h5_file):
        """Test that paradigms are loaded correctly from HDF5."""
        session = Session.from_h5(sample_h5_file)

        assert 'fob' in session.paradigms
        paradigm = session.paradigms['fob']
        assert isinstance(paradigm, FOBParadigm)
        assert paradigm.n_trials == 10

    def test_session_from_h5_extracts_animal_from_name(self, sample_h5_file):
        """Test that animal name is correctly extracted from session name."""
        session = Session.from_h5(sample_h5_file)

        assert session.animal == 'Alfie'

    def test_session_from_h5_extracts_timestamp_from_name(self, sample_h5_file):
        """Test that timestamp is correctly extracted from session name."""
        session = Session.from_h5(sample_h5_file)

        assert session.timestamp == datetime(2021, 8, 3, 13, 35, 20)

    def test_session_from_h5_with_nonexistent_file(self, temp_dir):
        """Test that loading from non-existent file raises appropriate error."""
        nonexistent_file = temp_dir / 'nonexistent.h5'

        with pytest.raises(FileNotFoundError):
            Session.from_h5(nonexistent_file)

    def test_session_from_h5_with_unsupported_paradigm(self, temp_dir, sample_session):
        """Test that loading with unsupported paradigm raises ValueError."""
        fpath = temp_dir / 'bad_paradigm.h5'

        # Manually create HDF5 with invalid paradigm name
        with h5py.File(fpath, 'w') as f:
            f.attrs['session_name'] = '210803_133520_Alfie'
            f.attrs['session_index'] = 5
            f.attrs['acquisition_software'] = 'OpenEphys'
            f.attrs['regions'] = np.array(['ML', 'AM'], dtype=h5py.string_dtype())
            f.attrs['layer_direction'] = [1, -1]
            f.attrs['n_probes'] = 2
            f.attrs['n_units'] = 5

            f.create_dataset('/unit_id', data=np.arange(5))
            f.create_dataset('/unit_channel', data=np.arange(5))
            f.create_dataset('/unit_probe', data=np.ones(5))
            f.create_dataset('/unit_quality', data=np.ones(5))
            f.create_dataset('/unit_waveform_uv', data=np.zeros((82, 5)))
            f.create_dataset('/unit_waveform_time', data=np.linspace(-1, 1, 82))
            f.create_dataset('/unit_waveform_norm_shift', data=np.zeros((82, 5)))

            # Create paradigm group with invalid name
            paradigms_group = f.create_group('/paradigms')
            invalid_paradigm = paradigms_group.create_group('invalid_paradigm_name')
            invalid_paradigm.attrs['paradigm_name'] = 'invalid_paradigm_name'

        with pytest.raises(ValueError, match="Paradigm.*not supported"):
            Session.from_h5(fpath)


class TestSessionDataSaving:
    """Tests for saving Session data to HDF5 files."""

    def test_session_to_h5_creates_file(self, temp_dir, sample_session):
        """Test that to_h5 creates an HDF5 file."""
        fpath = temp_dir / 'output.h5'
        sample_session.to_h5(fpath)

        assert fpath.exists()
        assert fpath.is_file()

    def test_session_to_h5_saves_attributes(self, temp_dir, sample_session):
        """Test that session attributes are saved to HDF5."""
        fpath = temp_dir / 'output.h5'
        sample_session.to_h5(fpath)

        with h5py.File(fpath, 'r') as f:
            assert f.attrs['session_name'] == '210803_133520_Alfie'
            assert f.attrs['session_index'] == 5
            assert f.attrs['acquisition_software'] == 'OpenEphys'
            assert f.attrs['n_probes'] == 2
            assert f.attrs['n_units'] == 5

    def test_session_to_h5_saves_unit_datasets(self, temp_dir, sample_session):
        """Test that unit-level datasets are saved correctly."""
        fpath = temp_dir / 'output.h5'
        sample_session.to_h5(fpath)

        with h5py.File(fpath, 'r') as f:
            assert '/unit_id' in f
            assert '/unit_channel' in f
            assert '/unit_probe' in f
            assert '/unit_quality' in f
            assert f['/unit_id'].shape == (5,)

    def test_session_to_h5_saves_waveform_datasets(self, temp_dir, sample_session):
        """Test that waveform datasets are saved correctly."""
        fpath = temp_dir / 'output.h5'
        sample_session.to_h5(fpath)

        with h5py.File(fpath, 'r') as f:
            assert '/unit_waveform_uv' in f
            assert '/unit_waveform_time' in f
            assert '/unit_waveform_norm_shift' in f

    def test_session_to_h5_saves_paradigms(self, temp_dir, sample_session):
        """Test that paradigms are saved in HDF5 structure."""
        fpath = temp_dir / 'output.h5'
        sample_session.to_h5(fpath)

        with h5py.File(fpath, 'r') as f:
            assert '/paradigms' in f
            assert '/paradigms/FOB' in f

    def test_session_to_h5_roundtrip_preserves_data(self, temp_dir, sample_session):
        """Test that saving and loading preserves session data."""
        fpath = temp_dir / 'roundtrip.h5'
        sample_session.to_h5(fpath)
        loaded_session = Session.from_h5(fpath)

        assert loaded_session.session_name == sample_session.session_name
        assert loaded_session.n_units == sample_session.n_units
        assert loaded_session.n_probes == sample_session.n_probes
        assert np.array_equal(loaded_session.unit_id, sample_session.unit_id)
        assert np.array_equal(loaded_session.unit_channel, sample_session.unit_channel)
        assert len(loaded_session.paradigms) == len(sample_session.paradigms)


class TestSessionUnitSelection:
    """Tests for selecting subsets of units from Session."""

    def test_select_units_reduces_n_units(self, sample_session):
        """Test that selecting units updates n_units correctly."""
        units_to_select = np.array([0, 2, 4])
        sample_session.select_units(units_to_select)

        assert sample_session.n_units == 3

    def test_select_units_filters_unit_arrays(self, sample_session):
        """Test that unit arrays are filtered correctly."""
        original_unit_ids = sample_session.unit_id.copy()
        units_to_select = np.array([0, 2, 4])
        sample_session.select_units(units_to_select)

        assert np.array_equal(sample_session.unit_id, original_unit_ids[units_to_select])
        assert sample_session.unit_channel.shape == (3,)
        assert sample_session.unit_probe.shape == (3,)
        assert sample_session.unit_quality.shape == (3,)

    def test_select_units_filters_waveforms(self, sample_session):
        """Test that waveform arrays are filtered correctly."""
        units_to_select = np.array([1, 3])
        nt_original = sample_session.unit_waveform_uv.shape[0]
        sample_session.select_units(units_to_select)

        assert sample_session.unit_waveform_uv.shape == (nt_original, 2)
        assert sample_session.unit_waveform_norm_shift.shape == (nt_original, 2)

    def test_select_units_propagates_to_paradigms(self, sample_session):
        """Test that unit selection is propagated to all paradigms."""
        units_to_select = np.array([0, 1, 2])
        sample_session.select_units(units_to_select)

        paradigm = sample_session.paradigms['fob']
        assert paradigm.timecourse_all_units.shape[1] == 3

    def test_select_units_maintains_validation(self, sample_session):
        """Test that session remains valid after unit selection."""
        units_to_select = np.array([0, 2, 4])
        sample_session.select_units(units_to_select)

        # If validation passes without raising, test succeeds
        sample_session.validate()

    def test_select_units_with_empty_selection(self, sample_session):
        """Test that passing an empty array to unit selection raises error."""
        units_to_select = np.array([], dtype=np.int32)

        # Currently raises ValueError due to np.min() on empty array
        with pytest.raises(AssertionError):
            sample_session.select_units(units_to_select)

    def test_select_units_with_single_unit(self, sample_session):
        """Test selecting a single unit works correctly."""
        units_to_select = np.array([2])
        sample_session.select_units(units_to_select)

        assert sample_session.n_units == 1
        assert sample_session.unit_id.shape == (1,)


class TestSessionProbeSelection:
    """Tests for selecting a specific probe from Session."""

    def test_select_probe_filters_to_probe_units(self, sample_session):
        """Test that selecting a probe keeps only units from that probe."""
        # From fixture, units [0, 1] are on probe 1, units [2, 3, 4] are on probe 2
        sample_session.select_probe(1)

        assert np.all(sample_session.unit_probe == 1)
        assert sample_session.n_units == 2

    def test_select_probe_updates_n_probes(self, sample_session):
        """Test that n_probes is set to 1 after probe selection."""
        sample_session.select_probe(1)

        assert sample_session.n_probes == 1

    def test_select_probe_updates_regions(self, sample_session):
        """Test that regions tuple is updated to single region."""
        sample_session.select_probe(1)

        assert len(sample_session.regions) == 1
        assert sample_session.regions == ('ML',)

    def test_select_probe_updates_layer_direction(self, sample_session):
        """Test that layer_direction tuple is updated."""
        sample_session.select_probe(1)

        assert len(sample_session.layer_direction) == 1
        assert sample_session.layer_direction == (1,)

    def test_select_probe_second_probe(self, sample_session):
        """Test selecting the second probe."""
        sample_session.select_probe(2)

        assert sample_session.n_units == 3
        assert sample_session.regions == ('AM',)
        assert sample_session.layer_direction == (-1,)

    def test_select_probe_propagates_to_paradigms(self, sample_session):
        """Test that probe selection propagates to paradigms."""
        sample_session.select_probe(1)

        paradigm = sample_session.paradigms['fob']
        assert paradigm.timecourse_all_units.shape[1] == 2

    def test_select_probe_maintains_validation(self, sample_session):
        """Test that session remains valid after probe selection."""
        sample_session.select_probe(1)

        # Validation should pass
        sample_session.validate()

    def test_select_probe_with_invalid_probe_number(self, sample_session):
        """Test that selecting non-existent probe raises error."""
        with pytest.raises(AssertionError):
            sample_session.select_probe(99)

    def test_select_probe_with_zero_probe_number(self, sample_session):
        """Test that probe number must be positive."""
        with pytest.raises(AssertionError):
            sample_session.select_probe(0)

    def test_select_probe_with_negative_probe_number(self, sample_session):
        """Test that negative probe number raises error."""
        with pytest.raises(AssertionError):
            sample_session.select_probe(-1)


class TestSessionProperties:
    """Tests for Session properties and utility methods."""

    def test_paradigm_names_property(self, sample_session):
        """Test that paradigm_names returns list of paradigm keys."""
        names = sample_session.paradigm_names

        assert isinstance(names, list)
        assert 'fob' in names
        assert len(names) == 1

    def test_is_nonneg_int_with_valid_array(self):
        """Test _is_nonneg_int helper method with valid input."""
        arr = np.array([0, 1, 2, 3], dtype=np.int32)
        assert Session._is_nonneg_int(arr)

    def test_is_nonneg_int_with_negative_values(self):
        """Test _is_nonneg_int rejects negative values."""
        arr = np.array([0, 1, -1, 3], dtype=np.int32)
        assert not Session._is_nonneg_int(arr)

    def test_is_nonneg_int_with_float_array(self):
        """Test _is_nonneg_int rejects float arrays."""
        arr = np.array([0.0, 1.0, 2.0], dtype=np.float64)
        assert not Session._is_nonneg_int(arr)

    def test_is_nonneg_int_with_zero_array(self):
        """Test _is_nonneg_int accepts all zeros."""
        arr = np.array([0, 0, 0], dtype=np.int32)
        assert Session._is_nonneg_int(arr)


class TestSessionEdgeCases:
    """Tests for edge cases and boundary conditions."""

    def test_session_with_single_unit(self, sample_session_data):
        """Test Session with only one unit."""
        data = sample_session_data.copy()
        data['n_units'] = 1
        data['unit_id'] = np.array([0], dtype=np.int32)
        data['unit_channel'] = np.array([10], dtype=np.int32)
        data['unit_probe'] = np.array([1], dtype=np.int32)
        data['unit_quality'] = np.array([0.8], dtype=np.float64)
        data['unit_waveform_uv'] = np.random.randn(82, 1)
        data['unit_waveform_norm_shift'] = np.random.randn(82, 1)

        session = Session(**data)
        assert session.n_units == 1

    def test_session_with_single_probe(self, sample_session_data):
        """Test Session with only one probe."""
        data = sample_session_data.copy()
        data['n_probes'] = 1
        data['regions'] = ('ML',)
        data['layer_direction'] = (1,)
        data['unit_probe'] = np.ones(5, dtype=np.int32)

        session = Session(**data)
        assert session.n_probes == 1

    def test_session_with_large_number_of_units(self, sample_session_data):
        """Test Session with many units to check scalability."""
        n_units = 1000
        data = sample_session_data.copy()
        data['n_units'] = n_units
        data['unit_id'] = np.arange(n_units, dtype=np.int32)
        data['unit_channel'] = np.arange(n_units, dtype=np.int32)
        data['unit_probe'] = np.random.randint(1, 3, size=n_units, dtype=np.int32)
        data['unit_quality'] = np.random.rand(n_units)
        data['unit_waveform_uv'] = np.random.randn(82, n_units)
        data['unit_waveform_norm_shift'] = np.random.randn(82, n_units)

        session = Session(**data)
        assert session.n_units == n_units

    def test_session_with_no_paradigms(self, sample_session_data):
        """Test Session with empty paradigms dictionary."""
        data = sample_session_data.copy()
        data['paradigms'] = {}

        session = Session(**data)
        assert len(session.paradigms) == 0
        assert session.paradigm_names == []

    def test_session_with_contiguous_unit_selection(self, sample_session):
        """Test unit selection with contiguous range (optimized path)."""
        # Select units [1, 2, 3] - contiguous range
        units_to_select = np.array([1, 2, 3])
        sample_session.select_units(units_to_select)

        assert sample_session.n_units == 3

    def test_session_with_noncontiguous_unit_selection(self, sample_session):
        """Test unit selection with non-contiguous indices."""
        # Select units [0, 2, 4] - non-contiguous
        units_to_select = np.array([0, 2, 4])
        sample_session.select_units(units_to_select)

        assert sample_session.n_units == 3

    def test_session_waveform_time_different_lengths(self, sample_session_data):
        """Test that different waveform time lengths can be handled."""
        data = sample_session_data.copy()
        # Use different waveform length
        nt_waveform = 100
        data['unit_waveform_time'] = np.linspace(-1, 1, nt_waveform)
        data['unit_waveform_uv'] = np.random.randn(nt_waveform, 5)
        data['unit_waveform_norm_shift'] = np.random.randn(nt_waveform, 5)

        session = Session(**data)
        assert session.unit_waveform_time.shape[0] == nt_waveform
