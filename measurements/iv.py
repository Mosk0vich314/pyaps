"""IV (current-voltage) sweep on the bias AO channel."""

from __future__ import annotations
from dataclasses import asdict

from .base import BaseMeasurement, ADwinSettings
from .sweep import Sweep, SweepParams
from gui.realtime_plot import RealtimeSweepPlot


class IVMeasurement(BaseMeasurement):
    TYPE_NAME = "IV"

    def __init__(self, settings: ADwinSettings, params: SweepParams | None = None):
        super().__init__(settings)
        self.params = params or SweepParams(output=1)

    def run(self, plot: RealtimeSweepPlot | None = None,
            stop_flag=None) -> None:
        print("--- Starting IV Measurement ---")
        # Load the ADwin process for this sweep family if needed.
        if self.params.process not in self.adwin._loaded:
            self.adwin.load_process(self.params.process)

        own_plot = False
        if plot is None:
            plot = RealtimeSweepPlot("IV", self.settings.N_ADC,
                                      x_range=(self.params.minV, self.params.maxV))
            plot.show()
            own_plot = True

        sweep = Sweep(self.adwin, self.settings)
        result = sweep.run(self.params, plot=plot, stop_flag=stop_flag)
        self.data = {"IV": _serialize(result)}
        self.save()

        if own_plot:
            # Leave the window up so the user can inspect; caller closes it.
            pass


def _serialize(p: SweepParams) -> dict:
    """Strip non-serializable bits (callables) before passing to savemat."""
    d = asdict(p)
    return d
