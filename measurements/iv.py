"""IV (current-voltage) sweep on the bias AO channel.

Mirrors the flow of legacy `Make_IV.m`:
  1. Ramp Gate from initV → targetV (if a GateRamp is provided)
  2. Wait gate `waiting_time` seconds
  3. Run the bias sweep `repeat` times (Sweep_AO + Realtime_sweep)
  4. Ramp Gate from targetV → endV
  5. Save .mat
"""

from __future__ import annotations
from dataclasses import asdict
import time

from .base import BaseMeasurement, ADwinSettings
from .sweep import Sweep, SweepParams
from .fixed_voltage import FixedVoltage, FixedVoltageParams, GateRamp
from gui.realtime_plot import RealtimeSweepPlot


class IVMeasurement(BaseMeasurement):
    TYPE_NAME = "IV"

    def __init__(self, settings: ADwinSettings,
                 params: SweepParams | None = None,
                 gate: GateRamp | None = None):
        super().__init__(settings)
        self.params = params or SweepParams(output=1)
        self.gate = gate or GateRamp()  # disabled by default

    def run(self, plot: RealtimeSweepPlot | None = None,
            stop_flag=None) -> None:
        print("--- Starting IV Measurement ---")

        # 1. Load processes
        if self.params.process not in self.adwin._loaded:
            self.adwin.load_process(self.params.process)
        if self.gate.enabled and "Fixed_AO" not in self.adwin._loaded:
            self.adwin.load_process("Fixed_AO")

        # 2. Pre-measurement gate ramp
        fixed = FixedVoltage(self.adwin, self.settings)
        if self.gate.enabled:
            print(f"[IV] Ramping gate AO{self.gate.output}: "
                  f"{self.gate.initV:+.3f} V → {self.gate.targetV:+.3f} V")
            fixed.apply(FixedVoltageParams(
                output=self.gate.output, startV=self.gate.initV,
                setV=self.gate.targetV, ramp_rate=self.gate.ramp_rate,
                V_per_V=self.gate.V_per_V))
            if self.gate.waiting_time > 0:
                time.sleep(self.gate.waiting_time)

        # 3. Sweep (×repeat)
        own_plot = plot is None
        if own_plot:
            plot = RealtimeSweepPlot("IV", self.settings.N_ADC,
                                      x_range=(self.params.minV, self.params.maxV))
            plot.show()

        sweep = Sweep(self.adwin, self.settings)
        repeat = max(1, self.params.repeat)
        for i in range(repeat):
            if stop_flag and stop_flag():
                break
            self.params.index = i + 1
            if repeat > 1:
                print(f"[IV] Sweep {i+1}/{repeat}")
            sweep.run(self.params, plot=plot, stop_flag=stop_flag)

        self.data = {"IV": _serialize(self.params),
                     "Gate": asdict(self.gate)}
        self.save()

        # 4. Post-measurement gate ramp
        if self.gate.enabled:
            print(f"[IV] Ramping gate back: "
                  f"{self.gate.targetV:+.3f} V → {self.gate.endV:+.3f} V")
            fixed.apply(FixedVoltageParams(
                output=self.gate.output, startV=self.gate.targetV,
                setV=self.gate.endV, ramp_rate=self.gate.ramp_rate,
                V_per_V=self.gate.V_per_V))


def _serialize(p: SweepParams) -> dict:
    d = asdict(p)
    return d
