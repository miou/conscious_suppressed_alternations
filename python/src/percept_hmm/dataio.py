"""Helper functions for saving and loading data."""

from dataclasses import dataclass
from typing import Optional
from datetime import datetime
from pathlib import Path

import numpy as np
import pandas as pd
import h5py


# ---------------------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------------------

# Dict mapping full paradigm names to abbreviations
PARADIGM_ABBR = {
    'FOB': 'fob',
    'physical_switches_static': 'pss',
    'binocular_rivalry_static': 'brs',
    'no_report_v3_physical_switches': 'psn',
    'no_report_v3_binocular_rivalry': 'brn',
    'transparent_static': 'tss',
    'physical_switches_static_triplets': 'psst',
    'binocular_rivalry_static_triplets': 'brst',
    'no_report_v3_physical_switches_triplets': 'psnt',
    'no_report_v3_binocular_rivalry_triplets': 'brnt',
    'face_static': 'fas',
}

# Inverse dict mapping paradigm abbreviations to full names
PARADIGM_ABBR_INV = {v: k for k, v in PARADIGM_ABBR.items()}


# ---------------------------------------------------------------------------------------
# Dataclasses representing Tsao lab data
# ---------------------------------------------------------------------------------------

@dataclass
class Paradigm:
    """Class containing data for single paradigm (i.e. task) in Tsao lab session."""

    # Full name of paradigm
    paradigm_name: str

    # Abbreviation of paradigm name (used for file names)
    paradigm_abbr: str

    # Number of trials in paradigm
    n_trials: int

    # Number of time points in paradigm
    n_time: int

    # Files for all stimulus images used in paradigm
    stimulus_files: list[str]

    # Index of stimulus presented in each trial
    stimulus_index_valid: np.ndarray

    # Matrix of spikes for all units across all trials
    timecourse_all_units: np.ndarray

    # Target on duration for all trials (ms)
    on_duration: int

    # Target off duration for all trials (ms)
    off_duration: int

    # Actual on durations for each trial (ms)
    on_durations: np.ndarray

    # Actual off durations for each trial (ms)
    off_durations: np.ndarray

    # Total trial durations (ms)
    trial_durations: np.ndarray

    # Trial on times in `timecourse_all_units` matrix (ms)
    timecourse_on_times: np.ndarray

    # Trial off times in `timecourse_all_units` matrix (ms)
    timecourse_off_times: np.ndarray

    # Trial on times in kilosort time (seconds)
    timecourse_on_times_ks: np.ndarray

    # X-coordinate of eye tracking
    eyex_timecourse: np.ndarray

    # Y-coordinate of eye tracking
    eyey_timecourse: np.ndarray

    # Photodiode sequence (missing in one session)
    photodiode_timecourse: Optional[np.ndarray] = None

    # Face indicator variable (only for physical switches paradigms)
    trial_is_face: Optional[np.ndarray] = None

    # Object indicator variable (only for physical switches paradigms)
    trial_is_object: Optional[np.ndarray] = None

    # Fixation point locations (only for no-report paradigms)
    fix_positions: Optional[np.ndarray] = None

    # Indices of face fixation points (only for no-report paradigms)
    face_fix_positions_index: Optional[np.ndarray] = None

    # Indices of object fixation points (only for no-report paradigms)
    object_fix_positions_index: Optional[np.ndarray] = None

    # Indicator for  monkey fixating on point (only for no-report paradigms)
    trials_fixated: Optional[np.ndarray] = None

    # Indicator for monkey fixating on face point (only for no-report paradigms)
    trials_fixated_face: Optional[np.ndarray] = None

    # Indicator for monkey fixating on object point (only for no-report paradigms)
    trials_fixated_object: Optional[np.ndarray] = None

    # Indicator for trials where monkey percieves face (only for no-report paradigms)
    good_face_trial: Optional[np.ndarray] = None

    # Indicator for trials where monkey percieves object (only for no-report paradigms)
    good_object_trial: Optional[np.ndarray] = None

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

        # Validate `stimulus_files`
        indices_all = np.arange(len(self.stimulus_files))
        indices_used = np.unique(self.stimulus_index_valid)
        assert np.all(np.isin(indices_used, indices_all))

        # Validate `stimulus_index_valid`
        assert self.stimulus_index_valid.shape == (self.n_trials,)
        assert self._is_nonneg_int(self.timecourse_all_units)

        # Validate `timecourse_all_units`
        assert self.timecourse_all_units.shape[0] == self.n_time
        assert self._is_nonneg_int(self.timecourse_all_units)

        # Validate `on_durations`
        assert self.on_durations.shape == (self.n_trials,)
        assert self._is_nonneg_int(self.on_durations)

        # Validate `off_durations`
        assert self.off_durations.shape == (self.n_trials,)
        # assert(self._is_nonneg_int(self.off_durations)) # TODO: Find out why some of these are negative

        # Validate `trial_durations`
        assert self.trial_durations.shape == (self.n_trials,)
        assert self._is_nonneg_int(self.trial_durations)
        # assert(np.all((self.on_durations + self.off_durations) == self.trial_durations))

        # Validate `timecourse_on_times`
        assert self.timecourse_on_times.shape == (self.n_trials,)
        assert self._is_nonneg_int(self.timecourse_on_times)
        assert np.all(self.timecourse_on_times < self.n_time)
        assert np.all(np.diff(self.timecourse_on_times) == self.trial_durations[:-1])

        # TODO: Figure out why this test sometimes doesn't pass
        # Validate `timecourse_off_times`
        assert self.timecourse_off_times.shape == (self.n_trials,)
        #if not np.all(self.timecourse_off_times <= self.n_time):
        #    idx = np.argwhere(self.timecourse_off_times >= self.n_time)
        #    print(self.n_time)
        #    print(idx)
        #    print(self.timecourse_off_times[idx])
        #    print(self.paradigm_abbr)
        #assert np.all(self.timecourse_off_times <= self.n_time)
        assert self._is_nonneg_int(self.timecourse_off_times)

        # Validate `timecourse_on_times_ks`
        assert self.timecourse_on_times_ks.shape == (self.n_trials,)
        assert (
            np.issubdtype(self.timecourse_on_times_ks.dtype, np.floating)
            and np.all(np.isfinite(self.timecourse_on_times_ks))
            and np.all(self.timecourse_on_times_ks >= 0)
        )

        # Validate `eyex_timecourse`
        assert self.eyex_timecourse.shape == (self.n_time,)

        # Validate `eyey_timecourse`
        assert self.eyey_timecourse.shape == (self.n_time,)

    @property
    def trial_bounds(self):
        """List of (start time, stop time) pairs for all trials."""

        # Time point where each trial starts (inclusive)
        start_times = self.timecourse_on_times

        # Time point where each trial stops (exclusive)
        stop_times = np.append(self.timecourse_on_times[1:], self.n_time)

        return list(zip(start_times.tolist(), stop_times.tolist(), strict=True))

    @property
    def spike_trials(self):
        """List of spike matrices for each trial in paradigm."""

        return [self.timecourse_all_units[a:b, :] for a, b in self.trial_bounds]

    @property
    def eyex_timecourse_trials(self):
        """List of arrays of eye tracking x-values for each trial in paradigm."""

        return [self.eyex_timecourse[a:b] for a, b in self.trial_bounds]

    @property
    def eyey_timecourse_trials(self):
        """List of arrays of eye tracking y-values for each trial in paradigm."""

        return [self.eyey_timecourse[a:b] for a, b in self.trial_bounds]


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
    regions: tuple[str]

    # Layer direction for each probe
    layer_direction: tuple[int]

    # Kilosort ID for each unit in dataset
    unit_id: np.ndarray

    # Channel each unit was recorded from
    unit_channel: np.ndarray

    # Probe each unit was recorded from
    unit_probe: np.ndarray

    # Quality of each unit
    unit_quality: np.ndarray

    # Unit waveforms
    unit_waveform_uv: np.ndarray

    # Time discretization used for unit waveforms
    unit_waveform_time: np.ndarray

    # Normalized and shifted waveforms
    unit_waveform_norm_shift: np.ndarray

    paradigms: dict[str, Paradigm]

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
            assert x in [-1, 1]

        # Validate `unit_id`
        assert self.unit_id.shape == (self.n_units,)
        assert self._is_nonneg_int(self.unit_id)

        # Validate `unit_channel`
        assert self.unit_id.shape == (self.n_units,)
        assert self._is_nonneg_int(self.unit_id)

        # Validate `unit_probe`
        assert self.unit_probe.shape == (self.n_units,)
        assert self._is_nonneg_int(self.unit_probe)

        # Validate `unit_quality`
        assert self.unit_id.shape == (self.n_units,)

        # Validate `unit_waveform_uv`, `unit_waveform_time`, `unit_waveform_norm_shift`
        nt_waveform = self.unit_waveform_time.shape[0]
        assert self.unit_waveform_time.shape == (nt_waveform,)
        assert self.unit_waveform_uv.shape == (nt_waveform, self.n_units)
        assert self.unit_waveform_norm_shift.shape == (nt_waveform, self.n_units)

        # Validate paradigms
        for pdm_abbr, pdm in self.paradigms.items():
            assert pdm.paradigm_abbr == pdm_abbr
            assert pdm.timecourse_all_units.shape[1] == self.n_units

    @property
    def paradigm_names(self):
        return list(self.paradigms.keys())


