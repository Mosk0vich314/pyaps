"""
Main application window.
Replaces STG2.mlapp with a PySide6 GUI.
"""

from __future__ import annotations
import threading
import numpy as np
import cv2

from PySide6.QtWidgets import (
    QMainWindow, QWidget, QHBoxLayout, QVBoxLayout, QGridLayout,
    QGroupBox, QPushButton, QLabel, QDoubleSpinBox, QSpinBox,
    QComboBox, QLineEdit, QCheckBox, QSizePolicy, QMessageBox,
)
from PySide6.QtCore import Qt, QTimer, Signal, QObject
from PySide6.QtGui import QImage, QPixmap, QFont

from hardware.stage_controller import StageController
from hardware.camera import Camera
from matlab_bridge.engine_session import MatlabBridge


# ---------------------------------------------------------------------------
# Signal bridge (camera runs in a background thread → must post to GUI thread)
# ---------------------------------------------------------------------------

class _Signals(QObject):
    new_frame = Signal(np.ndarray)


# ---------------------------------------------------------------------------
# Main window
# ---------------------------------------------------------------------------

class MainWindow(QMainWindow):
    UNIT_MULT = 1e-6   # µm → meters

    def __init__(self):
        super().__init__()
        self.setWindowTitle("PYAPS — Probe Station Control")
        self.setMinimumSize(1200, 800)

        self._stage: StageController | None = None
        self._camera = Camera(device_index=0, fps=10)
        self._matlab = MatlabBridge()
        self._signals = _Signals()
        self._signals.new_frame.connect(self._on_frame)

        self._flag_stop = False
        self._flag_pause = False
        self._chip_ref_dev_id: int | None = None
        self._device_coordinates: dict | None = None

        self._build_ui()
        self._start_camera()
        self._connect_matlab()

    # ------------------------------------------------------------------
    # UI construction
    # ------------------------------------------------------------------

    def _build_ui(self):
        central = QWidget()
        self.setCentralWidget(central)
        root = QHBoxLayout(central)

        # Left column: camera + chip scan
        left = QVBoxLayout()
        left.addWidget(self._build_camera_panel())
        left.addWidget(self._build_chip_scan_panel())

        # Right column: motors + measurements
        right = QVBoxLayout()
        right.addWidget(self._build_motor_panel())
        right.addWidget(self._build_measurement_panel())
        right.addStretch()

        root.addLayout(left, stretch=3)
        root.addLayout(right, stretch=2)

    def _build_camera_panel(self) -> QGroupBox:
        box = QGroupBox("Camera")
        layout = QVBoxLayout(box)
        self._camera_label = QLabel("No camera feed")
        self._camera_label.setAlignment(Qt.AlignCenter)
        self._camera_label.setMinimumSize(640, 480)
        self._camera_label.setStyleSheet("background: black; color: white;")
        layout.addWidget(self._camera_label)
        return box

    def _build_motor_panel(self) -> QGroupBox:
        box = QGroupBox("Stage")
        grid = QGridLayout(box)

        # Step size
        grid.addWidget(QLabel("Step (mm):"), 0, 0)
        self._step_mm = QDoubleSpinBox()
        self._step_mm.setRange(0.001, 10.0)
        self._step_mm.setValue(0.1)
        self._step_mm.setDecimals(3)
        grid.addWidget(self._step_mm, 0, 1, 1, 2)

        # XY jog
        btn_y_pos = QPushButton("+Y")
        btn_y_neg = QPushButton("-Y")
        btn_x_neg = QPushButton("-X")
        btn_x_pos = QPushButton("+X")
        btn_z_pos = QPushButton("+Z")
        btn_z_neg = QPushButton("-Z")

        grid.addWidget(btn_y_pos, 1, 1)
        grid.addWidget(btn_x_neg, 2, 0)
        grid.addWidget(btn_x_pos, 2, 2)
        grid.addWidget(btn_y_neg, 3, 1)
        grid.addWidget(btn_z_pos, 1, 3)
        grid.addWidget(btn_z_neg, 3, 3)
        grid.addWidget(QLabel("Z"), 2, 3, Qt.AlignCenter)

        btn_y_pos.clicked.connect(lambda: self._jog_y(+1))
        btn_y_neg.clicked.connect(lambda: self._jog_y(-1))
        btn_x_neg.clicked.connect(lambda: self._jog_x(-1))
        btn_x_pos.clicked.connect(lambda: self._jog_x(+1))
        btn_z_pos.clicked.connect(lambda: self._jog_z(+1))
        btn_z_neg.clicked.connect(lambda: self._jog_z(-1))

        # Rotation
        grid.addWidget(QLabel("Rot step (°):"), 4, 0)
        self._rot_step = QDoubleSpinBox()
        self._rot_step.setRange(0.01, 90.0)
        self._rot_step.setValue(1.0)
        grid.addWidget(self._rot_step, 4, 1)
        btn_rot_pos = QPushButton("+θ")
        btn_rot_neg = QPushButton("-θ")
        btn_rot_pos.clicked.connect(lambda: self._jog_theta(+1))
        btn_rot_neg.clicked.connect(lambda: self._jog_theta(-1))
        grid.addWidget(btn_rot_pos, 4, 2)
        grid.addWidget(btn_rot_neg, 4, 3)

        # Zero + Stop
        btn_zero = QPushButton("Zero XY")
        btn_zero.setStyleSheet("background: #2a6099; color: white;")
        btn_zero.clicked.connect(self._zero_xy)
        btn_stop = QPushButton("STOP")
        btn_stop.setStyleSheet("background: #cc3333; color: white; font-weight: bold;")
        btn_stop.clicked.connect(self._emergency_stop)
        grid.addWidget(btn_zero, 5, 0, 1, 2)
        grid.addWidget(btn_stop, 5, 2, 1, 2)

        # Position readback
        self._pos_label = QLabel("X: --  Y: --  Z: --")
        self._pos_label.setFont(QFont("Courier", 9))
        grid.addWidget(self._pos_label, 6, 0, 1, 4)

        self._pos_timer = QTimer()
        self._pos_timer.setInterval(500)
        self._pos_timer.timeout.connect(self._update_position)

        return box

    def _build_chip_scan_panel(self) -> QGroupBox:
        box = QGroupBox("Chip Scan")
        layout = QGridLayout(box)

        layout.addWidget(QLabel("Layout:"), 0, 0)
        self._layout_combo = QComboBox()
        self._layout_combo.addItems(["twoTGNR", "doubleQDot"])
        layout.addWidget(self._layout_combo, 0, 1)

        layout.addWidget(QLabel("Start device:"), 1, 0)
        self._start_dev = QSpinBox()
        self._start_dev.setRange(1, 999)
        self._start_dev.setValue(1)
        layout.addWidget(self._start_dev, 1, 1)

        layout.addWidget(QLabel("Sample name:"), 2, 0)
        self._sample_name = QLineEdit("sample")
        layout.addWidget(self._sample_name, 2, 1)

        layout.addWidget(QLabel("Save dir:"), 3, 0)
        self._save_dir = QLineEdit("C:/Data")
        layout.addWidget(self._save_dir, 3, 1)

        self._test_move_check = QCheckBox("Test movement only")
        layout.addWidget(self._test_move_check, 4, 0, 1, 2)

        btn_start = QPushButton("START CHIP SCAN")
        btn_start.setStyleSheet("background: #2a8a2a; color: white; font-weight: bold;")
        btn_start.clicked.connect(self._start_chip_scan)
        layout.addWidget(btn_start, 5, 0)

        btn_stop = QPushButton("STOP")
        btn_stop.setStyleSheet("background: #cc3333; color: white;")
        btn_stop.clicked.connect(self._stop_chip_scan)
        layout.addWidget(btn_stop, 5, 1)

        self._scan_status = QLabel("Idle")
        layout.addWidget(self._scan_status, 6, 0, 1, 2)

        return box

    def _build_measurement_panel(self) -> QGroupBox:
        box = QGroupBox("Measurements")
        layout = QVBoxLayout(box)

        layout.addWidget(QLabel("Contact threshold:"))
        self._threshold = QDoubleSpinBox()
        self._threshold.setRange(0.0, 1e-6)
        self._threshold.setDecimals(10)
        self._threshold.setValue(1e-9)
        self._threshold.setSingleStep(1e-10)
        layout.addWidget(self._threshold)

        self._do_iv    = QCheckBox("IV sweep")
        self._do_gate  = QCheckBox("Gate sweep")
        self._do_stab  = QCheckBox("Stability diagram")
        self._do_iv.setChecked(True)
        layout.addWidget(self._do_iv)
        layout.addWidget(self._do_gate)
        layout.addWidget(self._do_stab)

        btn_single = QPushButton("Run on current device")
        btn_single.clicked.connect(self._run_single)
        layout.addWidget(btn_single)

        return box

    # ------------------------------------------------------------------
    # Camera
    # ------------------------------------------------------------------

    def _start_camera(self):
        self._camera.on_frame = lambda f: self._signals.new_frame.emit(f)
        try:
            self._camera.start()
        except RuntimeError as e:
            self._camera_label.setText(f"Camera error:\n{e}")

    def _on_frame(self, frame: np.ndarray):
        rgb = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
        h, w, ch = rgb.shape
        img = QImage(rgb.data, w, h, ch * w, QImage.Format_RGB888)
        self._camera_label.setPixmap(
            QPixmap.fromImage(img).scaled(
                self._camera_label.size(), Qt.KeepAspectRatio, Qt.SmoothTransformation
            )
        )

    # ------------------------------------------------------------------
    # MATLAB bridge
    # ------------------------------------------------------------------

    def _connect_matlab(self):
        threading.Thread(target=self._matlab_init_thread, daemon=True).start()

    def _matlab_init_thread(self):
        try:
            self._matlab.start()
            self._stage = StageController()
            self._pos_timer.start()
        except Exception as e:
            # Post to GUI thread via a single-shot timer
            QTimer.singleShot(0, lambda: QMessageBox.warning(
                self, "Init warning",
                f"Hardware init error:\n{e}\n\nMotor/ADwin functions unavailable."
            ))

    # ------------------------------------------------------------------
    # Motor jog
    # ------------------------------------------------------------------

    def _jog_x(self, sign: int):
        self._run_in_thread(lambda: self._stage.move_x(sign * self._step_mm.value() / 1000))

    def _jog_y(self, sign: int):
        self._run_in_thread(lambda: self._stage.move_y(sign * self._step_mm.value() / 1000))

    def _jog_z(self, sign: int):
        self._run_in_thread(lambda: self._stage.move_z(sign * self._step_mm.value() / 1000))

    def _jog_theta(self, sign: int):
        self._run_in_thread(lambda: self._stage.move_theta(sign * self._rot_step.value()))

    def _zero_xy(self):
        if self._stage:
            self._stage.zero_xy()

    def _emergency_stop(self):
        self._flag_stop = True
        if self._stage:
            self._stage.stop()

    def _update_position(self):
        if not self._stage:
            return
        try:
            x = self._stage.get_position_x() * 1000
            y = self._stage.get_position_y() * 1000
            z = self._stage.get_position_z() * 1000
            self._pos_label.setText(f"X: {x:.3f} mm  Y: {y:.3f} mm  Z: {z:.3f} mm")
        except Exception:
            pass

    # ------------------------------------------------------------------
    # Chip scan
    # ------------------------------------------------------------------

    def _start_chip_scan(self):
        if not self._stage:
            QMessageBox.warning(self, "Not ready", "Stage not connected.")
            return
        self._flag_stop = False
        self._flag_pause = False
        threading.Thread(target=self._chip_scan_thread, daemon=True).start()

    def _stop_chip_scan(self):
        self._flag_stop = True

    def _chip_scan_thread(self):
        from PySide6.QtWidgets import QInputDialog
        self._set_status("Waiting for alignment...")

        # Ask user to align — must run in GUI thread
        aligned = threading.Event()
        QTimer.singleShot(0, lambda: self._ask_alignment(aligned))
        aligned.wait()

        self._chip_ref_dev_id = self._start_dev.value()
        self._stage.zero_xy()
        self._set_status(f"Scanning from device {self._chip_ref_dev_id}...")

        coords = self._device_coordinates
        if not coords:
            self._set_status("No device coordinates loaded.")
            return

        dev_ids  = coords["deviceID"]
        dev_x    = coords["deviceX"]
        dev_y    = coords["deviceY"]
        ref_x    = dev_x[self._chip_ref_dev_id - 1]
        ref_y    = dev_y[self._chip_ref_dev_id - 1]
        save_dir = self._save_dir.text()
        sample   = self._sample_name.text()

        for i, dev_id in enumerate(dev_ids[self._chip_ref_dev_id - 1:], start=self._chip_ref_dev_id):
            if self._flag_stop:
                break

            if dev_id != self._chip_ref_dev_id:
                target_x = (dev_x[i - 1] - ref_x) * self.UNIT_MULT
                target_y = -(dev_y[i - 1] - ref_y) * self.UNIT_MULT
                self._stage.move_to_x(target_x)
                self._stage.move_to_y(target_y)

            self._set_status(f"Device {dev_id}")

            if not self._test_move_check.isChecked():
                self._run_routines(dev_id, save_dir, sample)

        self._set_status("Scan complete." if not self._flag_stop else "Scan stopped.")

    def _ask_alignment(self, event: threading.Event):
        QMessageBox.information(
            self, "Alignment",
            f"Align on device {self._start_dev.value()}, then click OK."
        )
        event.set()

    def _run_routines(self, dev_id: int, save_dir: str, sample: str):
        dev_label = f"{sample}-{dev_id}"
        try:
            if self._do_iv.isChecked():
                self._matlab.run_iv(dev_label, save_dir)
            if self._do_gate.isChecked():
                self._matlab.run_gate_sweep(dev_label, save_dir)
            if self._do_stab.isChecked():
                self._matlab.run_stability(dev_label, save_dir)
        except Exception as e:
            print(f"Routine error on device {dev_id}: {e}")

    # ------------------------------------------------------------------
    # Single device run
    # ------------------------------------------------------------------

    def _run_single(self):
        if not self._sample_name.text():
            QMessageBox.warning(self, "No sample", "Enter a sample name.")
            return
        dev_label = f"{self._sample_name.text()}-manual"
        threading.Thread(
            target=self._run_routines,
            args=(dev_label, self._save_dir.text(), self._sample_name.text()),
            daemon=True
        ).start()

    # ------------------------------------------------------------------
    # Helpers
    # ------------------------------------------------------------------

    def _run_in_thread(self, fn):
        if self._stage:
            threading.Thread(target=fn, daemon=True).start()

    def _set_status(self, msg: str):
        QTimer.singleShot(0, lambda: self._scan_status.setText(msg))

    # ------------------------------------------------------------------
    # Cleanup
    # ------------------------------------------------------------------

    def closeEvent(self, event):
        self._flag_stop = True
        self._camera.stop()
        self._matlab.stop()
        if self._stage:
            self._stage.close()
        event.accept()
