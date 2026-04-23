"""Port of APS2/Measurements/IVMeasurement.m."""

from __future__ import annotations
from dataclasses import dataclass, asdict
from .base_measurement import BaseMeasurement


@dataclass
class IVParams:
    startV: float = -0.5
    maxV: float = 0.5
    points: int = 501
    scanrate: int = 450000
    settling_time: float = 0.0
    process: str = "Sweep_AO"
    output: int = 1


class IVMeasurement(BaseMeasurement):
    MATLAB_CLASS = "IVMeasurement"

    def __init__(self, bridge, settings: dict, params: IVParams | None = None):
        super().__init__(bridge, settings)
        self.params = params or IVParams()

    def create(self):
        super().create()
        # Override any defaults set by the MATLAB constructor.
        self.bridge.assign_fields(self._var + ".IV", asdict(self.params))
