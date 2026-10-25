"""Session class."""

from dataclasses import dataclass
from typing import Self, Optional
from datetime import datetime
from pathlib import Path

import numpy as np
import h5py

from .paradigm import Paradigm
from .naming import parse_session_name


@dataclass
class Session:
    """Class containing all data for single Tsao lab session."""

    # Name of session (includes timestamp and name of animal)
    session_name: str

    # Index used for session in Tsao Lab inventory
    session_index: int

    # Name of animal used for session
    animal: str

    # Date and time when recording took place
    timestamp: datetime

    # Software used for recording system
    acquisition_software: str

    # Number of probes used for session
    n_probes: int

    # Number of units found after spike sorting
    n_units: int

    # Region where each probe was placed
    regions: tuple[str, ...]

    # Layer direction for each probe
    layer_direction: tuple[int, ...]

    # Kilosort ID for each unit in dataset
    unit_id: np.ndarray

    # Channel each unit was recorded from
    unit_channel: np.ndarray

    # Probe each unit was recorded from
    unit_probe: np.ndarray

    # Quality of each unit
    unit_quality: np.ndarray

    # All paradigms in session, indexed by their abbreviated names
    paradigms: dict[str, Paradigm]

    # Unit waveforms
    unit_waveform_uv: Optional[np.ndarray] = None

    # Time discretization used for unit waveforms
    unit_waveform_time: Optional[np.ndarray] = None

    # Normalized and shifted waveforms
    unit_waveform_norm_shift: Optional[np.ndarray] = None

    def __post_init__(self):
        self.validate()

    @staticmethod
    def _is_nonneg_int(arr: np.ndarray) -> bool:
        """Returns True if array is integer type and all values are non-negative."""

        is_int = bool(np.issubdtype(arr.dtype, np.integer))
        is_nonneg = np.all(arr >= 0).item()

        return is_int and is_nonneg

    def validate(self):
        """Throw error if any values are invalid."""

        # Validate `regions`
        assert len(self.regions) == self.n_probes

        # Validate `layer_direction`
        assert len(self.layer_direction) == self.n_probes
        for x in self.layer_direction:
            assert isinstance(x, int)
            assert x in [-1, 0, 1]

        # Validate `unit_id`
        assert self.unit_id.shape == (self.n_units,)
        assert self._is_nonneg_int(self.unit_id)

        # Validate `unit_channel`
        assert self.unit_channel.shape == (self.n_units,)
        assert self._is_nonneg_int(self.unit_channel)

        # Validate `unit_probe`
        assert self.unit_probe.shape == (self.n_units,)
        assert self._is_nonneg_int(self.unit_probe)

        # Validate `unit_quality`
        assert self.unit_quality.shape == (self.n_units,)

        # TODO: Change this back after I make waveform data required again
        # Validate `unit_waveform_uv`, `unit_waveform_time`, `unit_waveform_norm_shift`
        # nt_waveform = self.unit_waveform_time.shape[0]
        # assert self.unit_waveform_time.shape == (nt_waveform,)
        # assert self.unit_waveform_uv.shape == (nt_waveform, self.n_units)
        # assert self.unit_waveform_norm_shift.shape == (nt_waveform, self.n_units)

        # Validate paradigms
        for pdm_abbr, pdm in self.paradigms.items():
            assert pdm.paradigm_abbr == pdm_abbr
            assert pdm.timecourse_all_units.shape[1] == self.n_units

    @property
    def paradigm_names(self):
        return list(self.paradigms.keys())

    @classmethod
    def from_h5(
        cls, fpath: Path, load_paradigms: bool = True, units: np.ndarray | None = None
    ) -> Self:
        """Load session data from HDF5 file.

        Args:
            fpath: Path
                Path to HDF5 file containing session data
            load_paradigms: bool (default=True)
                Whether to load paradigm data in addition to top-level session data.
            units: np.ndarray (default=None)
                If this argument is set, only load specified units from file.
        Returns:
            session: Session
                Data from file loaded into Session object
        """

        # Dict mapping paradigm name to class
        paradigm_classes = {cls.paradigm_name: cls for cls in Paradigm.concrete_subclasses()}

        # Dictionary for data that will be used to create Session object
        data = {}

        with h5py.File(fpath, 'r') as f:
            # Extract animal and timestamp from session name
            session_name = str(f.attrs['session_name'])
            data['session_name'] = session_name
            data['timestamp'], data['animal'] = parse_session_name(session_name)

            # Load other fields
            data['session_index'] = int(f.attrs['session_index'].item())
            data['acquisition_software'] = str(f.attrs['acquisition_software'])
            data['regions'] = tuple(f.attrs['regions'].tolist())
            data['layer_direction'] = tuple(f.attrs['layer_direction'].tolist())
            data['n_probes'] = int(f.attrs['n_probes'].item())
            data['n_units'] = int(f.attrs['n_units'].item())
            data['unit_id'] = np.array(f['/unit_id']).flatten()
            data['unit_channel'] = np.array(f['/unit_channel']).flatten()
            data['unit_probe'] = np.array(f['/unit_probe']).flatten()
            data['unit_quality'] = np.array(f['/unit_quality']).flatten()

            # Waveform data is optional, but all three fields are either present or not
            if '/unit_waveform_uv' in f:
                data['unit_waveform_uv'] = np.array(f['/unit_waveform_uv'])
                data['unit_waveform_time'] = np.array(f['/unit_waveform_time']).flatten()
                data['unit_waveform_norm_shift'] = np.array(f['/unit_waveform_norm_shift'])

            # If units argument is set, restrict units in top-level data
            if units is not None:
                assert units.shape[0] > 0
                assert np.all(units < data['n_units'])
                data['n_units'] = units.shape[0]
                data['unit_id'] = data['unit_id'][units]
                data['unit_channel'] = data['unit_channel'][units]
                data['unit_probe'] = data['unit_probe'][units]
                data['unit_quality'] = data['unit_quality'][units]
                if 'unit_waveform_uv' in data:
                    data['unit_waveform_uv'] = data['unit_waveform_uv'][:, units]
                if 'unit_waveform_norm_shift' in data:
                    data['unit_waveform_norm_shift'] = data['unit_waveform_norm_shift'][:, units]

            # Paradigms (if load_paradigms is false, leave dict empty)
            data['paradigms'] = {}
            if load_paradigms:
                paradigm_names = list(f['/paradigms'].keys())
                for pd_name in paradigm_names:
                    # Get paradigm group
                    pd_group_path = f'/paradigms/{pd_name}'
                    pd_group = f[pd_group_path]

                    # Get subclass for paradigm type
                    try:
                        pd_cls = paradigm_classes[pd_name]
                    except KeyError:
                        raise ValueError(f"Paradigm '{pd_name}' not supported.")

                    # Load paradigm and save in dict with abbreviation as key
                    pd = pd_cls.from_h5(pd_group, units=units)
                    data['paradigms'][pd.paradigm_abbr] = pd

        return cls(**data)

    def to_h5(self, fpath: Path) -> None:
        """Save Session object to HDF5 file.

        Args:
            fpath: Path where the HDF5 file will be saved
        """

        with h5py.File(fpath, 'w') as f:
            # Save session-level attributes
            f.attrs['session_name'] = self.session_name
            f.attrs['session_index'] = self.session_index
            f.attrs['acquisition_software'] = self.acquisition_software
            f.attrs['regions'] = np.array(self.regions, dtype=h5py.string_dtype())
            f.attrs['layer_direction'] = self.layer_direction
            f.attrs['n_probes'] = self.n_probes
            f.attrs['n_units'] = self.n_units

            # Save unit-level datasets
            f.create_dataset('/unit_id', data=self.unit_id)
            f.create_dataset('/unit_channel', data=self.unit_channel)
            f.create_dataset('/unit_probe', data=self.unit_probe)
            f.create_dataset('/unit_quality', data=self.unit_quality)

            # Waveform data is optional, but all three fields are either present or not
            if self.unit_waveform_uv is not None:
                f.create_dataset('/unit_waveform_uv', data=self.unit_waveform_uv)
                f.create_dataset('/unit_waveform_time', data=self.unit_waveform_time)
                f.create_dataset('/unit_waveform_norm_shift', data=self.unit_waveform_norm_shift)

            # Create paradigms group
            paradigms_group = f.create_group('/paradigms')

            # Save each paradigm
            for paradigm in self.paradigms.values():
                pd_group = paradigms_group.create_group(paradigm.paradigm_name)
                paradigm.to_h5(pd_group)

    def select_units(self, units: np.ndarray) -> None:
        """Select subset of units in Session object.

        Args:
            units: All units to select
        """

        # Validate units array
        assert units.shape[0] > 0
        assert np.all(units < self.n_units)

        # Alter fields that depend on units
        self.n_units = units.shape[0]
        self.unit_id = self.unit_id[units]
        self.unit_channel = self.unit_channel[units]
        self.unit_probe = self.unit_probe[units]
        self.unit_quality = self.unit_quality[units]
        if self.unit_waveform_uv is not None:
            self.unit_waveform_uv = self.unit_waveform_uv[:, units]
        if self.unit_waveform_norm_shift is not None:
            self.unit_waveform_norm_shift = self.unit_waveform_norm_shift[:, units]

        # Recursively select units for all paradigms
        for pd_abbr in self.paradigms.keys():
            self.paradigms[pd_abbr].select_units(units)

        # Make sure selection didn't introduce inconsistencies
        self.validate()

    def select_probe(self, probe: int) -> None:
        """Select probe in Session object.

        Args:
            probe: Probe number to select
        """

        # Make sure probe is positive number
        assert probe >= 1
        probe_python_index = probe - 1

        # Check that probe to select is in list of session probes
        assert np.isin(probe, np.unique(self.unit_probe))

        # Indices of all units on selected probe
        units = np.argwhere(self.unit_probe == probe).flatten()

        # Select probe units
        self.select_units(units)

        # Alter fields that depend on probe selection
        self.n_probes = 1
        self.regions = (self.regions[probe_python_index],)
        self.layer_direction = (self.layer_direction[probe_python_index],)

        # Make sure selection didn't introduce inconsistencies
        self.validate()
