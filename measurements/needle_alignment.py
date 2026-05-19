"""Needle alignment helper.

Drives a sine wave on the gate AO to create an oscillating signal that helps
the user visually align the probe needle. Uses the Waveform_AO process (slot 6).

ADwin parameter slots (from Waveform_AO_<model>.bas):

  Par 6   AO_address
  Par 9   AO output channel
  Par 31  signal length (samples)
  Data 5  output waveform (volts → bins)
"""

from __future__ import annotations
from dataclasses import dataclass
import numpy as np

from .base import BaseMeasurement, ADwinSettings
from utilities.adwin_helpers import get_delays, convert_V_to_bin


@dataclass
class NeedleAlignParams:
    process: str = "Waveform_AO"
    output: int = 2          # gate AO channel
    amplitude: float = 10.0  # V
    frequency: float = 10.0  # Hz
    scanrate: float = 500_000  # samples/s
    V_per_V: float = 1.0


class NeedleAlignment(BaseMeasurement):
    TYPE_NAME = "NeedleAlign"
    SLOT = 6

    def __init__(self, settings: ADwinSettings,
                 params: NeedleAlignParams | None = None):
        super().__init__(settings)
        self.params = params or NeedleAlignParams()

    def start(self):
        p = self.params
        s = self.settings
        a = self.adwin

        if p.process not in a._loaded:
            a.load_process(p.process)

        n_samples = int(p.scanrate / p.frequency)
        t = np.linspace(0, 1.0 / p.frequency, n_samples, endpoint=False)
        waveform_v = p.amplitude * np.sin(2 * np.pi * p.frequency * t)

        bins, _ = convert_V_to_bin(waveform_v / p.V_per_V,
                                   s.output_min, s.output_max,
                                   s.output_resolution)
        bins_send = (np.asarray(bins) - 1).astype(np.float64)

        a.set_par(6, s.AO_address)
        a.set_par(9, p.output)
        a.set_par(31, n_samples)
        a.set_data_double(5, bins_send, 1)

        process_delay, _ = get_delays(p.scanrate, 0, s.clockfrequency)
        a.set_processdelay(self.SLOT, process_delay)
        a.start_process(self.SLOT)
        print(f"[NeedleAlign] Running ({p.frequency} Hz, ±{p.amplitude} V).")

    def stop(self):
        self.adwin.stop_process(self.SLOT)
        print("[NeedleAlign] Stopped.")

    def run(self):
        self.start()
