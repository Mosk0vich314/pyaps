"""Generic ADwin sweep with real-time plotting.

Direct port of `Run_sweep.m` + `Realtime_sweep.m` (Lakeshore Libs/Matlab),
collapsed into one Python class because the polling loop and the data
acquisition share state and there's no reason to keep them in two files.

ADwin parameter slot layout (from the .bas process source — do NOT change
without also recompiling the ADwin process binary):

  Par 5   AI_address
  Par 6   AO_address
  Par 7   DIO_address
  Par 8   AO output channel
  Par 10  input_resolution
  Par 20  N_ADC_pairs
  Par 21  points_av
  Par 22  loops_waiting (settling time)
  Par 23  NumBias
  Par 25  current sweep counter (ADwin writes this — we poll it)
  Par 26  loops_waiting_autoranging
  FPar 9  maxI (bias-reversal threshold)
  FPar 27..34   ADC log10 gains
  Data 1  bias bin array
  Data 11 ADC_gain array
  Data 41..N  per-ADC current arrays

The sweep is launched on slot 1 (Sweep_AO family).
"""

from __future__ import annotations
from dataclasses import dataclass, field
from typing import Optional
import time

import numpy as np
from PySide6.QtWidgets import QApplication

from hardware.adwin import ADwin
from utilities.adwin_helpers import get_delays, convert_V_to_bin
from gui.realtime_plot import RealtimeSweepPlot
from .base import ADwinSettings


@dataclass
class SweepParams:
    """Parameters for a single bias / gate sweep."""
    process: str = "Sweep_AO_read_AI_single_auto_FEMTO"  # full TBx file base name
    output: int = 1                # AO channel
    startV: float = 0.0
    minV: float = -0.5
    maxV: float = 0.5
    dV: float = 0.001
    sweep_dir: str = "up"          # "up" or "down"
    scanrate: float = 450_000      # Hz (raw ADwin sample rate)
    settling_time: float = 0.0     # ms
    settling_time_autoranging: float = 1.0  # ms
    # Number of raw ADwin samples averaged per bias step. The legacy MATLAB
    # convention is `scanrate / display_rate_hz`, with display_rate_hz = 50 Hz,
    # which gives a smooth ~50 plotted-points/sec for live updates. Setting
    # this to 0 picks that default automatically; set explicitly for a
    # different noise/speed tradeoff.
    points_av: int = 0
    display_rate_hz: float = 50.0  # used only when points_av == 0
    V_per_V: float = 1.0           # voltage divider factor at the input
    repeat: int = 1
    # If maxI is set, ADwin process can short the output if current exceeds it
    maxI: Optional[float] = None
    index: int = 1                 # 1-based index into the repeat axis

    # Filled in by Sweep.run()
    bias: Optional[np.ndarray] = field(default=None, repr=False)
    bias_new: Optional[np.ndarray] = field(default=None, repr=False)
    NumBias: int = 0
    process_delay: int = 0
    loops_waiting: int = 0
    loops_waiting_autoranging: int = 0
    time_per_point: Optional[np.ndarray] = field(default=None, repr=False)
    sampling_rate: Optional[np.ndarray] = field(default=None, repr=False)
    current: Optional[list[np.ndarray]] = field(default=None, repr=False)


