"""Port of APS2/Measurements/StabilityMeasurement.m."""

from __future__ import annotations
from dataclasses import dataclass, asdict
from .base_measurement import BaseMeasurement


@dataclass
class StabIV:
    startV: float = 0.0
    maxV: float = 0.2
    minV: float = -0.2
    points: int = 1001
    sweep_dir: str = "up"
    scanrate: int = 450000
    process_number: int = 1


@dataclass
class StabGate:
    initV: float = 0.0
    minV: float = -0.5
    maxV: float = 0.5
    dV: float = 0.001
    ramp_rate: float = 0.5
    process: str = "Fixed_AO"
    process_number: int = 3
    waiting_time: float = 0.1
    sweep_dir: str = "up"


class StabilityMeasurement(BaseMeasurement):
    MATLAB_CLASS = "StabilityMeasurement"

    def __init__(self, bridge, settings: dict,
                 iv: StabIV | None = None, gate: StabGate | None = None):
        super().__init__(bridge, settings)
        self.iv = iv or StabIV()
        self.gate = gate or StabGate()

    def create(self):
        super().create()
        self.bridge.assign_fields(self._var + ".IV",   asdict(self.iv))
        self.bridge.assign_fields(self._var + ".Gate", asdict(self.gate))

    def stop(self):
        if self._created:
            self.bridge.eval(f"{self._var}.Stop();")