@dataclass
class Dataset:
    """Class containing data for a single probe and paradigm for a given session.

    The 'dataset' is an abstraction we use for our analysis pipeline, because most
    analyses we run (e.g. decoding, HMM fitting) are done independently on each (probe,
    paradigm) pair for a given session. Because a single probe and paradigm recording is
    sometimes divided into "runs" based on large time gaps between groups of trials, a
    Dataset object might only contain data from a subset of trials from a particular
    paradigm.

    """

    ## Fields inherited from Session

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

    # Number of units found after spike sorting
    n_units: int

    # Region where probe was placed
    region: str

    # Layer direction for probe
    layer_direction: int

    # Kilosort ID for each unit
    unit_id: np.ndarray

    # Channel each unit was recorded from
    unit_channel: np.ndarray

    # Quality of each unit
    unit_quality: np.ndarray

    # Unit waveforms
    unit_waveform_uv: np.ndarray

    # Time discretization used for unit waveforms
    unit_waveform_time: np.ndarray

    # Normalized and shifted waveforms
    unit_waveform_norm_shift: np.ndarray

    ## Fields inherited from Paradigm

    # Full name of paradigm
    paradigm_name: str

    # Abbreviation of paradigm name (used for file names)
    paradigm_abbr: str

    # Number of trials in paradigm
    n_trials: int

    # Number of time points in paradigm
    n_time: int

    # Files for all stimulus images used in paradigm
    stimulus_files: list[str]

    # Index of stimulus presented in each trial
    stimulus_index_valid: np.ndarray

    # Matrix of spikes for all units across all trials
    timecourse_all_units: np.ndarray

    # Target on duration for all trials
    on_duration: int

    # Target off duration for all trials
    off_duration: int

    # Actual on durations for each trial
    on_durations: np.ndarray

    # Actual off durations for each trial
    off_durations: np.ndarray

    # Total trial durations
    trial_durations: np.ndarray

    # Trial on times (in `timecourse_all_units` matrix)
    timecourse_on_times: np.ndarray

    # Trial off times (in `timecourse_all_units` matrix)
    timecourse_off_times: np.ndarray

    # Trial on times in kilosort time
    timecourse_on_times_ks: np.ndarray

    # X-coordinate of eye tracking
    eyex_timecourse: np.ndarray

    # Y-coordinate of eye tracking
    eyey_timecourse: np.ndarray

    # Trial range this dataset was extracted from
    orig_trial_range: tuple[int, int]

    # Photodiode sequence (missing in one session)
    photodiode_timecourse: Optional[np.ndarray] = None

    # Face indicator variable (only for physical switches paradigms)
    trial_is_face: Optional[np.ndarray] = None

    # Object indicator variable (only for physical switches paradigms)
    trial_is_object: Optional[np.ndarray] = None

    # Indicator for  monkey fixating on point (only for no-report paradigms)
    trials_fixated: Optional[np.ndarray] = None

    # Indicator for monkey fixating on face point (only for no-report paradigms)
    trials_fixated_face: Optional[np.ndarray] = None

    # Indicator for monkey fixating on object point (only for no-report paradigms)
    trials_fixated_object: Optional[np.ndarray] = None

    # Indicator for trials where monkey percieves face (only for no-report paradigms)
    good_face_trial: Optional[np.ndarray] = None

    # Indicator for trials where monkey percieves object (only for no-report paradigms)
    good_object_trial: Optional[np.ndarray] = None

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

        # Validate `unit_id`
        assert self.unit_id.shape == (self.n_units,)
        assert self._is_nonneg_int(self.unit_id)

        # Validate `unit_channel`
        assert self.unit_id.shape == (self.n_units,)
        assert self._is_nonneg_int(self.unit_id)

        # Validate `unit_quality`
        assert self.unit_id.shape == (self.n_units,)

        # Validate `unit_waveform_uv`, `unit_waveform_time`, `unit_waveform_norm_shift`
        nt_waveform = self.unit_waveform_time.shape[0]
        assert self.unit_waveform_time.shape == (nt_waveform,)
        assert self.unit_waveform_uv.shape == (nt_waveform, self.n_units)
        assert self.unit_waveform_norm_shift.shape == (nt_waveform, self.n_units)

        # Validate `stimulus_files`
        indices_all = np.arange(len(self.stimulus_files))
        indices_used = np.unique(self.stimulus_index_valid)
        assert np.all(np.isin(indices_used, indices_all))

        # Validate `stimulus_index_valid`
        assert self.stimulus_index_valid.shape == (self.n_trials,)
        assert self._is_nonneg_int(self.timecourse_all_units)

        # Validate `timecourse_all_units`
        assert self.timecourse_all_units.shape == (self.n_time, self.n_units)
        assert self._is_nonneg_int(self.timecourse_all_units)

        # Validate `on_durations`
        assert self.on_durations.shape == (self.n_trials,)
        assert self._is_nonneg_int(self.on_durations)

        # Validate `off_durations`
        assert self.off_durations.shape == (self.n_trials,)
        # assert(self._is_nonneg_int(self.off_durations)) # TODO: Find out why some of these are negative

        # Validate `trial_durations`
        assert self.trial_durations.shape == (self.n_trials,)
        assert self._is_nonneg_int(self.trial_durations)
        # assert(np.all((self.on_durations + self.off_durations) == self.trial_durations))

        # Validate `timecourse_on_times`
        assert self.timecourse_on_times.shape == (self.n_trials,)
        assert self._is_nonneg_int(self.timecourse_on_times)
        assert np.all(self.timecourse_on_times < self.n_time)
        assert np.all(np.diff(self.timecourse_on_times) == self.trial_durations[:-1])

        # TODO: Figure out why some datasets don't pass this test!
        # Validate `timecourse_off_times`
        assert self.timecourse_off_times.shape == (self.n_trials,)
        #if not np.all(self.timecourse_off_times <= self.n_time):
        #    idx = np.argwhere(self.timecourse_off_times >= self.n_time)
        #    print(self.n_time)
        #    print(idx)
        #    print(self.timecourse_off_times[idx])
        #    print(self.session_index)
        #    print(self.paradigm_abbr)
        #assert np.all(self.timecourse_off_times <= self.n_time)
        assert self._is_nonneg_int(self.timecourse_off_times)

        # TODO: Figure out why some datasets don't pass this test!
        # Validate `timecourse_on_times_ks`
        assert self.timecourse_on_times_ks.shape == (self.n_trials,)
        assert np.issubdtype(self.timecourse_on_times_ks.dtype, np.floating)
        assert np.all(np.isfinite(self.timecourse_on_times_ks))
        # assert np.all(self.timecourse_on_times_ks >= 0)

        # Validate `eyex_timecourse`
        assert self.eyex_timecourse.shape == (self.n_time,)

        # Validate `eyey_timecourse`
        assert self.eyey_timecourse.shape == (self.n_time,)

    @property
    def trial_bounds(self):
        """List of (start time, stop time) pairs for all trials."""

        # Time point where each trial starts (inclusive)
        start_times = self.timecourse_on_times

        # Time point where each trial stops (exclusive)
        stop_times = np.append(self.timecourse_on_times[1:], self.n_time)

        return list(zip(start_times.tolist(), stop_times.tolist(), strict=True))

    @property
    def spike_trials(self):
        """List of spike matrices for each trial in paradigm."""

        return [self.timecourse_all_units[a:b, :] for a, b in self.trial_bounds]

    @property
    def eyex_timecourse_trials(self):
        """List of arrays of eye tracking x-values for each trial in paradigm."""

        return [self.eyex_timecourse[a:b] for a, b in self.trial_bounds]

    @property
    def eyey_timecourse_trials(self):
        """List of arrays of eye tracking y-values for each trial in paradigm."""

        return [self.eyey_timecourse[a:b] for a, b in self.trial_bounds]


