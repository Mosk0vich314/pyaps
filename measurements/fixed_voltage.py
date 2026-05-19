"""Apply / ramp a fixed DC voltage on an AO channel via ADwin.

Direct port of the ADwin branch of `Apply_fixed_voltage.m`. Other branches
(OptoDAC, Zurich Instruments MFLI, 24-bit oversampled gate) are intentionally
omitted — APS2 measurements never used them.

ADwin parameter slots (from Fixed_AO_<model>.bas):

  Par 6   AO_address
  Par 9   AO output channel
  Par 41  start voltage (bin)
  Par 42  set voltage (bin)
"""

from __future__ import annotations
from dataclasses import dataclass

from hardware.adwin import ADwin
from utilities.adwin_helpers import get_delays, convert_V_to_bin
from .base import ADwinSettings


@dataclass
class FixedVoltageParams:
    output: int = 2          # AO channel
    startV: float = 0.0
    setV: float = 0.0
    ramp_rate: float = 0.5   # V/s
    V_per_V: float = 1.0
    wait_for_finish: bool = True

    # Filled in by run()
    startV_bin: int = 0
    setV_bin: int = 0
    startV_new: float = 0.0
    setV_new: float = 0.0
    process_delay: int = 0
    time_per_point: float = 0.0


@dataclass
class GateRamp:
    """Gate that gets ramped before a measurement and back after it.

    Matches the `Gate` struct in legacy `Make_IV.m`. `enabled=False` means
    skip the ramp entirely.
    """
    enabled: bool = False
    output: int = 2
    initV: float = 0.0
    targetV: float = 0.0
    endV: float = 0.0
    ramp_rate: float = 1.0     # V/s
    waiting_time: float = 0.0  # s, sleep after each ramp
    V_per_V: float = 1.0


class FixedVoltage:
    """Ramp an AO channel from startV → setV at the given V/s."""

    SLOT = 3

    def __init__(self, adwin: ADwin, settings: ADwinSettings):
        self.adwin = adwin
        self.settings = settings

    def apply(self, p: FixedVoltageParams) -> FixedVoltageParams:
        s = self.settings
        a = self.adwin

        # 1. Address + channel
        a.set_par(6, s.AO_address)
        a.set_par(9, p.output)

        # 2. Voltages → bins
        sv_bin, sv_new = convert_V_to_bin(p.startV / p.V_per_V,
                                          s.output_min, s.output_max,
                                          s.output_resolution)
        ev_bin, ev_new = convert_V_to_bin(p.setV / p.V_per_V,
                                          s.output_min, s.output_max,
                                          s.output_resolution)
        p.startV_bin = sv_bin - 1
        p.setV_bin = ev_bin - 1
        p.startV_new = sv_new * p.V_per_V
        p.setV_new = ev_new * p.V_per_V
        a.set_par(41, p.startV_bin)
        a.set_par(42, p.setV_bin)

        # 3. Ramp rate → process delay
        # Frequency of bin updates = ramp_rate / volts-per-bin / V_per_V
        volts_per_bin = (s.output_max - s.output_min) / (2 ** s.output_resolution)
        max_frequency = p.ramp_rate / volts_per_bin / p.V_per_V
        p.time_per_point = 1.0 / max_frequency
        p.process_delay, _ = get_delays(max_frequency, 0, s.clockfrequency)
        a.set_processdelay(self.SLOT, p.process_delay)

        # 4. Run
        a.start_process(self.SLOT)
        if p.wait_for_finish:
            while a.process_status(self.SLOT) == 1:
                pass
        return p
