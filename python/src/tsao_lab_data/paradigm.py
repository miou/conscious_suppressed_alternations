"""Paradigm class."""

from abc import ABC, abstractmethod
from dataclasses import dataclass
from typing import ClassVar, Self

import numpy as np
import h5py


@dataclass
class Paradigm(ABC):
    """Class containing data for single paradigm (i.e. task) in Tsao lab session."""

    # Paradigm name (determined by subclass)
    paradigm_name: ClassVar[str]

    # Paradigm abbreviation (also determined by subclass)
    paradigm_abbr: ClassVar[str]

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

    def __post_init__(self):
        """Validate object fields after initialization."""

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
        assert self._is_nonneg_int(self.stimulus_index_valid)

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
        # if not np.all(self.timecourse_off_times <= self.n_time):
        #    idx = np.argwhere(self.timecourse_off_times >= self.n_time)
        #    print(self.n_time)
        #    print(idx)
        #    print(self.timecourse_off_times[idx])
        #    print(self.paradigm_abbr)
        # assert np.all(self.timecourse_off_times <= self.n_time)
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

    @classmethod
    def concrete_subclasses(cls) -> list[type['Paradigm']]:
        """Return all concrete Paradigm subclasses (those with paradigm_name defined)."""

        def _walk(c):
            for sub in c.__subclasses__():
                yield sub
                yield from _walk(sub)

        return [c for c in _walk(cls) if 'paradigm_name' in c.__dict__]

    @classmethod
    def _check_paradigm_name(cls, g: h5py.Group) -> None:
        """Raise exception if paradigm name in H5 group differs from Paradigm subclass."""

        if g.attrs['paradigm_name'] != cls.paradigm_name:
            raise ValueError(
                f"Paradigm name in H5 group ('{g.attrs['paradigm_name']}') "
                f"does not match subclass ('{cls.paradigm_name}')"
            )

    @classmethod
    def _load_common_fields_h5(cls, g: h5py.Group, units: np.ndarray | None = None) -> dict:
        """Load fields common to all Paradigm objects from HDF5 Group."""

        # Dict for storing and returning data
        data = {}

        # Load fields common to all paradigms
        data['stimulus_files'] = g['stimulus_files'].asstr()[:].flatten().tolist()
        data['stimulus_index_valid'] = np.array(g['stimulus_index_valid']).flatten()
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

        # Load spike timecourse (if subset of units is specified, only load those)
        if units is None:
            data['timecourse_all_units'] = np.array(g['timecourse_all_units'])
        else:
            data['timecourse_all_units'] = np.array(g['timecourse_all_units'][:, units])

        # Get number of trials and number of time points from other fields
        data['n_trials'] = data['stimulus_index_valid'].shape[0]
        data['n_time'] = data['timecourse_all_units'].shape[0]

        return data

    @classmethod
    @abstractmethod
    def from_h5(cls, g: h5py.Group, units: np.ndarray | None = None) -> Self:
        """Load Paradigm object from HDF5 file."""

        pass

    def to_h5(self, g: h5py.Group) -> None:
        """Save fields common to all Paradigm objects to HDF5 Group."""

        # Save attributes
        g.attrs['paradigm_name'] = self.paradigm_name
        g.attrs['on_duration'] = self.on_duration
        g.attrs['off_duration'] = self.off_duration

        # Save datasets
        g.create_dataset(
            'stimulus_files',
            data=np.array(self.stimulus_files, dtype=h5py.string_dtype()),
        )
        g.create_dataset('stimulus_index_valid', data=self.stimulus_index_valid)
        g.create_dataset('timecourse_all_units', data=self.timecourse_all_units)
        g.create_dataset('on_durations', data=self.on_durations)
        g.create_dataset('off_durations', data=self.off_durations)
        g.create_dataset('trial_durations', data=self.trial_durations)
        g.create_dataset('timecourse_on_times', data=self.timecourse_on_times)
        g.create_dataset('timecourse_off_times', data=self.timecourse_off_times)
        g.create_dataset('timecourse_on_times_ks', data=self.timecourse_on_times_ks)
        g.create_dataset('eyex_timecourse', data=self.eyex_timecourse)
        g.create_dataset('eyey_timecourse', data=self.eyey_timecourse)

    def select_units(self, units: np.ndarray) -> None:
        """Drop all units not in list from this Paradigm object."""

        # Validate units array
        assert units.shape[0] > 0

        # If units in list are a contiguous range, then use simple indexing for speed
        unit_start = np.min(units)
        unit_stop = np.max(units) + 1
        unit_range = np.arange(unit_start, unit_stop)
        if (units.shape[0] == unit_range.shape[0]) and np.all(units == unit_range):
            self.timecourse_all_units = self.timecourse_all_units[:, unit_start:unit_stop].copy()
        else:
            self.timecourse_all_units = self.timecourse_all_units[:, units]

    def _validate_trial_range(self, trial_start: int, trial_stop: int) -> None:
        """Make sure trial range is not negative, empty, or out of bounds."""

        assert trial_start >= 0
        assert (trial_stop - trial_start) >= 1
        assert trial_stop <= self.n_trials

    def _get_time_range(self, trial_start: int, trial_stop: int) -> tuple[int, int]:
        """Get range of timecourse values corresponding to trial range."""

        time_start = self.trial_bounds[trial_start][0]  # beginning of first trial
        time_stop = self.trial_bounds[trial_stop - 1][1]  # end of last trial

        return time_start, time_stop

    def select_trial_range(self, trial_start: int, trial_stop: int) -> None:
        """Extract data for given trial range"""

        # Check that trial range is valid for this paradigm
        self._validate_trial_range(trial_start, trial_stop)

        # Get time range
        time_start, time_stop = self._get_time_range(trial_start, trial_stop)

        # Create slice objects
        trial_slice = slice(trial_start, trial_stop)
        time_slice = slice(time_start, time_stop)

        # Number of trials and time points change
        self.n_trials = trial_stop - trial_start
        self.n_time = time_stop - time_start

        # Extract trial range from per-trial variables
        self.stimulus_index_valid = self.stimulus_index_valid[trial_slice]
        self.on_durations = self.on_durations[trial_slice]
        self.off_durations = self.off_durations[trial_slice]
        self.trial_durations = self.trial_durations[trial_slice]
        self.timecourse_on_times_ks = self.timecourse_on_times_ks[trial_slice]

        # Need to adjust time variables to account for new start time
        self.timecourse_on_times = self.timecourse_on_times[trial_slice] - time_start
        self.timecourse_off_times = self.timecourse_off_times[trial_slice] - time_start

        # Extract time range from timecourse variables
        self.timecourse_all_units = self.timecourse_all_units[time_slice, :]
        self.eyex_timecourse = self.eyex_timecourse[time_slice]
        self.eyey_timecourse = self.eyey_timecourse[time_slice]