# ----------------------------------------------------------------------------------------
# File name parsing methods
# ----------------------------------------------------------------------------------------


def paradigm_full_to_abbr(full_name: str) -> str:
    """Get abbreviation used for full paradigm name.

    Args:
        full_name: str
            Full name of paradigm used in raw data file
    Returns:
        abbr: str
            Abbreviation used for directory names and scripts
    Raises:
        ValueError
            If 'full_name' does not have an abbreviation
    """

    try:
        return PARADIGM_ABBR[full_name]
    except KeyError:
        raise ValueError(f"Paradigm '{full_name}' is not supported")


def paradigm_abbr_to_full(abbr: str) -> str:
    """Get full name of paradigm with given abbreviation.

    Args:
        full_name: str
            Full name of paradigm used in raw data file
    Returns:
        abbr: str
            Abbreviation used for directory names and scripts
    Raises:
        ValueError
            If 'abbr' does not have a full name
    """

    try:
        return PARADIGM_ABBR_INV[abbr]
    except KeyError:
        raise ValueError(f"Abbreviation '{abbr}' is not supported")


def get_session_animal(session_name: str) -> str:
    """Parse name of animal from session name.

    Args:
        session_name: str
            Name of session, for example '210803_133520_Alfie'
    Returns:
        animal: str
            Name of animal, for example 'Alfie'

    """

    return session_name[14:]


