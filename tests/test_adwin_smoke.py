"""Minimal ADwin smoke test.

Sets a handful of Par / FPar slots to recognizable values. Open ADwin Inspector
(FPar_TPar tool) and verify the same values appear there. If they do, the boot
+ DLL chain is working end-to-end from Python.

Run from the repo root:
    .venv\\Scripts\\python.exe tests\\test_adwin_smoke.py
"""

from __future__ import annotations
import sys, pathlib
sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent.parent))

from hardware.adwin import get_adwin


def main():
    adw = get_adwin("GoldII")

    # --- Set integer parameters ---
    test_ints = {
        1:  42,
        2:  1234,
        10: 18,      # input_resolution
        25: 7,
        50: 11,
    }
    for idx, val in test_ints.items():
        adw.set_par(idx, val)
    print(f"Wrote Par: {test_ints}")

    # --- Set float parameters ---
    test_floats = {
        1: 3.14159,
        9: 1.0e-6,
        27: 7.0,     # log10(1e7) — what Run_sweep would set for a 1e7 V/A FEMTO
    }
    for idx, val in test_floats.items():
        adw.set_fpar(idx, val)
    print(f"Wrote FPar: {test_floats}")

    # --- Read them back to confirm round-trip ---
    print("\nRead back:")
    for idx in test_ints:
        got = adw.get_par(idx)
        ok = "OK" if got == test_ints[idx] else "MISMATCH"
        print(f"  Par[{idx}]  = {got}   (wrote {test_ints[idx]})  {ok}")
    for idx in test_floats:
        got = adw.get_fpar(idx)
        # ADwin stores floats as 32-bit; tolerate single-precision rounding.
        ok = "OK" if abs(got - test_floats[idx]) < abs(test_floats[idx]) * 1e-6 + 1e-9 else "MISMATCH"
        print(f"  FPar[{idx}] = {got}   (wrote {test_floats[idx]})  {ok}")

    print("\n→ Now open the ADwin Inspector (FPar_TPar tool) and confirm "
          "the same values are visible there.")


if __name__ == "__main__":
    main()
