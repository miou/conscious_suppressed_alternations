"""Functions for handling data in DVC pipelines."""

import numpy as np
from tsao_lab_data.session import Session


def rec_fname(session: str, paradigm: str, probes: str, ext: str) -> str:
    """Get filename used for subset of data throughout pipeline."""

    # Check formatting
    assert session[0] == 's'
    assert probes[0] == 'p'
    assert ext[0] == '.'

    return f'{session}_{paradigm}_{probes}{ext}'


def parse_rec_fname(fname: str) -> dict:
    """Get filename used for subset of data throughout pipeline."""

    # Split by underscore to get session and paradigm segments of filename
    us_split = fname.split('_')
    session = us_split[0]
    paradigm = us_split[1]

    # Final segment contains probe string and file extension, separated by period
    pd_split = us_split[2].split('.')
    probes = pd_split[0]
    ext = '.' + pd_split[1]

    # Check that parsed values are valid
    assert len(session) >= 2 and session[0] == 's'
    assert len(probes) >= 2 and probes[0] == 'p'
    assert len(ext) >= 2 and  ext[0] == '.'

    return {
        'session': session,
        'paradigm': paradigm,
        'probes': probes,
        'ext': ext
    }


def get_probe_list(probes_arg: str | None, n_probes_total: int) -> list[int]:
    """Parse argument passed to --probes option and return list of probes."""

    # If no probe argument is given, default to using all probes
    if probes_arg is None:
        return list(range(1, n_probes_total + 1))

    # Extract list of probes from argument string (e.g. 'p12' becomes [1, 2])
    probes = [int(c) for c in probes_arg[1:]]

    # Sort list
    probes.sort()

    # Check that probes are all valid
    for p in probes:
        assert 1 <= p <= n_probes_total

    return probes


def get_units_select(
    session: Session, probes: list[int], units_filter: list[list[int]]
) -> np.ndarray:
    """Get list of session units that are on specified probes and contained in filtered lists.

    For example, if a session has 10 units total, and units 0-4 are on probe 1 and units 5-9 are on
    probe 2, this function should behave like:
        get_units_select(session, [1, 2], [[3, 4, 5]]) -> np.array([3, 4, 5])
        get_units_select(session, [1, 2], [[3, 4, 5], [4, 5]]) -> np.array([4, 5])
        get_units_select(session, [1], [[3, 4, 5], [4, 5]]) -> np.array([4])
        get_units_select(session, [2], [[3, 4, 5], [4, 5]]) -> np.array([5])
        get_units_select(session, [1], [[0, 1, 2, 3, 4, 5, 6]]) -> np.array([0, 1, 2, 3, 4])

    """

    # Set of units that belong to at least one probe in list
    units_sel_probe = set([])
    for p in probes:
        units_sel_probe = units_sel_probe | set(
            np.argwhere(session.unit_probe == p).flatten().tolist()
        )

    # Set of units that are present in all filtered lists of units
    units_sel_filter = set(range(0, session.n_units))
    for uf in units_filter:
        units_sel_filter = units_sel_filter & set(uf)

    # Selected units must pass filter and belong to probe in list
    units_select = units_sel_probe & units_sel_filter

    # Convert set of units to sorted list
    units_select_ls = sorted(list(units_select))

    return np.array(units_select_ls)