def get_session_datetime(session_name: str) -> datetime:
    """Parse datetime of session from session name.

    Args:
        session_name: str
            Name of session, for example '210803_133520_Alfie'
    Returns:
        dt: datetime.datetime
            Session datetime, for example datetime('2021-08-03 13:35:20')

    """

    dt_string = session_name[:13]
    return datetime.strptime(dt_string, '%y%m%d_%H%M%S')


def get_dset_name(
    session: str, paradigm: str, probe: int, run: int | None = None
) -> str:
    """Get name for dataset based on attributes."""

    if run is None:
        return f'{session}_{paradigm}_p{probe}'
    else:
        return f'{session}_{paradigm}_p{probe}_r{run}'


def parse_dset_name(dset_name: str) -> dict:
    """Extract session abbreviation, paradigm, probe, and run from dataset name.

    Examples:
    - 's005_pss_p1_r1' -> {'session':'s005', 'paradigm':'pss', 'probe':1, 'run':1}
    - 's005_pss_p1' -> {'session':'s005', 'paradigm':'pss', 'probe':1, 'run':None}

    Args:
        dset_name: str
            Name of dataset
    Returns:
        data: dict containing elements
            'session': str
                Session abbreviation
            'paradigm': str
                Paradigm abbreviation
            'probe': int
                Probe
            'run': int | None
                Run (None if there isn't a run)
    """

    # Find paradigm string in name and keep track of position
    pdm_index = -1
    paradigm = None
    for pdm in PARADIGM_ABBR.values():
        pdm_index = dset_name.find(f'_{pdm}_')
        if pdm_index != -1:
            paradigm = pdm
            break
    if paradigm is None:
        raise ValueError("Dataset name doesn't contain paradigm")

    # Extract session string
    session = dset_name[0:pdm_index]

    # Extract probe number
    probe_index = pdm_index + len(paradigm) + 3
    probe = int(dset_name[probe_index])

    # Extract run (if present)
    if len(dset_name) == (probe_index + 1):
        run = None
    else:
        run_index = probe_index + 3
        run = int(dset_name[run_index])

    return {'session': session, 'probe': probe, 'paradigm': paradigm, 'run': run}


def get_recording_name(session: str, probe: int) -> str:
    """Get name for recording based on attributes."""

    return f'{session}_p{probe}'


def parse_recording_name(rec_name: str) -> dict:
    """Extract session abbreviation and probe from recording name.

    Examples:
    - 's005_p1' -> {'session':'s005', 'probe':1}

    Args:
        rec_name: str
            Name of recording
    Returns:
        data: dict containing elements
            'session': str
                Session abbreviation
            'probe': int
                Probe
    """

    # Check formatting
    if rec_name[-3:-1] != '_p':
        raise ValueError('Recording name not correctly formatted')

    # Probe number is last character in string
    probe = int(rec_name[-1])

    # Session is part of string before '_p'
    session = rec_name[:-3]

    return {'session': session, 'probe': probe}


# -----------------------------------------------------------------------------------------
# Methods for extracting, loading, and saving Paradigm, Session, and Dataset objects
# -----------------------------------------------------------------------------------------


def load_paradigm_h5(g: h5py.Group) -> Paradigm:
    """Load Paradigm object from HDF5 group.

    Args:
        g: h5py.Group
            Pointer to HDF5 group in open h5py.File object to load paradigm from
    Returns:
        pd: Paradigm
            Paradigm object containing data from group.
    """

    # Data that will be used to create Session object
    data = {}

    # Load paradigm fields
    data['paradigm_name'] = str(g.attrs['paradigm_name'])
    data['paradigm_abbr'] = paradigm_full_to_abbr(data['paradigm_name'])
    data['stimulus_files'] = g['stimulus_files'].asstr()[:].flatten().tolist()
    data['stimulus_index_valid'] = np.array(g['stimulus_index_valid']).flatten()
    data['timecourse_all_units'] = np.array(g['timecourse_all_units'])
    data['on_duration'] = int(g.attrs['on_duration'].item())
    data['off_duration'] = int(g.attrs['off_duration'].item())
    data['on_durations'] = np.array(g['on_durations']).flatten()
    data['off_durations'] = np.array(g['off_durations']).flatten()
    data['trial_durations'] = np.array(g['trial_durations']).flatten()
    data['timecourse_on_times'] = np.array(g['timecourse_on_times']).flatten()
    data['timecourse_off_times'] = np.array(g['timecourse_off_times']).flatten()
    data['timecourse_on_times_ks'] = np.array(g['timecourse_on_times_ks']).flatten()
    data['eyex_timecourse'] = np.array(g['eyex_timecourse']).flatten()
    data['eyey_timecourse'] = np.array(g['eyey_timecourse']).flatten()

    # Photodiode timecourse is optional
    if 'photodiode_timecourse' in g.keys():
        data['photodiode_timecourse'] = np.array(g['photodiode_timecourse']).flatten()

    # Get number of trials and number of time points from other fields
    data['n_trials'] = data['stimulus_index_valid'].shape[0]
    data['n_time'] = data['timecourse_all_units'].shape[0]

    # Stimulus labels for physical switches paradigms
    if data['paradigm_abbr'] in ['pss', 'psst', 'psn', 'psnt']:
        data['trial_is_face'] = np.array(g['trial_is_face']).flatten()
        data['trial_is_object'] = np.array(g['trial_is_object']).flatten()

    # Fixation points and percept labels for no-report paradigms
    if data['paradigm_abbr'] in ['brn', 'brnt', 'psn', 'psnt']:
        data['fix_positions'] = np.array(g['fix_positions'])
        data['face_fix_positions_index'] = np.array(g['face_fix_positions_index']).flatten()
        data['object_fix_positions_index'] = np.array(g['object_fix_positions_index']).flatten()
        data['trials_fixated'] = np.array(g['trials_fixated']).flatten()
        data['trials_fixated_face'] = np.array(g['trials_fixated_face']).flatten()
        data['trials_fixated_object'] = np.array(g['trials_fixated_object']).flatten()
        data['good_face_trial'] = np.array(g['good_face_trial']).flatten()
        data['good_object_trial'] = np.array(g['good_object_trial']).flatten()

    return Paradigm(**data)


