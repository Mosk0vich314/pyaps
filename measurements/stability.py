"""Stability diagram: repeat IV sweeps over a gate-voltage axis."""

from __future__ import annotations
from dataclasses import asdict, dataclass, field
import time
import numpy as np

from .base import BaseMeasurement, ADwinSettings
from .sweep import Sweep, SweepParams
from .fixed_voltage import FixedVoltage, FixedVoltageParams
from gui.realtime_plot import RealtimeSweepPlot, RealtimeStabilityPlot


@dataclass
class StabilityGate:
    output: int = 2
    initV: float = 0.0
    minV: float = -0.5
    maxV: float = 0.5
    dV: float = 0.001
    ramp_rate: float = 0.5     # V/s
    sweep_dir: str = "up"
    waiting_time: float = 0.1  # s, between gate set and IV start
    V_per_V: float = 1.0


class StabilityMeasurement(BaseMeasurement):
    TYPE_NAME = "Stability"

    def __init__(self, settings: ADwinSettings,
                 iv: SweepParams | None = None,
                 gate: StabilityGate | None = None):
        super().__init__(settings)
        self.iv = iv or SweepParams(output=1, startV=0, minV=-0.2, maxV=0.2,
                                    dV=0.0004, scanrate=450_000)
        self.gate = gate or StabilityGate()

    def run(self, plot: RealtimeStabilityPlot | None = None,
            sweep_plot: RealtimeSweepPlot | None = None,
            stop_flag=None) -> None:
        print("--- Starting Stability Measurement ---")

        # 1. Load processes
        if self.iv.process not in self.adwin._loaded:
            self.adwin.load_process(self.iv.process)
        if "Fixed_AO" not in self.adwin._loaded:
            self.adwin.load_process("Fixed_AO")

        # 2. Build gate vector
        gate_v = np.arange(self.gate.minV, self.gate.maxV + self.gate.dV/2, self.gate.dV)
        if self.gate.sweep_dir == "down":
            gate_v = gate_v[::-1]
        n_gate = len(gate_v)
        self.iv.repeat = n_gate

        # 3. Plots
        own_plot = plot is None
        if own_plot:
            plot = RealtimeStabilityPlot(
                "Stability",
                x_range=(self.iv.minV, self.iv.maxV),
                y_range=(self.gate.minV, self.gate.maxV))
            plot.show()
        plot.set_grid(self.iv.NumBias if self.iv.NumBias else 1, n_gate)

        if sweep_plot is None:
            sweep_plot = RealtimeSweepPlot("IV (live)", self.settings.N_ADC,
                                            x_range=(self.iv.minV, self.iv.maxV))
            sweep_plot.show()

        sweep = Sweep(self.adwin, self.settings)
        fixed = FixedVoltage(self.adwin, self.settings)

        prev_v = self.gate.initV
        for i, v in enumerate(gate_v):
            if stop_flag and stop_flag():
                break

            fixed.apply(FixedVoltageParams(
                output=self.gate.output, startV=prev_v, setV=float(v),
                ramp_rate=self.gate.ramp_rate, V_per_V=self.gate.V_per_V))
            prev_v = float(v)
            time.sleep(self.gate.waiting_time)

            self.iv.index = i + 1
            sweep.run(self.iv, plot=sweep_plot, stop_flag=stop_flag)

            # Update stability colormap with the latest column (first ADC channel)
            if self.iv.current is not None and len(self.iv.current) > 0:
                col = self.iv.current[0][:, i]
                # Re-grid after first sweep so we know NumBias
                if i == 0:
                    plot.set_grid(self.iv.NumBias, n_gate)
                plot.set_column(i, col)

        self.data = {
            "IV": asdict(self.iv),
            "Gate": {**vars(self.gate), "vector": gate_v},
        }
        self.save()