@dataclass
class FOBParadigm(Paradigm):
    paradigm_name: ClassVar[str] = 'FOB'
    paradigm_abbr: ClassVar[str] = 'fob'

    @classmethod
    def from_h5(cls, g: h5py.Group, units: np.ndarray | None = None) -> Self:
        cls._check_paradigm_name(g)
        data = cls._load_common_fields_h5(g, units)
        return cls(**data)


@dataclass
class FSParadigm(Paradigm):
    """Intermediate base class shared by all flash suppression paradigms. Not a concrete paradigm."""

    # Indicator for whether trial is priming (unambiguous) trial
    trial_is_priming: np.ndarray

    # Indicator for whether trial is binocular (flash suppression) trial
    trial_is_binocular: np.ndarray

    # Indicator for whether trial is transparent trial
    trial_is_transparent: np.ndarray

    # Indicator for whether trial is unambiguous trial
    trial_is_unambiguous: np.ndarray

    # Indicator for whether trial is gray trial
    trial_is_gray: np.ndarray

    # Index of dominant image for priming and binocular trials (-1 for gray trials)
    trial_dominant_image_index: np.ndarray

    # Index of suppressed image for binocular trials (-1 for gray and priming trials)
    trial_suppressed_image_index: np.ndarray

    # Indicator for whether priming stimulus with given index is red
    priming_stimulus_is_red: np.ndarray

    # Indicator for whether priming stimulus with given index is cyan
    priming_stimulus_is_cyan: np.ndarray

    def validate(self):
        super().validate()

        assert self.trial_is_priming.shape == (self.n_trials,)
        assert self.trial_is_binocular.shape == (self.n_trials,)
        assert self.trial_is_transparent.shape == (self.n_trials,)
        assert self.trial_is_unambiguous.shape == (self.n_trials,)
        assert self.trial_is_gray.shape == (self.n_trials,)
        assert self.trial_dominant_image_index.shape == (self.n_trials,)
        assert self.trial_suppressed_image_index.shape == (self.n_trials,)
        assert self.priming_stimulus_is_red.ndim == 1
        assert self.priming_stimulus_is_red.shape[0] >= 1
        assert self.priming_stimulus_is_cyan.ndim == 1
        assert self.priming_stimulus_is_cyan.shape[0] >= 1

    @classmethod
    def _load_fs_fields_h5(cls, g: h5py.Group) -> dict:
        return {
            'trial_is_priming': np.array(g['trial_is_priming']).flatten(),
            'trial_is_binocular': np.array(g['trial_is_binocular']).flatten(),
            'trial_is_transparent': np.array(g['trial_is_transparent']).flatten(),
            'trial_is_unambiguous': np.array(g['trial_is_unambiguous']).flatten(),
            'trial_is_gray': np.array(g['trial_is_gray']).flatten(),
            'trial_dominant_image_index': np.array(g['trial_dominant_image_index']).flatten(),
            'trial_suppressed_image_index': np.array(g['trial_suppressed_image_index']).flatten(),
            'priming_stimulus_is_red': np.array(g['priming_stimulus_is_red']).flatten(),
            'priming_stimulus_is_cyan': np.array(g['priming_stimulus_is_cyan']).flatten(),
        }

    def to_h5(self, g: h5py.Group) -> None:
        super().to_h5(g)

        g.create_dataset('trial_is_priming', data=self.trial_is_priming)
        g.create_dataset('trial_is_binocular', data=self.trial_is_binocular)
        g.create_dataset('trial_is_transparent', data=self.trial_is_transparent)
        g.create_dataset('trial_is_unambiguous', data=self.trial_is_unambiguous)
        g.create_dataset('trial_is_gray', data=self.trial_is_gray)
        g.create_dataset('trial_dominant_image_index', data=self.trial_dominant_image_index)
        g.create_dataset('trial_suppressed_image_index', data=self.trial_suppressed_image_index)
        g.create_dataset('priming_stimulus_is_red', data=self.priming_stimulus_is_red)
        g.create_dataset('priming_stimulus_is_cyan', data=self.priming_stimulus_is_cyan)

    def select_trial_range(self, trial_start: int, trial_stop: int) -> None:
        super().select_trial_range(trial_start, trial_stop)

        trial_slice = slice(trial_start, trial_stop)
        self.trial_is_priming = self.trial_is_priming[trial_slice]
        self.trial_is_binocular = self.trial_is_binocular[trial_slice]
        self.trial_is_transparent = self.trial_is_transparent[trial_slice]
        self.trial_is_unambiguous = self.trial_is_unambiguous[trial_slice]
        self.trial_is_gray = self.trial_is_gray[trial_slice]
        self.trial_dominant_image_index = self.trial_dominant_image_index[trial_slice]
        self.trial_suppressed_image_index = self.trial_suppressed_image_index[trial_slice]


