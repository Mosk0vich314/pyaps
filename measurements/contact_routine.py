"""Needle contact routine.

Functional port of MATLAB's `needleRoutine.m` plus the GUI Z-descent loop that
surrounded it. The legacy contract:

1. Drive a low-frequency sine wave (10 Hz, ±10 V) on the gate channel via
   the Waveform_AO ADwin process. While the needle is in air this couples
   capacitively but produces no DC current; once the needle touches the
   device, an AC current at the same frequency flows through the bias ADC.
2. Acquire a short timetrace via Read_AI and extract the AC amplitude.
3. Lower Z by a small step. Repeat until the AC amplitude crosses the
   contact threshold (default 2 nA), or a max-step budget is exhausted.

The class lives outside `BaseMeasurement` because it doesn't save data — it
just leaves the stage at the contacted Z position.
"""

from __future__ import annotations
from dataclasses import dataclass
import time
import numpy as np

from hardware.adwin import ADwin
from .base import ADwinSettings
from .needle_alignment import NeedleAlignment, NeedleAlignParams
from .timetrace import Timetrace, TimetraceParams


@dataclass
class ContactParams:
    threshold: float = 2e-9          # A — peak AC amplitude that signals contact
    z_step_mm: float = 0.005         # 5 µm per Z descent step
    max_steps: int = 200
    settle_after_z: float = 0.05     # s — wait after each Z move before sampling
    timetrace_runtime: float = 0.3   # s — short trace per Z step
    excitation_frequency: float = 10.0  # Hz
    excitation_amplitude: float = 10.0  # V
    gate_output_channel: int = 2
    timetrace_process: str = "Read_AI_single_auto_FEMTO"
    excitation_process: str = "Waveform_AO"


class ContactRoutine:
    """Lower Z until the gate-induced AC current exceeds `threshold`."""

    def __init__(self, adwin: ADwin, settings: ADwinSettings, stage):
        self.adwin = adwin
        self.settings = settings
        self.stage = stage
        self.needle = NeedleAlignment(settings, NeedleAlignParams())
        self.timetrace = Timetrace(adwin, settings)

    def run(self, p: ContactParams | None = None,
            stop_flag=None) -> dict:
        p = p or ContactParams()
        # Use the right ADC measurement: take the first active ADC channel as
        # the contact-current sensor.
        if self.settings.N_ADC == 0:
            raise RuntimeError("No active ADC channel configured for contact detection.")

        # 1. Start sine excitation on the gate
        self.needle.params = NeedleAlignParams(
            output=p.gate_output_channel,
            amplitude=p.excitation_amplitude,
            frequency=p.excitation_frequency,
            process=p.excitation_process,
        )
        self.needle.start()
        print(f"[Contact] Excitation: {p.excitation_frequency} Hz, "
              f"±{p.excitation_amplitude} V on AO {p.gate_output_channel}.")

        result = {"contacted": False, "steps": 0, "final_amplitude": 0.0,
                  "z_traveled_mm": 0.0}

        try:
            tt_params = TimetraceParams(
                process=p.timetrace_process,
                runtime=p.timetrace_runtime,
            )

            for step in range(p.max_steps):
                if stop_flag and stop_flag():
                    print("[Contact] Stopped by user.")
                    break

                # Acquire short trace and look at AC amplitude on first ADC
                self.timetrace.acquire(tt_params, stop_flag=stop_flag)
                trace = tt_params.data[0]
                amplitude = self._ac_amplitude(trace, p.excitation_frequency,
                                                tt_params.sampling_rate)
                result["final_amplitude"] = float(amplitude)
                result["steps"] = step + 1

                print(f"[Contact] Step {step+1}: |I_ac| = {amplitude:.3e} A "
                      f"(threshold {p.threshold:.1e})")

                if amplitude >= p.threshold:
                    print("[Contact] *** Contact detected ***")
                    result["contacted"] = True
                    break

                # Lower Z one step
                self.stage.move_z(-p.z_step_mm)
                result["z_traveled_mm"] = -(step + 1) * p.z_step_mm
                time.sleep(p.settle_after_z)

            if not result["contacted"]:
                print(f"[Contact] No contact after {result['steps']} steps "
                      f"({result['z_traveled_mm']:.3f} mm).")
        finally:
            self.needle.stop()

        return result

    @staticmethod
    def _ac_amplitude(trace: np.ndarray, freq: float,
                      sampling_rate: float) -> float:
        """Lock-in style amplitude estimate at the excitation frequency.

        Demodulates by multiplying with sin/cos at `freq` and computes the
        magnitude. More robust than peak-to-peak when the trace is short.
        """
        if trace.size == 0 or sampling_rate <= 0:
            return 0.0
        n = trace.size
        t = np.arange(n) / sampling_rate
        ref_sin = np.sin(2 * np.pi * freq * t)
        ref_cos = np.cos(2 * np.pi * freq * t)
        # Subtract DC so we don't pick up a bias offset
        x = trace - np.mean(trace)
        i = np.dot(x, ref_sin) * (2.0 / n)
        q = np.dot(x, ref_cos) * (2.0 / n)
        return float(np.hypot(i, q))
