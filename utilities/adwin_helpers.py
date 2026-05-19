"""Numerical helpers used by the sweep / fixed-voltage measurements.

Direct ports of get_delays.m, convert_V_to_bin.m, convert_bin_to_V.m.
"""

from __future__ import annotations
import numpy as np


def get_delays(scanrate: float, settling_time_ms: float,
               clock_frequency: float) -> tuple[int, int]:
    """Convert (scanrate Hz, settling_time ms, clock_frequency Hz) to ADwin clock ticks.

    Returns (process_delay, loops_waiting).
    """
    process_delay = int(round(clock_frequency / scanrate))
    loops_waiting = int(round(settling_time_ms / 1000.0 * scanrate))
    return process_delay, loops_waiting


def convert_V_to_bin(V, v_min: float, v_max: float, resolution: int):
    """Convert voltage(s) to DAC bin number(s) and the snapped voltage value(s).

    Mirrors `convert_V_to_bin.m` exactly (same off-by-one as MATLAB: bins are
    1..2**resolution; subtract 1 before sending to ADwin per the legacy code).
    """
    levels = np.linspace(v_min, v_max, 2 ** resolution)
    V_arr = np.atleast_1d(np.asarray(V, dtype=np.float64))
    # Find nearest level for each input voltage
    bins = np.searchsorted(levels, V_arr)
    bins = np.clip(bins, 0, len(levels) - 1)
    # Compare with neighbour to pick the truly closest one
    left = np.clip(bins - 1, 0, len(levels) - 1)
    take_left = np.abs(V_arr - levels[left]) < np.abs(V_arr - levels[bins])
    bins = np.where(take_left, left, bins)
    voltage_new = levels[bins]
    # MATLAB indexes from 1
    bins_matlab = bins + 1
    if np.isscalar(V) or np.asarray(V).ndim == 0:
        return int(bins_matlab[0]), float(voltage_new[0])
    return bins_matlab.astype(np.int64), voltage_new


def convert_bin_to_V(bins, v_range: float, resolution: int):
    """Inverse of convert_V_to_bin.

    `bins` are 1-indexed (MATLAB convention).
    """
    levels = np.linspace(-v_range, v_range, 2 ** resolution)
    idx = np.asarray(bins, dtype=np.int64) - 1
    return levels[idx]
