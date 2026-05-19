"""Time-trace acquisition via the Read_AI ADwin process (slot 2).

Direct port of the ADwin branch of `Run_timetrace.m`. Used both as a standalone
measurement and as the data source for the contact-detection routine.

ADwin parameter slots (Read_AI_<variant>_<model>.bas):

  Par 5,6,7   AI/AO/DIO addresses
  Par 10      input_resolution
  Par 14      runtime_counts (number of samples to acquire)
  Par 20      N_ADC_pairs
  Par 21      points_av
  Par 22      loops_waiting (settling)
  Par 26      loops_waiting_autoranging
  FPar 27..34 ADC log10 gains
  Data 11     ADC_gain array
"""

from __future__ import annotations
from dataclasses import dataclass, field
import time
import numpy as np

from hardware.adwin import ADwin
from utilities.adwin_helpers import get_delays
from .base import ADwinSettings


@dataclass
class TimetraceParams:
    process: str = "Read_AI_single_auto_FEMTO"
    runtime: float = 1.0           # seconds
    scanrate: float = 500_000      # samples/s
    points_av: int = 1
    settling_time: float = 0.0
    settling_time_autoranging: float = 1.0

    # Filled in by acquire()
    process_delay: int = 0
    loops_waiting: int = 0
    loops_waiting_autoranging: int = 0
    runtime_counts: int = 0
    sampling_rate: float = 0.0
    time_per_point: float = 0.0
    time_axis: np.ndarray | None = field(default=None, repr=False)
    data: list[np.ndarray] | None = field(default=None, repr=False)


class Timetrace:
    """Acquire a fixed-length time trace on all active ADCs."""

    SLOT = 2

    def __init__(self, adwin: ADwin, settings: ADwinSettings):
        self.adwin = adwin
        self.settings = settings

    def acquire(self, p: TimetraceParams,
                stop_flag=None) -> TimetraceParams:
        s = self.settings
        a = self.adwin

        if p.process not in a._loaded:
            a.load_process(p.process)

        p.process_delay, p.loops_waiting = get_delays(
            p.scanrate, p.settling_time, s.clockfrequency)
        _, p.loops_waiting_autoranging = get_delays(
            p.scanrate, p.settling_time_autoranging, s.clockfrequency)
        p.time_per_point = p.points_av / p.scanrate + p.settling_time / 1000.0
        p.sampling_rate = 1.0 / p.time_per_point
        p.runtime_counts = int(np.ceil(p.sampling_rate * p.runtime))
        p.time_axis = np.arange(p.runtime_counts) * p.time_per_point

        a.set_par(10, s.input_resolution)
        a.set_par(5, s.AI_address)
        a.set_par(6, s.AO_address)
        a.set_par(7, s.DIO_address)
        a.set_par(20, s.N_ADC_pairs)
        a.set_par(14, p.runtime_counts)
        a.set_par(21, p.points_av)
        a.set_par(22, p.loops_waiting)
        a.set_par(26, p.loops_waiting_autoranging)

        # ADC gains (FPar 27..34, log10)
        adc_pars = list(range(27, 35))
        for ch_idx in s.ADC_idx:
            gain = s.ADC[ch_idx - 1]
            if isinstance(gain, (int, float)) and gain > 0:
                a.set_fpar(adc_pars[ch_idx - 1], float(np.log10(gain)))

        a.set_data_double(11, np.asarray(s.ADC_gain, dtype=np.float64), 1)

        # Run
        a.set_processdelay(self.SLOT, p.process_delay)
        a.start_process(self.SLOT)

        # Wait for completion
        deadline = time.time() + p.runtime + 2.0
        while a.process_status(self.SLOT) == 1:
            if stop_flag and stop_flag():
                a.stop_process(self.SLOT)
                break
            if time.time() > deadline:
                a.stop_process(self.SLOT)
                break
            time.sleep(0.01)

        # Read back per-ADC data (arrays = ADC_idx + 1)
        p.data = []
        for ch_idx in s.ADC_idx:
            buf = a.get_data_double(ch_idx + 1, 1, p.runtime_counts)
            p.data.append(buf)

        return p
