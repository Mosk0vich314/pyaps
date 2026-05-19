"""Base class for all measurements.

Holds settings, ensures ADwin is booted, and saves results to disk in a format
compatible with the legacy `.mat` workflow (so existing analysis scripts that
load Settings/Data structs keep working).
"""

from __future__ import annotations
from dataclasses import dataclass, field, asdict
from datetime import datetime
import pathlib
from typing import Any

import numpy as np
from scipy.io import savemat

from hardware.adwin import (
    ADwin, get_adwin,
    INPUT_RESOLUTION, OUTPUT_RESOLUTION, OUTPUT_MIN, OUTPUT_MAX, INPUT_RANGE,
    AI_ADDRESS, AO_ADDRESS, DIO_ADDRESS,
)


@dataclass
class ADwinSettings:
    """Replaces the MATLAB `Settings` struct that every legacy routine consumed.

    Field names match the MATLAB ones so saved .mat files round-trip to the
    legacy plotting/processing scripts.
    """
    ADwin: str = "GoldII"

    # Filled in by ADwin instance after boot
    clockfrequency: float = 0.3e9

    # ADC/DAC config
    input_resolution: int = INPUT_RESOLUTION
    output_resolution: int = OUTPUT_RESOLUTION
    output_min: float = OUTPUT_MIN
    output_max: float = OUTPUT_MAX
    input_range: float = INPUT_RANGE
    AI_address: int = AI_ADDRESS
    AO_address: int = AO_ADDRESS
    DIO_address: int = DIO_ADDRESS

    # ADC channel selection (1-indexed). ADC[i] is the gain (e.g. 1e7 V/A) or "off".
    ADC: list[Any] = field(default_factory=lambda: [1e7, "off", "off", "off",
                                                    "off", "off", "off", "off"])
    ADC_gain: list[float] = field(default_factory=lambda: [0]*8)
    auto: str = "FEMTO"

    # 4-point measurement (pair voltage/current ADCs); 0 = off
    res4p: int = 0

    # Bookkeeping for saved .mat files
    sample: str = "sample"
    filename: str = "meas"
    type: str = ""
    save_dir: str = "."
    T: float = 300.0

    # Path used by legacy plotting scripts (kept for .mat compatibility)
    path: str = ""

    def __post_init__(self):
        from hardware.adwin import CLOCK_FREQUENCY
        self.clockfrequency = CLOCK_FREQUENCY[self.ADwin]

    @property
    def ADC_idx(self) -> list[int]:
        """1-indexed list of active ADC channels (those whose gain is numeric)."""
        return [i + 1 for i, g in enumerate(self.ADC) if isinstance(g, (int, float))]

    @property
    def N_ADC(self) -> int:
        return len(self.ADC_idx)

    @property
    def N_ADC_pairs(self) -> int:
        return self.N_ADC // 2 if self.res4p else self.N_ADC

    def to_matlab_dict(self) -> dict:
        """Plain dict for scipy.io.savemat — mirrors the MATLAB struct layout."""
        d = asdict(self)
        # ADC contains mixed types — savemat handles cell-array equivalents via object arrays
        d["ADC"] = np.array(self.ADC, dtype=object)
        d["ADC_idx"] = np.array(self.ADC_idx, dtype=np.int64)
        d["ADC_gain"] = np.array(self.ADC_gain, dtype=np.float64)
        return d


class BaseMeasurement:
    """Parent of all measurement types."""

    TYPE_NAME = ""

    def __init__(self, settings: ADwinSettings):
        self.settings = settings
        self.settings.type = self.TYPE_NAME
        self.data: dict[str, Any] = {}
        self.filename: str = ""
        self.adwin: ADwin = get_adwin(settings.ADwin)
        self.settings.clockfrequency = self.adwin.clock_frequency

    # ------------------------------------------------------------------
    # Subclass hooks
    # ------------------------------------------------------------------

    def run(self):
        raise NotImplementedError("Subclasses must implement run()")

    # ------------------------------------------------------------------
    # I/O
    # ------------------------------------------------------------------

    def save(self, suffix: str = ""):
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        s = self.settings
        name = f"{s.filename}_{s.sample}_{s.type}_{timestamp}"
        if suffix:
            name = f"{name}_{suffix}"
        self.filename = name

        out_dir = pathlib.Path(s.save_dir)
        out_dir.mkdir(parents=True, exist_ok=True)
        out_path = out_dir / f"{name}.mat"

        savemat(str(out_path), {
            "Settings": s.to_matlab_dict(),
            "Data": self.data,
        }, do_compression=True)
        print(f"[Save] {out_path}")
