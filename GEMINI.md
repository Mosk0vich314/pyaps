# PYAPS - Probe Station Control

Automated Probe Station control software written in Python (PySide6) with a MATLAB bridge for measurement routines.

## Project Structure

- `main.pyw`: Entry point for the application.
- `gui/`: Contains the main window and UI logic.
- `hardware/`: Drivers and controllers for hardware components.
    - `stage_controller.py`: High-level control for the 4-axis (X, Y, Z, Rot) stage.
    - `stepper_motor.py`: Low-level serial driver for ESCO stepper motors.
    - `camera.py`: OpenCV-based camera capture.
    - `device.py`: Chip layout definitions and coordinate generation.
    - `switch_box.py`: Interface for the hardware switch box.
- `matlab_bridge/`: Communication with MATLAB.
    - `engine_session.py`: Starts and manages a headless MATLAB engine, loads necessary paths, and executes MATLAB-based measurement routines.
- `measurements/`: Python wrappers around MATLAB measurement classes.
- `utilities/`: Helper functions.
    - `process_yield.py`: Analyzes yield from IV measurement files.
    - `cam_settings.py`: Camera settings/utilities.
- `LakeShore-Measurement-scripts-Adwin/`: Submodule containing legacy and core MATLAB scripts for instrument control via ADwin.

## Architectural Notes

1. **MATLAB Bridge**: The core measurement logic resides in MATLAB. Python acts as the orchestration layer and provides the modern GUI.
2. **Hardware Communication**:
    - Motors: Serial (115200 baud) using a custom command-response protocol.
    - Camera: OpenCV (prefers DSHOW backend).
    - ADwin: Controlled via MATLAB.
3. **Threading**:
    - The GUI runs on the main thread.
    - Camera capture runs in a separate thread and emits frames to the GUI.
    - MATLAB initialization and measurement routines run in background threads to avoid freezing the UI.
    - Motor movements are also executed in background threads.
4. **Units**:
    - Stage: mm for linear axes, degrees for rotation.
    - Device Layouts: Microns (µm).
    - Conversion between µm and mm is handled in `MainWindow` (`UNIT_MULT = 1e-3`).

## Key Dependencies

- PySide6 (GUI)
- pyserial (Motor control)
- opencv-python (Camera)
- matlabengine (MATLAB bridge)
- numpy/scipy (Data processing)

## Development Workflow

- Run `python main.pyw` to start the application.
- Logs for motor communication are written to `motor_debug.log`.
- Measurement data is typically saved as `.mat` files.
