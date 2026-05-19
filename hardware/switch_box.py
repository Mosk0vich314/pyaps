"""Switch-box: digital pulse on an ADwin DIO line.

Port of APS2/Hardware/switchBox.m. Uses the Single_DO process (slot 5).

ADwin parameter slots (from Single_DO_<model>.bas):

  Par 50   DIO bit number
  Par 51   pulse trigger (0 → 1 → 0 fires the pulse)
"""

from __future__ import annotations
import time

from hardware.adwin import ADwin, get_adwin


class SwitchBox:
    SLOT = 5
    PROCESS = "Single_DO"

    def __init__(self, bit: int = 11, adwin: ADwin | None = None):
        self.bit = bit
        self.adwin = adwin or get_adwin()
        if self.PROCESS not in self.adwin._loaded:
            self.adwin.load_process(self.PROCESS)
        self.adwin.set_processdelay(self.SLOT, 100_000)
        self.adwin.set_par(50, self.bit)

    def pulse(self, hold_s: float = 0.01):
        a = self.adwin
        a.start_process(self.SLOT)
        a.set_par(51, 0)
        a.set_par(51, 1)
        time.sleep(hold_s)
        a.set_par(51, 0)
        a.stop_process(self.SLOT)