def load_session_h5(fpath: Path) -> Session:
    """Load session data from HDF5 file.

    Args:
        fpath: Path
            Path to HDF5 file containing session data
    Returns:
        session: Session
            Data from file loaded into Session object
    """

    # Dictionary for data that will be used to create Session object
    data = {}

    with h5py.File(fpath) as f:
        # Extract animal and timestamp from session name
        session_name = str(f.attrs['session_name'])
        data['session_name'] = session_name
        data['animal'] = get_session_animal(session_name)
        data['timestamp'] = get_session_datetime(session_name)

        # Load other fields
        data['session_index'] = int(f.attrs['session_index'].item())
        data['acquisition_software'] = f.attrs['acquisition_software']
        data['regions'] = tuple(f.attrs['regions'].tolist())
        data['layer_direction'] = f.attrs['layer_direction'].tolist()
        data['n_probes'] = int(f.attrs['n_probes'].item())
        data['n_units'] = int(f.attrs['n_units'].item())
        data['unit_id'] = np.array(f['/unit_id']).flatten()
        data['unit_channel'] = np.array(f['/unit_channel']).flatten()
        data['unit_probe'] = np.array(f['/unit_probe']).flatten()
        data['unit_quality'] = np.array(f['/unit_quality']).flatten()
        data['unit_waveform_uv'] = np.array(f['/unit_waveform_uv'])
        data['unit_waveform_time'] = np.array(f['/unit_waveform_time']).flatten()
        data['unit_waveform_norm_shift'] = np.array(f['/unit_waveform_norm_shift'])

        # Paradigms
        data['paradigms'] = {}
        paradigm_names = list(f['/paradigms'].keys())
        for pd_name in paradigm_names:
            # Load paradigm
            pd_group_path = f'/paradigms/{pd_name}'
            pd_group = f[pd_group_path]
            pd = load_paradigm_h5(pd_group)

            # Save in dict with abbreviation as key
            data['paradigms'][pd.paradigm_abbr] = pd

    return Session(**data)


def save_paradigm_h5(g: h5py.Group, paradigm: Paradigm) -> None:
    """Save a Paradigm object to an HDF5 group.

    Args:
        g: h5py.Group
            HDF5 group to save paradigm data to
        paradigm: Paradigm
            Paradigm data to save
    """

    # Save attributes
    g.attrs['paradigm_name'] = paradigm.paradigm_name
    g.attrs['on_duration'] = paradigm.on_duration
    g.attrs['off_duration'] = paradigm.off_duration

    # Save datasets
    g.create_dataset(
        'stimulus_files',
        data=np.array(paradigm.stimulus_files, dtype=h5py.string_dtype()),
    )
    g.create_dataset('stimulus_index_valid', data=paradigm.stimulus_index_valid)
    g.create_dataset('timecourse_all_units', data=paradigm.timecourse_all_units)
    g.create_dataset('on_durations', data=paradigm.on_durations)
    g.create_dataset('off_durations', data=paradigm.off_durations)
    g.create_dataset('trial_durations', data=paradigm.trial_durations)
    g.create_dataset('timecourse_on_times', data=paradigm.timecourse_on_times)
    g.create_dataset('timecourse_off_times', data=paradigm.timecourse_off_times)
    g.create_dataset('timecourse_on_times_ks', data=paradigm.timecourse_on_times_ks)
    g.create_dataset('eyex_timecourse', data=paradigm.eyex_timecourse)
    g.create_dataset('eyey_timecourse', data=paradigm.eyey_timecourse)

    # Photodiode timecourse is optional
    if paradigm.photodiode_timecourse is not None:
        g.create_dataset('photodiode_timecourse', data=paradigm.photodiode_timecourse)

    # Save paradigm-specific fields for physical switches paradigms
    if paradigm.paradigm_abbr in ['pss', 'psst', 'psn', 'psnt']:
        if paradigm.trial_is_face is not None:
            g.create_dataset('trial_is_face', data=paradigm.trial_is_face)
        if paradigm.trial_is_object is not None:
            g.create_dataset('trial_is_object', data=paradigm.trial_is_object)

    # Save paradigm-specific fields for no-report paradigms
    if paradigm.paradigm_abbr in ['brn', 'brnt']:
        if paradigm.trials_fixated is not None:
            g.create_dataset('trials_fixated', data=paradigm.trials_fixated)
        if paradigm.trials_fixated_face is not None:
            g.create_dataset('trials_fixated_face', data=paradigm.trials_fixated_face)
        if paradigm.trials_fixated_object is not None:
            g.create_dataset(
                'trials_fixated_object', data=paradigm.trials_fixated_object
            )
        if paradigm.good_face_trial is not None:
            g.create_dataset('good_face_trial', data=paradigm.good_face_trial)
        if paradigm.good_object_trial is not None:
            g.create_dataset('good_object_trial', data=paradigm.good_object_trial)


def save_session_h5(session: Session, fpath: Path) -> None:
    """Save a Session object to an HDF5 file.

    Args:
        session: Session object to save
        fpath: Path where the HDF5 file will be saved
    """

    with h5py.File(fpath, 'w') as f:
        # Save session-level attributes
        f.attrs['session_name'] = session.session_name
        f.attrs['session_index'] = session.session_index
        f.attrs['acquisition_software'] = session.acquisition_software
        f.attrs['regions'] = np.array(session.regions, dtype=h5py.string_dtype())
        f.attrs['layer_direction'] = session.layer_direction
        f.attrs['n_probes'] = session.n_probes
        f.attrs['n_units'] = session.n_units

        # Save unit-level datasets
        f.create_dataset('/unit_id', data=session.unit_id)
        f.create_dataset('/unit_channel', data=session.unit_channel)
        f.create_dataset('/unit_probe', data=session.unit_probe)
        f.create_dataset('/unit_quality', data=session.unit_quality)
        f.create_dataset('/unit_waveform_uv', data=session.unit_waveform_uv)
        f.create_dataset('/unit_waveform_time', data=session.unit_waveform_time)
        f.create_dataset(
            '/unit_waveform_norm_shift', data=session.unit_waveform_norm_shift
        )

        # Create paradigms group
        paradigms_group = f.create_group('/paradigms')

        # Save each paradigm
        for paradigm in session.paradigms.values():
            pd_group = paradigms_group.create_group(paradigm.paradigm_name)
            save_paradigm_h5(pd_group, paradigm)


