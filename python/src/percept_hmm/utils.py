"""Utility functions."""

import time
from contextlib import contextmanager
import yaml
import numpy as np


@contextmanager
def timex(msg: str):
    """Context manager for timing code block and printing result."""

    print(msg)
    tic = time.perf_counter()
    try:
        yield
    finally:
        toc = time.perf_counter() - tic
        print(f'Done. ({toc:.2f} s)')


def load_params(params_fpath: str) -> dict:
    """Read parameters from YAML file.

    Args:
        params_fpath: str
            Path to file containing parameters

    Returns:
        params: dict
            Dictionary containing parameters

    """

    with open(params_fpath, 'r') as f:
        return yaml.safe_load(f)


def get_angle_rad(u: np.ndarray, v: np.ndarray) -> float:
    """Calculate angle between two vectors (radians).

    Args:
        u: np.ndarray[float, (N,)]
            First vector
        v: np.ndarray[float, (N,)]
            Second vector

    Returns:
        theta_rad: float
            Angle between vectors (radians)

    """

    # Remove extra dimensions (these interfere with np.dot())
    u = np.squeeze(u)
    v = np.squeeze(v)

    # Compute product of vector norms for denominator (computing each norm
    # individually and multiplying them can lead to numerical instability due
    # to square root function) square root function) square root function) square root function)
    norm_prod = np.sqrt(np.dot(u, u) * np.dot(v, v))

    # Dot-product formula for angle between vectors
    theta_rad = np.arccos(np.dot(u, v) / norm_prod)

    return theta_rad


def get_angle_deg(u: np.ndarray, v: np.ndarray) -> float:
    """Calculate angle between two vectors (degrees).

    Args:
        u: np.ndarray[float, (N,)]
            First vector
        v: np.ndarray[float, (N,)]
            Second vector

    Returns:
        theta_deg: float
            Angle between vectors (degrees)

    """

    # Compute angle in radians and then convert to degrees
    theta_rad = get_angle_rad(u, v)
    theta_deg = theta_rad * 360 / (2 * np.pi)

    return theta_deg