class Sweep:
    """Run an ADwin sweep on slot 1 and stream samples into a plot widget."""

    POLL_INTERVAL_S = 0.05    # 20 Hz update rate
    SLOT = 1

    def __init__(self, adwin: ADwin, settings: ADwinSettings):
        self.adwin = adwin
        self.settings = settings

    # ------------------------------------------------------------------
    # Bias vector
    # ------------------------------------------------------------------

    @staticmethod
    def build_bias_vector(p: SweepParams) -> np.ndarray:
        """Match the ramp_up / ramp_down / ramp_up2 logic from Run_sweep.m."""
        if p.minV < p.startV:
            ramp_up   = np.arange(p.startV, p.maxV + p.dV/2, p.dV)
            ramp_down = np.arange(ramp_up[-1], p.minV - p.dV/2, -p.dV)
            ramp_up2  = np.arange(ramp_down[-1], p.startV + p.dV/2, p.dV)
            bias = np.concatenate([ramp_up, ramp_down, ramp_up2])
        else:
            ramp_up   = np.arange(p.minV, p.maxV + p.dV/2, p.dV)
            ramp_down = np.arange(ramp_up[-1], p.minV - p.dV/2, -p.dV)
            bias = np.concatenate([ramp_up, ramp_down])
        if p.sweep_dir == "down":
            bias = -bias
        return bias

    # ------------------------------------------------------------------
    # Run
    # ------------------------------------------------------------------

    def run(self, p: SweepParams,
            plot: Optional[RealtimeSweepPlot] = None,
            stop_flag: Optional[callable] = None) -> SweepParams:
        s = self.settings

        # 1. Bias vector
        if p.bias is None:
            p.bias = self.build_bias_vector(p)
        p.NumBias = len(p.bias)
        p.minV = float(np.min(p.bias))
        p.maxV = float(np.max(p.bias))

        # 2. Timing
        if p.points_av <= 0:
            # Auto: target ~50 plotted points/sec (legacy MATLAB convention).
            p.points_av = max(1, int(p.scanrate / p.display_rate_hz))
        p.process_delay, p.loops_waiting = get_delays(
            p.scanrate, p.settling_time, s.clockfrequency)
        _, p.loops_waiting_autoranging = get_delays(
            p.scanrate, p.settling_time_autoranging, s.clockfrequency)

        # 3. Set parameters
        a = self.adwin
        a.set_par(10, s.input_resolution)
        a.set_par(5, s.AI_address)
        a.set_par(6, s.AO_address)
        a.set_par(7, s.DIO_address)
        a.set_par(8, p.output)
        a.set_par(20, s.N_ADC_pairs)
        a.set_par(21, p.points_av)
        a.set_par(22, p.loops_waiting)
        a.set_par(26, p.loops_waiting_autoranging)
        if p.maxI is not None:
            a.set_fpar(9, float(p.maxI))

        # ADC current-amplifier gains (FPar 27..34, log10 of gain)
        adc_pars = list(range(27, 35))
        for k, ch_idx in enumerate(s.ADC_idx):
            gain = s.ADC[ch_idx - 1]
            if isinstance(gain, (int, float)) and gain > 0:
                a.set_fpar(adc_pars[ch_idx - 1], float(np.log10(gain)))

        # 4. Bias array → bins
        bins, bias_new = convert_V_to_bin(p.bias / p.V_per_V,
                                          s.output_min, s.output_max,
                                          s.output_resolution)
        p.bias_new = bias_new * p.V_per_V
        bias_bins_send = bins - 1   # legacy MATLAB subtracts 1
        a.set_data_double(1, bias_bins_send.astype(np.float64), 1)

        a.set_par(23, p.NumBias)
        a.set_par(25, 0)   # reset sweep counter

        # Per-point timing for analysis (seconds per plotted bias step)
        t_per_step = p.points_av / p.scanrate + p.settling_time / 1000.0
        p.time_per_point = np.full(p.NumBias, t_per_step)
        p.sampling_rate = np.full(p.NumBias, 1.0 / t_per_step)

        # 5. ADC gain array
        a.set_data_double(11, np.asarray(s.ADC_gain, dtype=np.float64), 1)

        # 6. Storage
        if p.current is None:
            p.current = [np.zeros((p.NumBias, p.repeat)) for _ in range(s.N_ADC)]

        # 7. Run
        a.set_processdelay(self.SLOT, p.process_delay)
        a.start_process(self.SLOT)
        total_runtime = p.NumBias * t_per_step
        print(f"[Sweep] {p.NumBias} pts × {t_per_step*1000:.2f} ms = "
              f"{total_runtime:.2f} s total (points_av={p.points_av})")
        if plot is not None:
            plot.clear()

        self._poll_loop(p, plot, stop_flag)

        # 8. Read back final, complete data per ADC channel.
        # Data arrays for the per-ADC currents start at array number 41 (matches
        # the legacy convention: GetData_Double(channel + 1, ...) where channel
        # is the 1-based ADC index — i.e. arrays 2..9 in the original code).
        # The .bas script writes into arrays (ADC_idx + 1).
        for k, ch_idx in enumerate(s.ADC_idx):
            arr_no = ch_idx + 1
            buf = a.get_data_double(arr_no, 1, p.NumBias)
            p.current[k][:, p.index - 1] = buf

        return p

    # ------------------------------------------------------------------
    # Polling + live plot
    # ------------------------------------------------------------------

    def _poll_loop(self, p: SweepParams,
                   plot: Optional[RealtimeSweepPlot],
                   stop_flag: Optional[callable]):
        s = self.settings
        a = self.adwin
        previous = 0
        adc_arrays = [ch + 1 for ch in s.ADC_idx]

        while True:
            if stop_flag and stop_flag():
                a.stop_process(self.SLOT)
                return
            running = a.process_status(self.SLOT) == 1
            current_count = a.get_par(25) - 1
            if current_count > previous:
                n_new = current_count - previous
                if plot is not None:
                    chunks: list[np.ndarray] = []
                    for arr_no in adc_arrays:
                        chunks.append(a.get_data_double(arr_no, previous + 1, n_new))
                    x_chunk = p.bias[previous:current_count]
                    plot.append(x_chunk, chunks)
                previous = current_count
            if not running and a.get_par(25) <= 0:
                break
            if not running and current_count >= p.NumBias - 1:
                break
            QApplication.processEvents()
            time.sleep(self.POLL_INTERVAL_S)
