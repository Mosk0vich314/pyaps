"""Port of APS2/Measurements/NeedleAlignment.m."""

from __future__ import annotations
from dataclasses import dataclass, asdict
from .base_measurement import BaseMeasurement


@dataclass
class NeedleGate:
    Amplitude: float = 10.0     # V
    Frequency: float = 10.0     # Hz
    process: str = "Waveform_AO"


@dataclass
class NeedleTimetrace:
    runtime: float = 1.2
    scanrate: int = 500000


class NeedleAlignment(BaseMeasurement):
    MATLAB_CLASS = "NeedleAlignment"

    def __init__(self, bridge, settings: dict,
                 gate: NeedleGate | None = None,
                 timetrace: NeedleTimetrace | None = None):
        super().__init__(bridge, settings)
        self.gate = gate or NeedleGate()
        self.timetrace = timetrace or NeedleTimetrace()

    def create(self):
        super().create()
        self.bridge.assign_fields(self._var + ".Gate",      asdict(self.gate))
        self.bridge.assign_fields(self._var + ".Timetrace", asdict(self.timetrace))
