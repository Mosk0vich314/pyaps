"""Gate sweep at a fixed bias."""

from __future__ import annotations
from dataclasses import asdict

from .base import BaseMeasurement, ADwinSettings
from .sweep import Sweep, SweepParams
from .fixed_voltage import FixedVoltage, FixedVoltageParams
from gui.realtime_plot import RealtimeSweepPlot


class GateSweepMeasurement(BaseMeasurement):
    TYPE_NAME = "Gatesweep"

    def __init__(self, settings: ADwinSettings,
                 gate_params: SweepParams | None = None,
                 bias_params: FixedVoltageParams | None = None):
        super().__init__(settings)
        # Defaults match the APS2 GateSweepMeasurement.m
        self.gate = gate_params or SweepParams(
            output=2, startV=0, minV=-50, maxV=50, dV=0.1)
        self.bias = bias_params or FixedVoltageParams(output=1, startV=0, setV=0.1)

    def run(self, plot: RealtimeSweepPlot | None = None,
            stop_flag=None) -> None:
        print("--- Starting Gate Sweep ---")

        # 1. Set the fixed bias
        if "Fixed_AO" not in self.adwin._loaded:
            self.adwin.load_process("Fixed_AO")
        FixedVoltage(self.adwin, self.settings).apply(self.bias)

        # 2. Sweep the gate
        if self.gate.process not in self.adwin._loaded:
            self.adwin.load_process(self.gate.process)

        own_plot = plot is None
        if own_plot:
            plot = RealtimeSweepPlot("Gate Sweep", self.settings.N_ADC,
                                      x_range=(self.gate.minV, self.gate.maxV),
                                      x_label="Gate (V)")
            plot.show()

        sweep = Sweep(self.adwin, self.settings)
        result = sweep.run(self.gate, plot=plot, stop_flag=stop_flag)
        self.data = {"Gate": asdict(result), "Bias": asdict(self.bias)}
        self.save()
