"""AO → AI loopback sweep with live plot.

Requires: physical cable connecting AO channel 1 to AI channel 1 on the ADwin.

Ramps AO1 through a triangle wave -1 V → +1 V → -1 V while simultaneously
reading AI1 via the Sweep_AO process, and plots the result live. A correct
loopback gives a straight line of slope 1 (output voltage == input voltage).

Notes
-----
- The Sweep_AO process is built around a current-measurement workflow where
  the ADC reading is divided by a FEMTO transimpedance gain. We set that gain
  to **1.0** here so the "current" axis is actually the AI voltage in volts.
  That keeps the loopback math trivial: AO_V → plot_Y should be a y=x line.
- If the plot is flat at zero, the AI channel isn't seeing the AO output.
- If the plot is offset by a constant, there's a ground-loop or wiring offset.
- If the plot has the right shape but wrong magnitude, your ADC_gain is wrong.

Run from the repo root:
    python tests\\test_loopback_sweep.py
"""

from __future__ import annotations
import sys
import pathlib

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent.parent))

from PySide6.QtWidgets import QApplication

from hardware.adwin import get_adwin
from measurements.base import ADwinSettings
from measurements.sweep import Sweep, SweepParams
from gui.realtime_plot import RealtimeSweepPlot


def main():
    app = QApplication.instance() or QApplication(sys.argv)

    adw = get_adwin("GoldII")

    # ADC gain = 1.0 so the plotted "current" is the raw AI voltage.
    # ADC_gain is the per-channel exponent the ADwin script uses; 0 = no extra scaling.
    settings = ADwinSettings(
        ADwin="GoldII",
        ADC=[1.0, "off", "off", "off", "off", "off", "off", "off"],
        ADC_gain=[0, 0, 0, 0, 0, 0, 0, 0],
    )

    # Pick the Sweep_AO binary that reads a single AI channel.
    sweep_params = SweepParams(
        process="Sweep_AO_read_AI_single_auto_FEMTO",
        output=1,
        startV=0.0,
        minV=-1.0,
        maxV=1.0,
        dV=0.005,
        scanrate=450_000,
        settling_time=0.0,
        V_per_V=1.0,
        # points_av=0 → auto = scanrate / 50 Hz = 9000 samples/step (legacy convention)
    )

    if sweep_params.process not in adw._loaded:
        adw.load_process(sweep_params.process)

    plot = RealtimeSweepPlot(
        "AO1 → AI1 loopback",
        n_adc=settings.N_ADC,
        x_range=(sweep_params.minV, sweep_params.maxV),
        x_label="AO1 commanded (V)",
        y_label="AI1 read (V)",
    )
    plot.show()

    sweep = Sweep(adw, settings)
    result = sweep.run(sweep_params, plot=plot)

    # Quick numeric sanity check: peak-to-peak of the readback should be ~2.0 V
    ai = result.current[0][:, 0]
    print(f"\nAI1 min = {ai.min():+.4f} V")
    print(f"AI1 max = {ai.max():+.4f} V")
    print(f"AI1 peak-to-peak = {ai.max() - ai.min():.4f} V "
          f"(expected ≈ {sweep_params.maxV - sweep_params.minV:.2f} V)")
    print("\nClose the plot window to exit.")
    app.exec()


if __name__ == "__main__":
    main()