def load_dataset_npz(fpath: Path) -> Dataset:
    """Load a Dataset object from a NumPy .npz file.

    Args:
        fpath: Path to the .npz file to load
    Returns:
        Dataset object loaded from the file
    """

    # Load the .npz file
    data_npz = np.load(fpath, allow_pickle=True)

    # Dictionary to hold all data for Dataset constructor
    data = {}

    # Load scalar and simple fields
    data['session_name'] = str(data_npz['session_name'].item())
    data['session_index'] = int(data_npz['session_index'].item())
    data['animal'] = str(data_npz['animal'].item())
    data['timestamp'] = datetime.fromisoformat(str(data_npz['timestamp'].item()))
    data['acquisition_software'] = str(data_npz['acquisition_software'].item())
    data['n_units'] = int(data_npz['n_units'].item())
    data['region'] = str(data_npz['region'].item())
    data['layer_direction'] = int(data_npz['layer_direction'].item())
    trial_range_arr = data_npz['orig_trial_range']
    data['orig_trial_range'] = (int(trial_range_arr[0]), int(trial_range_arr[1]))

    # Load unit-level arrays
    data['unit_id'] = data_npz['unit_id']
    data['unit_channel'] = data_npz['unit_channel']
    data['unit_quality'] = data_npz['unit_quality']
    data['unit_waveform_uv'] = data_npz['unit_waveform_uv']
    data['unit_waveform_time'] = data_npz['unit_waveform_time']
    data['unit_waveform_norm_shift'] = data_npz['unit_waveform_norm_shift']

    # Load paradigm fields
    data['paradigm_name'] = str(data_npz['paradigm_name'].item())
    data['paradigm_abbr'] = str(data_npz['paradigm_abbr'].item())
    data['n_trials'] = int(data_npz['n_trials'].item())
    data['n_time'] = int(data_npz['n_time'].item())
    data['stimulus_files'] = data_npz['stimulus_files'].tolist()
    data['stimulus_index_valid'] = data_npz['stimulus_index_valid']
    data['timecourse_all_units'] = data_npz['timecourse_all_units']
    data['on_duration'] = int(data_npz['on_duration'].item())
    data['off_duration'] = int(data_npz['off_duration'].item())
    data['on_durations'] = data_npz['on_durations']
    data['off_durations'] = data_npz['off_durations']
    data['trial_durations'] = data_npz['trial_durations']
    data['timecourse_on_times'] = data_npz['timecourse_on_times']
    data['timecourse_off_times'] = data_npz['timecourse_off_times']
    data['timecourse_on_times_ks'] = data_npz['timecourse_on_times_ks']
    data['eyex_timecourse'] = data_npz['eyex_timecourse']
    data['eyey_timecourse'] = data_npz['eyey_timecourse']

    # Load optional fields
    if 'photodiode_timecourse' in data_npz:
        data['photodiode_timecourse'] = data_npz['photodiode_timecourse']
    if 'trial_is_face' in data_npz:
        data['trial_is_face'] = data_npz['trial_is_face']
    if 'trial_is_object' in data_npz:
        data['trial_is_object'] = data_npz['trial_is_object']
    if 'trials_fixated' in data_npz:
        data['trials_fixated'] = data_npz['trials_fixated']
    if 'trials_fixated_face' in data_npz:
        data['trials_fixated_face'] = data_npz['trials_fixated_face']
    if 'trials_fixated_object' in data_npz:
        data['trials_fixated_object'] = data_npz['trials_fixated_object']
    if 'good_face_trial' in data_npz:
        data['good_face_trial'] = data_npz['good_face_trial']
    if 'good_object_trial' in data_npz:
        data['good_object_trial'] = data_npz['good_object_trial']

    return Dataset(**data)


def save_dataset_npz(dataset: Dataset, fpath: Path) -> None:
    """Save a Dataset object to a NumPy .npz file.

    Args:
        dataset: Dataset object to save
        fpath: Path where the .npz file will be saved
    """

    # Dictionary to hold all data to save
    save_dict = {}

    # Save scalar and simple fields as arrays or pickled objects
    save_dict['session_name'] = np.array(dataset.session_name, dtype=object)
    save_dict['session_index'] = np.array(dataset.session_index)
    save_dict['animal'] = np.array(dataset.animal, dtype=object)
    save_dict['timestamp'] = np.array(dataset.timestamp.isoformat(), dtype=object)
    save_dict['acquisition_software'] = np.array(
        dataset.acquisition_software, dtype=object
    )
    save_dict['n_units'] = np.array(dataset.n_units)
    save_dict['region'] = np.array(dataset.region, dtype=object)
    save_dict['layer_direction'] = np.array(dataset.layer_direction)
    save_dict['orig_trial_range'] = np.array(dataset.orig_trial_range)

    # Save unit-level arrays
    save_dict['unit_id'] = dataset.unit_id
    save_dict['unit_channel'] = dataset.unit_channel
    save_dict['unit_quality'] = dataset.unit_quality
    save_dict['unit_waveform_uv'] = dataset.unit_waveform_uv
    save_dict['unit_waveform_time'] = dataset.unit_waveform_time
    save_dict['unit_waveform_norm_shift'] = dataset.unit_waveform_norm_shift

    # Save paradigm fields
    save_dict['paradigm_name'] = np.array(dataset.paradigm_name, dtype=object)
    save_dict['paradigm_abbr'] = np.array(dataset.paradigm_abbr, dtype=object)
    save_dict['n_trials'] = np.array(dataset.n_trials)
    save_dict['n_time'] = np.array(dataset.n_time)
    save_dict['stimulus_files'] = np.array(dataset.stimulus_files, dtype=object)
    save_dict['stimulus_index_valid'] = dataset.stimulus_index_valid
    save_dict['timecourse_all_units'] = dataset.timecourse_all_units
    save_dict['on_duration'] = np.array(dataset.on_duration)
    save_dict['off_duration'] = np.array(dataset.off_duration)
    save_dict['on_durations'] = dataset.on_durations
    save_dict['off_durations'] = dataset.off_durations
    save_dict['trial_durations'] = dataset.trial_durations
    save_dict['timecourse_on_times'] = dataset.timecourse_on_times
    save_dict['timecourse_off_times'] = dataset.timecourse_off_times
    save_dict['timecourse_on_times_ks'] = dataset.timecourse_on_times_ks
    save_dict['eyex_timecourse'] = dataset.eyex_timecourse
    save_dict['eyey_timecourse'] = dataset.eyey_timecourse

    # Save optional fields
    if dataset.photodiode_timecourse is not None:
        save_dict['photodiode_timecourse'] = dataset.photodiode_timecourse
    if dataset.trial_is_face is not None:
        save_dict['trial_is_face'] = dataset.trial_is_face
    if dataset.trial_is_object is not None:
        save_dict['trial_is_object'] = dataset.trial_is_object
    if dataset.trials_fixated is not None:
        save_dict['trials_fixated'] = dataset.trials_fixated
    if dataset.trials_fixated_face is not None:
        save_dict['trials_fixated_face'] = dataset.trials_fixated_face
    if dataset.trials_fixated_object is not None:
        save_dict['trials_fixated_object'] = dataset.trials_fixated_object
    if dataset.good_face_trial is not None:
        save_dict['good_face_trial'] = dataset.good_face_trial
    if dataset.good_object_trial is not None:
        save_dict['good_object_trial'] = dataset.good_object_trial

    # Save to .npz file
    np.savez_compressed(fpath, **save_dict)


