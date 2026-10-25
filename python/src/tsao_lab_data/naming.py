"""Functions for processing names of paradigms and sessions."""

from datetime import datetime

from .paradigm import Paradigm


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

    # Dictionary matching paradigm name to abbreviation
    pd_classes = Paradigm.concrete_subclasses()
    pd_abbr = {cls.paradigm_name: cls.paradigm_abbr for cls in pd_classes}

    # Get abbreviation for name
    try:
        return pd_abbr[full_name]
    except KeyError:
        raise ValueError(f"Paradigm '{full_name}' is not supported")


def paradigm_abbr_to_full(abbr: str) -> str:
    """Get full name of paradigm with given abbreviation.

    Args:
        abbr: str
            Abbreviation used for directory names and scripts
    Returns:
        full_name: str
            Full name of paradigm used in raw data file
    Raises:
        ValueError
            If 'abbr' does not have a full name
    """

    # Dictionary matching paradigm abbreviation to name
    pd_classes = Paradigm.concrete_subclasses()
    abbr_pd = {cls.paradigm_abbr: cls.paradigm_name for cls in pd_classes}

    # Get full name for abbreviation
    try:
        return abbr_pd[abbr]
    except KeyError:
        raise ValueError(f"Abbreviation '{abbr}' is not supported")


def parse_session_name(session_name: str) -> tuple[datetime, str]:
    """Parse datetime and animal name from session name.

    Args:
        session_name: str
            Name of session, for example '210803_133520_Alfie'
    Returns:

        dt: datetime.datetime
            Session datetime, for example datetime('2021-08-03 13:35:20')
        animal: str
            Name of animal, for example 'Alfie'

    """

    # Length of datetime string at beginning of session name
    DT_STR_LEN = 13

    # Get datetime of session from beginning of session name
    dt_str = session_name[:DT_STR_LEN]
    dt = datetime.strptime(dt_str, '%y%m%d_%H%M%S')

    # Get animal from second part of session name
    animal = session_name[(DT_STR_LEN + 1) :]

    return (dt, animal)

