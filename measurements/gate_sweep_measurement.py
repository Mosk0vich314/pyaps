"""Port of APS2/Measurements/GateSweepMeasurement.m."""

from __future__ import annotations
from dataclasses import dataclass, asdict
from .base_measurement import BaseMeasurement


@dataclass
class GateParams:
    startV: float = -50.0
    maxV: float = 50.0
    points: int = 1001
    process: str = "Sweep_AO"
    output: int = 2


@dataclass
class BiasParams:
    setV: float = 0.1


class GateSweepMeasurement(BaseMeasurement):
    MATLAB_CLASS = "GateSweepMeasurement"

    def __init__(self, bridge, settings: dict,
                 gate: GateParams | None = None,
                 bias: BiasParams | None = None):
        super().__init__(bridge, settings)
        self.gate = gate or GateParams()
        self.bias = bias or BiasParams()

    def create(self):
        super().create()
        self.bridge.assign_fields(self._var + ".Gate", asdict(self.gate))
        self.bridge.assign_fields(self._var + ".Bias", asdict(self.bias))