def session_select_units(session: Session, units: np.ndarray) -> Session:
    """Select subset of units in Session object.

    Args:
        session: Original Session object to select from
        units: All units to select

    Returns:
        session_new: Session object with subset of units selected.
    """

    # Fields unaffected by unit change
    data = {}
    data['session_name'] = session.session_name
    data['session_index'] = session.session_index
    data['animal'] = session.animal
    data['timestamp'] = session.timestamp
    data['acquisition_software'] = session.acquisition_software
    data['n_probes'] = session.n_probes
    data['regions'] = session.regions
    data['layer_direction'] = session.layer_direction
    data['unit_waveform_time'] = session.unit_waveform_time

    # Fields that need to be altered
    data['n_units'] = units.shape[0]
    data['unit_id'] = session.unit_id[units]
    data['unit_channel'] = session.unit_channel[units]
    data['unit_probe'] = session.unit_probe[units]
    data['unit_quality'] = session.unit_quality[units]
    data['unit_waveform_uv'] = session.unit_waveform_uv[:, units]
    data['unit_waveform_norm_shift'] = session.unit_waveform_norm_shift[:, units]

    # Paradigms
    data['paradigms'] = {}
    for pd_abbr, pd in session.paradigms.items():
        # Fields unaffected by unit change
        pd_data = {}
        pd_data['paradigm_name'] = pd.paradigm_name
        pd_data['paradigm_abbr'] = pd.paradigm_abbr
        pd_data['n_trials'] = pd.n_trials
        pd_data['n_time'] = pd.n_time
        pd_data['stimulus_files'] = pd.stimulus_files
        pd_data['stimulus_index_valid'] = pd.stimulus_index_valid
        pd_data['on_duration'] = pd.on_duration
        pd_data['off_duration'] = pd.off_duration
        pd_data['on_durations'] = pd.on_durations
        pd_data['off_durations'] = pd.off_durations
        pd_data['trial_durations'] = pd.trial_durations
        pd_data['timecourse_on_times'] = pd.timecourse_on_times
        pd_data['timecourse_off_times'] = pd.timecourse_off_times
        pd_data['timecourse_on_times_ks'] = pd.timecourse_on_times_ks
        pd_data['eyex_timecourse'] = pd.eyex_timecourse
        pd_data['eyey_timecourse'] = pd.eyey_timecourse
        if pd.photodiode_timecourse is not None:
            pd_data['photodiode_timecourse'] = pd.photodiode_timecourse
        if pd.trial_is_face is not None:
            pd_data['trial_is_face'] = pd.trial_is_face
        if pd.trial_is_object is not None:
            pd_data['trial_is_object'] = pd.trial_is_object
        if pd.trials_fixated is not None:
            pd_data['trials_fixated'] = pd.trials_fixated
        if pd.trials_fixated_face is not None:
            pd_data['trials_fixated_face'] = pd.trials_fixated_face
        if pd.trials_fixated_object is not None:
            pd_data['trials_fixated_object'] = pd.trials_fixated_object
        if pd.good_face_trial is not None:
            pd_data['good_face_trial'] = pd.good_face_trial
        if pd.good_object_trial is not None:
            pd_data['good_object_trial'] = pd.good_object_trial

        # Only spike matrix needs to be altered
        pd_data['timecourse_all_units'] = pd.timecourse_all_units[:, units]

        data['paradigms'][pd_abbr] = Paradigm(**pd_data)

    return Session(**data)


def session_select_probe(session: Session, probe: int) -> Session:
    """Select probe in Session object.

    Args:
        session: Original Session object to select from
        probe: Probe number to seelct

    Returns:
        session_new: Session object only with data from given probe.
    """

    # Check that probe to select is in list of session probes
    assert np.isin(probe, np.unique(session.unit_probe))

    # Indices of all units on selected probe
    probe_units = np.argwhere(session.unit_probe == probe).flatten()

    return session_select_units(session, probe_units)


