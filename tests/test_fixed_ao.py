"""Process-loading + AO ramp smoke test.

Loads the Fixed_AO ADwin process (slot 3), ramps an AO channel from 0 V to a
target voltage at a slow ramp rate, and reports the final bin/voltage. Validate
externally by either:
  - measuring the AO output with a multimeter (most direct), or
  - watching Par 41 / Par 42 / Par 9 in ADwin Inspector while it runs.

Defaults: AO channel 2, target +1.000 V, 0.5 V/s ramp. Edit at the bottom if
you want a different channel or voltage.

Run from the repo root:
    python tests\\test_fixed_ao.py
"""

from __future__ import annotations
import sys
import pathlib
import time

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent.parent))

from hardware.adwin import get_adwin
from measurements.base import ADwinSettings
from measurements.fixed_voltage import FixedVoltage, FixedVoltageParams


def ramp_to(channel: int, target_v: float, ramp_rate: float = 0.5):
    adw = get_adwin("GoldII")
    settings = ADwinSettings(ADwin="GoldII")

    if "Fixed_AO" not in adw._loaded:
        adw.load_process("Fixed_AO")

    fixed = FixedVoltage(adw, settings)

    # 1. Ramp 0 → target
    print(f"\n--- Ramping AO{channel}: 0 V → {target_v:+.3f} V at {ramp_rate} V/s ---")
    p = FixedVoltageParams(output=channel, startV=0.0, setV=target_v,
                           ramp_rate=ramp_rate, wait_for_finish=True)
    fixed.apply(p)
    print(f"startV bin = {p.startV_bin}   (snapped to {p.startV_new:+.6f} V)")
    print(f"setV   bin = {p.setV_bin}   (snapped to {p.setV_new:+.6f} V)")
    print(f"process_delay = {p.process_delay}  ({p.time_per_point*1e6:.2f} µs/step)")
    print("Holding at target for 10 s — check multimeter / Inspector now.")
    time.sleep(10.0)

    # 2. Ramp back to 0
    print(f"\n--- Ramping AO{channel}: {target_v:+.3f} V → 0 V ---")
    p_back = FixedVoltageParams(output=channel, startV=target_v, setV=0.0,
                                ramp_rate=ramp_rate, wait_for_finish=True)
    fixed.apply(p_back)
    print("Back to 0 V.")


if __name__ == "__main__":
    # Edit these for your setup. AO channels are 1-indexed.
    AO_CHANNEL = 2
    TARGET_V   = 1.000
    RAMP_RATE  = 0.5  # V/s

    ramp_to(AO_CHANNEL, TARGET_V, RAMP_RATE)
