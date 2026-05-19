# PYAPS - Probe Station Control

Automated Probe Station control software written in Python (PySide6). All
measurement logic runs natively in Python — there is no MATLAB dependency.
The ADwin real-time DAQ is driven directly via the official `ADwin` Python
package; previous .bas/.TBx ADwin process binaries are kept under
`adwin_processes/` and loaded by name at runtime.

## Project Structure

- `main.pyw`: Application entry point.
- `gui/`: PySide6 UI.
    - `main_window.py`: main window (camera, stage, chip-scan).
    - `realtime_plot.py`: pyqtgraph widgets for live sweep / stability plots.
- `hardware/`: device drivers.
    - `adwin.py`: low-level ADwin wrapper (boot, load_process, par/data/process).
    - `stage_controller.py`, `stepper_motor.py`: ESCO stepper motor stage.
    - `camera.py`: OpenCV camera capture.
    - `device.py`: chip layout coordinate generator.
    - `switch_box.py`: ADwin DIO switch box (Single_DO process).
- `measurements/`: native Python measurement classes.
    - `base.py`: `BaseMeasurement` + `ADwinSettings` dataclass.
    - `sweep.py`: ADwin sweep + real-time plot polling (port of Run_sweep.m + Realtime_sweep.m).
    - `fixed_voltage.py`: ADwin AO ramp (port of Apply_fixed_voltage.m, ADwin branch only).
    - `iv.py`, `gate_sweep.py`, `stability.py`, `needle_alignment.py`: APS2 measurement types.
- `utilities/`:
    - `adwin_helpers.py`: get_delays / convert_V_to_bin / convert_bin_to_V.
    - `process_yield.py`: yield analysis from saved IV files.
    - `cam_settings.py`: camera utilities.
- `adwin_processes/{GoldII,ProII}/`: compiled ADwin process binaries (.TBx / .TCx)
  and their .bas source. Loaded by `ADwin.load_process(name)`.
- `Trash/`: temporarily-kept legacy code (MATLAB scripts, old matlab_bridge)
  pending removal once the Python port is verified on hardware. Not used at runtime.

## Architectural Notes

1. **No MATLAB**: ADwin is driven directly from Python via the `ADwin`
   package. The MATLAB engine has been removed.
2. **ADwin process binaries**: each measurement family corresponds to a
   compiled ADwin process loaded into a fixed slot:
       Sweep_AO     → slot 1
       Read_AI      → slot 2
       Fixed_AO     → slot 3
       Single_DO    → slot 5
       Waveform_AO  → slot 6
   These are loaded by name (e.g. `"Sweep_AO_read_AI_single_auto_FEMTO"`) from
   `adwin_processes/<model>/`. Parameter slots inside each process are
   contracts defined by the `.bas` source — do not change them in Python
   without recompiling the corresponding `.bas` → `.TBx`.
3. **Real-time plots**: pyqtgraph widgets polling ADwin Par 25 (sweep counter)
   and reading new samples in chunks via `GetData_Double`. Replaces
   MATLAB's `Realtime_sweep.m` / `Realtime_sweep3D.m` figures.
4. **Hardware Communication**:
    - Motors: serial (115200 baud) using a custom command-response protocol.
    - Camera: OpenCV (prefers DSHOW backend).
    - ADwin: Ethernet via the ADwin DLL.
5. **Threading**:
    - GUI runs on the main thread.
    - Camera capture runs in a separate thread, emitting frames via Qt signals.
    - Long-running measurements/motor moves run in background threads.
6. **Units**:
    - Stage: mm for linear axes, degrees for rotation.
    - Device Layouts: microns (µm).
    - Conversion (`UNIT_MULT = 1e-3`) handled in `MainWindow`.

## Key Dependencies

- PySide6 (GUI)
- pyqtgraph (real-time plots)
- pyserial (motor control)
- opencv-python (camera)
- ADwin (Jaeger Python wrapper for the ADwin DLL)
- numpy, scipy (data + .mat saving)

## Development Workflow

- Run `python main.pyw` to start the application.
- Logs for motor communication are written to `motor_debug.log`.
- Measurement data saved as `.mat` files (round-trips with the legacy
  MATLAB analysis scripts: contains `Settings` + `Data` structs).