def extract_dataset(
    session: Session,
    probe: int,
    paradigm_abbr: str,
    trial_range: tuple[int, int] | None = None,
) -> Dataset:
    """Extract subset of data from Session object and store in Dataset object.

    Args:
        session: Session object to extract from
        probe: Probe to extract
        paradigm_abbr: Abbreviation of paradigm to extract
        trial_range: Range of trials to extract (if None, all trials are extracted)

    Returns:
        dataset: Dataset object with subset of extracted data.
    """

    # Make sure probe is positive number
    assert probe >= 1
    probe_python_index = probe - 1

    # Select probe of interest from session
    session = session_select_probe(session, probe)

    # Unchanged session fields
    data = {}
    data['session_name'] = session.session_name
    data['session_index'] = session.session_index
    data['animal'] = session.animal
    data['timestamp'] = session.timestamp
    data['acquisition_software'] = session.acquisition_software
    data['n_units'] = session.n_units
    data['unit_id'] = session.unit_id
    data['unit_channel'] = session.unit_channel
    data['unit_quality'] = session.unit_quality
    data['unit_waveform_uv'] = session.unit_waveform_uv
    data['unit_waveform_time'] = session.unit_waveform_time
    data['unit_waveform_norm_shift'] = session.unit_waveform_norm_shift

    # New or modified fields
    data['region'] = session.regions[probe_python_index]
    data['layer_direction'] = session.layer_direction[probe_python_index]

    # Paradigm object
    pd = session.paradigms[paradigm_abbr]

    # Unchanged paradigm fields
    data['paradigm_name'] = pd.paradigm_name
    data['paradigm_abbr'] = pd.paradigm_abbr
    data['stimulus_files'] = pd.stimulus_files
    data['on_duration'] = pd.on_duration
    data['off_duration'] = pd.off_duration

    # Range of trials to extract
    if trial_range is None:
        trial_start = 0
        trial_stop = pd.n_trials
    else:
        trial_start, trial_stop = trial_range

    # Range of time points to extract
    time_start = pd.trial_bounds[trial_start][0]  # beginning of first trial
    time_stop = pd.trial_bounds[trial_stop - 1][1]  # end of last trial

    # Number of trials and time points change
    data['n_trials'] = trial_stop - trial_start
    data['n_time'] = time_stop - time_start

    # Extract trial range from per-trial variables
    trial_slice = slice(trial_start, trial_stop)
    data['stimulus_index_valid'] = pd.stimulus_index_valid[trial_slice]
    data['on_durations'] = pd.on_durations[trial_slice]
    data['off_durations'] = pd.off_durations[trial_slice]
    data['trial_durations'] = pd.trial_durations[trial_slice]
    if pd.trial_is_face is not None:
        data['trial_is_face'] = pd.trial_is_face[trial_slice]
    if pd.trial_is_object is not None:
        data['trial_is_object'] = pd.trial_is_object[trial_slice]
    if pd.trials_fixated is not None:
        data['trials_fixated'] = pd.trials_fixated
    if pd.trials_fixated_face is not None:
        data['trials_fixated_face'] = pd.trials_fixated_face[trial_slice]
    if pd.trials_fixated_object is not None:
        data['trials_fixated_object'] = pd.trials_fixated_object[trial_slice]
    if pd.good_face_trial is not None:
        data['good_face_trial'] = pd.good_face_trial[trial_slice]
    if pd.good_object_trial is not None:
        data['good_object_trial'] = pd.good_object_trial[trial_slice]

    # Need to adjust time variables to account for new start time
    data['timecourse_on_times'] = pd.timecourse_on_times[trial_slice] - time_start
    data['timecourse_off_times'] = pd.timecourse_off_times[trial_slice] - time_start
    data['timecourse_on_times_ks'] = pd.timecourse_on_times_ks[trial_slice] - time_start

    # Extract time range from timecourse variables
    time_slice = slice(time_start, time_stop)
    data['timecourse_all_units'] = pd.timecourse_all_units[time_slice, :]
    data['eyex_timecourse'] = pd.eyex_timecourse[time_slice]
    data['eyey_timecourse'] = pd.eyey_timecourse[time_slice]
    if pd.photodiode_timecourse is not None:
        data['photodiode_timecourse'] = pd.photodiode_timecourse[time_slice]

    # Add trial range to data
    data['orig_trial_range'] = (trial_start, trial_stop)

    return Dataset(**data)


# -----------------------------------------------------------------------------------------
# Methods for handling spike-sorting files (not used anymore)
# -----------------------------------------------------------------------------------------


def load_cluster_info_file(fpath: str) -> dict:
    """Load data from Phy-generated cluster info file.

    Args:
        fpath: str
            Path to cluster info file

    Returns:
        out_data: dict
            'mua_units': np.ndarray[int, (N,)]
                Unit IDs of MUA units
            'good_units': np.ndarray[int, (N,)]
                Unit IDs of good units

    """

    df = pd.read_csv(fpath, sep='\t', header=0)
    out_data = {}
    out_data['mua_units'] = df[df.group == 'mua'].cluster_id.values
    out_data['good_units'] = df[df.group == 'good'].cluster_id.values

    return out_data


def load_unit_labels_file(fpath: str) -> dict:
    """Load data from manually created unit labels file.

    Args:
        fpath: str
            Path to unit labels file

    Returns:
        out_data: dict
            'safetags_units': np.ndarray[int, (N,)]
                Unit IDs with safetags labels
            'safetags_start': np.ndarray[int, (N,)]
                Start times of safe interval for units
            'safetags_end': np.ndarray[int, (N,)]
                End times of safe interval for units
            'ps_units': np.ndarray[int, (M,)]
                Unit IDs of positive spiking units
            'ts_units': np.ndarray[int, (L,)]
                Unit IDs of triphasic spiking units

    """

    out_data = {}

    # Load file into dataframe, making sure safetag labels are integers
    df = pd.read_csv(fpath, sep=', ', header=0, engine='python')
    df.start.fillna(-1, inplace=True)
    df.start = df.start.astype(int)
    df.end.fillna(-1, inplace=True)
    df.end = df.end.astype(int)

    # Extract safetags data
    df_safetags = df[(df.start != 0) | (df.end != -1)]
    out_data['safetags_units'] = df_safetags.id.values
    out_data['safetags_start'] = df_safetags.start.values
    out_data['safetags_end'] = df_safetags.end.values

    # Extract waveform labels
    out_data['ps_units'] = df[df.type == 'ps'].id.values
    out_data['ts_units'] = df[df.type == 'ts'].id.values

    # TODO: Extract unit labels (need to figure out how to reconcile these with labels
    # from cluster_info.tsv file)

    return out_data