@dataclass
class FSMParadigm(FSParadigm):
    paradigm_name: ClassVar[str] = 'flash_suppression_many_stimuli'
    paradigm_abbr: ClassVar[str] = 'fsm'

    @classmethod
    def from_h5(cls, g: h5py.Group, units: np.ndarray | None = None) -> Self:
        cls._check_paradigm_name(g)
        data = cls._load_common_fields_h5(g, units)
        data.update(cls._load_fs_fields_h5(g))
        return cls(**data)


@dataclass
class FSMTParadigm(FSParadigm):
    paradigm_name: ClassVar[str] = 'flash_suppression_many_stimuli_transparent'
    paradigm_abbr: ClassVar[str] = 'fsmt'

    @classmethod
    def from_h5(cls, g: h5py.Group, units: np.ndarray | None = None) -> Self:
        cls._check_paradigm_name(g)
        data = cls._load_common_fields_h5(g, units)
        data.update(cls._load_fs_fields_h5(g))
        return cls(**data)


@dataclass
class FSOParadigm(FSParadigm):
    paradigm_name: ClassVar[str] = 'flash_suppression_optimized'
    paradigm_abbr: ClassVar[str] = 'fso'

    @classmethod
    def from_h5(cls, g: h5py.Group, units: np.ndarray | None = None) -> Self:
        cls._check_paradigm_name(g)
        data = cls._load_common_fields_h5(g, units)
        data.update(cls._load_fs_fields_h5(g))
        return cls(**data)


@dataclass
class FSORParadigm(FSParadigm):
    paradigm_name: ClassVar[str] = 'flash_suppression_optimized_repeat_subset'
    paradigm_abbr: ClassVar[str] = 'fsor'

    @classmethod
    def from_h5(cls, g: h5py.Group, units: np.ndarray | None = None) -> Self:
        cls._check_paradigm_name(g)
        data = cls._load_common_fields_h5(g, units)
        data.update(cls._load_fs_fields_h5(g))
        return cls(**data)
