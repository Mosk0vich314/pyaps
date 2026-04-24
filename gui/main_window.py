"""
Main application window.
Replaces STG2.mlapp with a PySide6 GUI.
"""

from __future__ import annotations
import io
import queue as _queue
import sys
import threading
import numpy as np
import cv2

# Thread-safe console queue — any thread can put a line here
_console_q: _queue.SimpleQueue = _queue.SimpleQueue()

from PySide6.QtWidgets import (
    QMainWindow, QWidget, QHBoxLayout, QVBoxLayout, QGridLayout,
    QGroupBox, QPushButton, QLabel, QDoubleSpinBox, QSpinBox,
    QComboBox, QLineEdit, QCheckBox, QSizePolicy, QMessageBox,
    QScrollArea, QFrame, QTabWidget, QStatusBar, QFormLayout, QTextEdit,
    QSlider,
)
from PySide6.QtCore import Qt, QTimer, Signal, QObject
from PySide6.QtGui import QImage, QPixmap, QFont

from hardware.stage_controller import StageController
from hardware.camera import Camera
from hardware.device import LAYOUTS, generate_device_coordinates
from hardware.switch_box import SwitchBox
from matlab_bridge.engine_session import MatlabBridge
from utilities.process_yield import process_yield


# Charcoal / teal / orange palette with saturn red + yellow accents
C_BG       = "#1a1c1f"   # deep charcoal
C_PANEL    = "#242629"   # panel charcoal
C_PANEL_2  = "#2c2f33"   # raised
C_BORDER   = "#3a3e44"
C_TEXT     = "#e4e6ea"
C_TEXT_DIM = "#a8adb4"
C_TEAL     = "#2dd4bf"
C_TEAL_D   = "#14b8a6"
C_ORANGE   = "#f97316"
C_ORANGE_D = "#c2410c"
C_RED      = "#dc2626"   # saturn red
C_YELLOW   = "#eab308"
C_GREEN    = "#65a30d"

APP_STYLESHEET = f"""
QMainWindow, QWidget {{ background: {C_BG}; color: {C_TEXT};
    font-family: 'Segoe UI', Arial, sans-serif; font-size: 10pt; }}
QGroupBox {{
    background: {C_PANEL};
    border: 1px solid {C_BORDER};
    border-left: 3px solid {C_TEAL};
    border-radius: 6px;
    margin-top: 16px;
    padding: 14px 8px 8px 8px;
}}
QGroupBox::title {{
    subcontrol-origin: margin;
    subcontrol-position: top left;
    left: 12px;
    padding: 0 6px;
    color: {C_TEAL};
    font-weight: 700;
    font-size: 10pt;
    letter-spacing: 0.5px;
}}
QGroupBox[accent="orange"]  {{ border-left-color: {C_ORANGE}; }}
QGroupBox[accent="orange"]::title {{ color: {C_ORANGE}; }}
QGroupBox[accent="yellow"]  {{ border-left-color: {C_YELLOW}; }}
QGroupBox[accent="yellow"]::title {{ color: {C_YELLOW}; }}
QGroupBox[accent="red"]     {{ border-left-color: {C_RED}; }}
QGroupBox[accent="red"]::title {{ color: #f87171; }}
QGroupBox[accent="green"]   {{ border-left-color: {C_GREEN}; }}
QGroupBox[accent="green"]::title {{ color: #a3e635; }}
QGroupBox[accent="teal_d"]  {{ border-left-color: {C_TEAL_D}; }}
QGroupBox[accent="teal_d"]::title {{ color: {C_TEAL_D}; }}

QLabel {{ color: {C_TEXT}; background: transparent; }}
QPushButton {{
    background: #33363b;
    color: {C_TEXT};
    border: 1px solid {C_BORDER};
    border-radius: 4px;
    padding: 6px 10px;
    min-height: 20px;
}}
QPushButton:hover   {{ background: #3d4046; border-color: {C_TEAL_D}; }}
QPushButton:pressed {{ background: #2a2d31; }}
QPushButton:disabled{{ background: #24262a; color: #6a6d73; border-color: #30333a; }}
QDoubleSpinBox, QSpinBox, QLineEdit, QComboBox {{
    background: {C_BG};
    color: {C_TEXT};
    border: 1px solid {C_BORDER};
    border-radius: 3px;
    padding: 3px 6px;
    min-height: 20px;
    selection-background-color: {C_TEAL_D};
}}
QDoubleSpinBox:focus, QSpinBox:focus, QLineEdit:focus, QComboBox:focus {{
    border-color: {C_TEAL};
}}
QCheckBox {{ spacing: 6px; }}
QCheckBox::indicator {{ width: 14px; height: 14px; border: 1px solid {C_BORDER};
    border-radius: 3px; background: {C_BG}; }}
QCheckBox::indicator:checked {{ background: {C_TEAL}; border-color: {C_TEAL}; }}

QStatusBar {{ background: #101214; color: {C_TEAL}; border-top: 1px solid {C_BORDER}; }}
QStatusBar QLabel {{ color: {C_TEAL}; }}

QScrollArea {{ border: none; background: transparent; }}
QScrollBar:vertical {{ background: {C_BG}; width: 10px; margin: 2px; border-radius: 5px; }}
QScrollBar::handle:vertical {{ background: {C_BORDER}; border-radius: 5px; min-height: 24px; }}
QScrollBar::handle:vertical:hover {{ background: {C_TEAL_D}; }}
QScrollBar::add-line:vertical, QScrollBar::sub-line:vertical {{ height: 0; }}
QScrollBar::add-page:vertical, QScrollBar::sub-page:vertical {{ background: transparent; }}
QScrollBar:horizontal {{ background: {C_BG}; height: 10px; margin: 2px; border-radius: 5px; }}
QScrollBar::handle:horizontal {{ background: {C_BORDER}; border-radius: 5px; min-width: 24px; }}
QScrollBar::handle:horizontal:hover {{ background: {C_TEAL_D}; }}
QScrollBar::add-line:horizontal, QScrollBar::sub-line:horizontal {{ width: 0; }}
QScrollBar::add-page:horizontal, QScrollBar::sub-page:horizontal {{ background: transparent; }}
"""



# ---------------------------------------------------------------------------
# stdout redirector — only writes to queue, never touches Qt from write()
# ---------------------------------------------------------------------------

class _ConsoleIO(io.TextIOBase):
    def __init__(self):
        super().__init__()
        self._buf = ""

    def write(self, s: str) -> int:
        self._buf += s
        while "\n" in self._buf:
            line, self._buf = self._buf.split("\n", 1)
            _console_q.put(line)
        return len(s)

    def flush(self):
        if self._buf:
            _console_q.put(self._buf)
            self._buf = ""


# ---------------------------------------------------------------------------
# Signal bridge (camera runs in a background thread → must post to GUI thread)
# ---------------------------------------------------------------------------

class _Signals(QObject):
    new_frame = Signal(np.ndarray)


# ---------------------------------------------------------------------------
# Main window
# ---------------------------------------------------------------------------

# Versioning for tracking updates
VERSION = "1.0.9"

class MainWindow(QMainWindow):
    UNIT_MULT = 1e-3   # µm → mm (device coordinates are in µm, stage works in mm)

    def __init__(self):
        super().__init__()
        self.setWindowTitle(f"PYAPS — Probe Station Control (v{VERSION})")
        self.setMinimumSize(1280, 860)
        self.resize(1720, 1000)
        self.setStyleSheet(APP_STYLESHEET)

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
        # Redirect stdout to queue (safe: write() never touches Qt)
        sys.stdout = _ConsoleIO()
        # QTimer drains the queue in the main thread every 100 ms
        self._console_timer = QTimer(self)
        self._console_timer.setInterval(100)
        self._console_timer.timeout.connect(self._drain_console)
        self._console_timer.start()
        self._start_camera()
        self._connect_matlab()

    # ------------------------------------------------------------------
    # UI construction
    # ------------------------------------------------------------------

    def _build_ui(self):
        central = QWidget()
        self.setCentralWidget(central)
        root = QHBoxLayout(central)
        root.setContentsMargins(8, 8, 8, 8)
        root.setSpacing(8)

        # Left column: camera expands, Run panel fixed below
        left = QVBoxLayout()
        left.setSpacing(8)
        cam = self._build_camera_panel()
        cam.setSizePolicy(QSizePolicy.Expanding, QSizePolicy.Expanding)
        left.addWidget(cam, stretch=1)
        left.addWidget(self._build_camera_controls(), stretch=0)
        left.addWidget(self._build_run_box(), stretch=0)

        # Right column: tabs — Stage / Settings / Console
        tabs = QTabWidget()
        tabs.setMinimumWidth(440)
        tabs.addTab(self._wrap_scroll(self._build_motor_panel()),    "Stage")
        tabs.addTab(self._wrap_scroll(self._build_settings_panel()), "Measurement Settings")
        tabs.addTab(self._build_console_panel(),                     "Console")

        root.addLayout(left, stretch=3)
        root.addWidget(tabs, stretch=2)

        self._status_bar = QStatusBar()
        self.setStatusBar(self._status_bar)
        self._status_bar.showMessage("Ready")

    def _wrap_scroll(self, widget: QWidget) -> QScrollArea:
        scroll = QScrollArea()
        scroll.setWidget(widget)
        scroll.setWidgetResizable(True)
        scroll.setFrameShape(QFrame.NoFrame)
        scroll.setHorizontalScrollBarPolicy(Qt.ScrollBarAlwaysOff)
        return scroll

    def _build_camera_panel(self) -> QGroupBox:
        box = QGroupBox("Camera")
        box.setProperty("accent", "teal_d")
        layout = QVBoxLayout(box)
        layout.setContentsMargins(10, 16, 10, 10)
        self._camera_label = QLabel("No camera feed")
        self._camera_label.setAlignment(Qt.AlignCenter)
        self._camera_label.setMinimumSize(640, 480)
        self._camera_label.setSizePolicy(QSizePolicy.Expanding, QSizePolicy.Expanding)
        self._camera_label.setStyleSheet(
            f"background: #0a0c0f; color: {C_TEAL_D}; border: 1px solid {C_BORDER}; border-radius: 4px;"
        )
        layout.addWidget(self._camera_label)
        return box

    def _build_camera_controls(self) -> QGroupBox:
        box = QGroupBox("Camera Controls")
        box.setProperty("accent", "teal_d")
        grid = QGridLayout(box)
        grid.setContentsMargins(10, 14, 10, 8)
        grid.setHorizontalSpacing(8)
        grid.setVerticalSpacing(4)

        # Row 0: Resolution + Auto-exposure
        grid.addWidget(QLabel("Resolution:"), 0, 0)
        self._cam_res_combo = QComboBox()
        self._cam_res_combo.addItem("(discovering...)")
        self._cam_res_combo.setEnabled(False)
        self._cam_res_combo.currentIndexChanged.connect(self._on_resolution_changed)
        grid.addWidget(self._cam_res_combo, 0, 1, 1, 2)

        self._cam_auto_exp = QCheckBox("Auto exposure")
        self._cam_auto_exp.setChecked(True)
        self._cam_auto_exp.toggled.connect(self._on_auto_exp_toggled)
        grid.addWidget(self._cam_auto_exp, 0, 3, 1, 2)

        # Row 1: Exposure | Brightness
        grid.addWidget(QLabel("Exposure:"), 1, 0)
        self._cam_exp_slider = QSlider(Qt.Horizontal)
        self._cam_exp_slider.setRange(-13, 0)
        self._cam_exp_slider.valueChanged.connect(self._on_exposure_changed)
        grid.addWidget(self._cam_exp_slider, 1, 1)
        self._cam_exp_val = QLabel("—")
        self._cam_exp_val.setMinimumWidth(30)
        grid.addWidget(self._cam_exp_val, 1, 2)

        grid.addWidget(QLabel("Brightness:"), 1, 3)
        self._cam_bri_slider = QSlider(Qt.Horizontal)
        self._cam_bri_slider.setRange(-128, 255)  # widen since cameras vary
        self._cam_bri_slider.valueChanged.connect(self._on_brightness_changed)
        grid.addWidget(self._cam_bri_slider, 1, 4)
        self._cam_bri_val = QLabel("—")
        self._cam_bri_val.setMinimumWidth(40)
        grid.addWidget(self._cam_bri_val, 1, 5)

        return box

    def _on_resolution_changed(self, idx: int):
        data = self._cam_res_combo.itemData(idx)
        if data is None:
            return
        w, h = data
        self._camera.set_resolution(w, h)

    def _on_auto_exp_toggled(self, enabled: bool):
        self._camera.set_auto_exposure(enabled)
        self._cam_exp_slider.setEnabled(not enabled)
        print(f"[camera] auto-exposure {'ON' if enabled else 'OFF'}")

    def _on_exposure_changed(self, val: int):
        self._cam_exp_val.setText(str(val))
        self._camera.set_exposure(float(val))

    def _on_brightness_changed(self, val: int):
        self._cam_bri_val.setText(str(val))
        self._camera.set_brightness(float(val))

    def _populate_resolutions(self):
        # Force auto-exposure ON at startup so the image is usable out of the box.
        self._camera.set_auto_exposure(True)

        # Use the predefined list instead of probing — probing disrupts the camera pipeline.
        from hardware.camera import _PROBE_RESOLUTIONS
        cur_w, cur_h = self._camera.get_current_resolution()
        self._cam_res_combo.blockSignals(True)
        self._cam_res_combo.clear()
        for w, h in _PROBE_RESOLUTIONS:
            self._cam_res_combo.addItem(f"{w} x {h}", (w, h))
        for i in range(self._cam_res_combo.count()):
            if self._cam_res_combo.itemData(i) == (cur_w, cur_h):
                self._cam_res_combo.setCurrentIndex(i)
                break
        self._cam_res_combo.setEnabled(True)
        self._cam_res_combo.blockSignals(False)

        # Sync sliders to the camera's actual current values (single get each — cheap).
        import cv2 as _cv2
        cur_exp = int(self._camera.get_property(_cv2.CAP_PROP_EXPOSURE))
        cur_bri = int(self._camera.get_property(_cv2.CAP_PROP_BRIGHTNESS))
        print(f"[camera] current exposure={cur_exp}  brightness={cur_bri}")

        self._cam_exp_slider.blockSignals(True)
        self._cam_exp_slider.setValue(max(-13, min(0, cur_exp)))
        self._cam_exp_slider.blockSignals(False)
        self._cam_exp_val.setText(str(self._cam_exp_slider.value()))

        self._cam_bri_slider.blockSignals(True)
        self._cam_bri_slider.setValue(max(-128, min(255, cur_bri)))
        self._cam_bri_slider.blockSignals(False)
        self._cam_bri_val.setText(str(self._cam_bri_slider.value()))

    def _build_motor_panel(self) -> QGroupBox:
        box = QGroupBox("Stage")
        box.setProperty("accent", "teal_d")
        box.setSizePolicy(QSizePolicy.Preferred, QSizePolicy.Minimum)
        v = QVBoxLayout(box)
        v.setSpacing(10)
        v.setContentsMargins(10, 16, 10, 10)

        # ----- Position readback (top, always visible) -----
        self._pos_label = QLabel("X: --    Y: --    Z: --")
        mono = QFont("Consolas", 11); mono.setBold(True)
        self._pos_label.setFont(mono)
        self._pos_label.setStyleSheet(
            f"background: #0f1114; color: {C_TEAL}; padding: 10px; border-radius: 4px; "
            f"border: 1px solid {C_BORDER};"
        )
        self._pos_label.setAlignment(Qt.AlignCenter)
        v.addWidget(self._pos_label)

        # ----- Jog -----
        jog_box = QGroupBox("Jog"); jog_box.setProperty("accent", "teal_d")
        jog = QGridLayout(jog_box)
        jog.setHorizontalSpacing(8); jog.setVerticalSpacing(8)
        jog.setContentsMargins(10, 14, 10, 10)
        for r in range(5):
            jog.setRowMinimumHeight(r, 34)

        jog.addWidget(QLabel("Step (mm):"), 0, 0)
        self._step_mm = QDoubleSpinBox()
        self._step_mm.setRange(0.001, 10.0)
        self._step_mm.setValue(0.1)
        self._step_mm.setDecimals(3)
        self._step_mm.setSingleStep(0.01)
        jog.addWidget(self._step_mm, 0, 1)
        jog.addWidget(QLabel("Rot step (°):"), 0, 2)
        self._rot_step = QDoubleSpinBox()
        self._rot_step.setRange(0.01, 90.0)
        self._rot_step.setValue(1.0)
        jog.addWidget(self._rot_step, 0, 3)

        btn_y_pos = QPushButton("▲ +Y")
        btn_y_neg = QPushButton("▼ -Y")
        btn_x_neg = QPushButton("◀ -X")
        btn_x_pos = QPushButton("▶ +X")
        btn_z_pos = QPushButton("▲ +Z")
        btn_z_neg = QPushButton("▼ -Z")
        btn_rot_pos = QPushButton("↻ +θ")
        btn_rot_neg = QPushButton("↺ -θ")

        for b in (btn_y_pos, btn_y_neg, btn_x_neg, btn_x_pos,
                  btn_z_pos, btn_z_neg, btn_rot_pos, btn_rot_neg):
            b.setMinimumHeight(32)
            b.setSizePolicy(QSizePolicy.Expanding, QSizePolicy.Fixed)

        # XY D-pad in cols 0-2, Z column in col 3
        jog.addWidget(btn_y_pos, 1, 1)
        jog.addWidget(btn_x_neg, 2, 0)
        center = QLabel("XY");  center.setAlignment(Qt.AlignCenter)
        center.setStyleSheet("color: #7aa7ff; font-weight: 600;")
        jog.addWidget(center,   2, 1)
        jog.addWidget(btn_x_pos, 2, 2)
        jog.addWidget(btn_y_neg, 3, 1)
        jog.addWidget(btn_z_pos, 1, 3)
        z_lbl = QLabel("Z"); z_lbl.setAlignment(Qt.AlignCenter)
        z_lbl.setStyleSheet("color: #7aa7ff; font-weight: 600;")
        jog.addWidget(z_lbl,     2, 3)
        jog.addWidget(btn_z_neg, 3, 3)

        # Rotation row
        jog.addWidget(btn_rot_neg, 4, 0, 1, 2)
        jog.addWidget(btn_rot_pos, 4, 2, 1, 2)

        btn_y_pos.clicked.connect(lambda: self._jog_y(+1))
        btn_y_neg.clicked.connect(lambda: self._jog_y(-1))
        btn_x_neg.clicked.connect(lambda: self._jog_x(-1))
        btn_x_pos.clicked.connect(lambda: self._jog_x(+1))
        btn_z_pos.clicked.connect(lambda: self._jog_z(+1))
        btn_z_neg.clicked.connect(lambda: self._jog_z(-1))
        btn_rot_pos.clicked.connect(lambda: self._jog_theta(+1))
        btn_rot_neg.clicked.connect(lambda: self._jog_theta(-1))

        v.addWidget(jog_box)

        # ----- Absolute Move -----
        abs_box = QGroupBox("Absolute Move (mm)"); abs_box.setProperty("accent", "yellow")
        ag = QGridLayout(abs_box)
        ag.setHorizontalSpacing(8); ag.setVerticalSpacing(8)
        ag.setContentsMargins(10, 14, 10, 10)
        for r in range(3):
            ag.setRowMinimumHeight(r, 32)
        ag.setColumnStretch(1, 1)
        self._goto_x = QDoubleSpinBox(); self._goto_x.setRange(-100, 100); self._goto_x.setDecimals(4); self._goto_x.setSingleStep(0.1)
        self._goto_y = QDoubleSpinBox(); self._goto_y.setRange(-100, 100); self._goto_y.setDecimals(4); self._goto_y.setSingleStep(0.1)
        self._goto_z = QDoubleSpinBox(); self._goto_z.setRange(-100, 100); self._goto_z.setDecimals(4); self._goto_z.setSingleStep(0.1)
        btn_go_x = QPushButton("Go X"); btn_go_x.clicked.connect(self._goto_x_clicked)
        btn_go_y = QPushButton("Go Y"); btn_go_y.clicked.connect(self._goto_y_clicked)
        btn_go_z = QPushButton("Go Z"); btn_go_z.clicked.connect(self._goto_z_clicked)
        for b in (btn_go_x, btn_go_y, btn_go_z):
            b.setMinimumHeight(28)
        ag.addWidget(QLabel("X:"), 0, 0); ag.addWidget(self._goto_x, 0, 1); ag.addWidget(btn_go_x, 0, 2)
        ag.addWidget(QLabel("Y:"), 1, 0); ag.addWidget(self._goto_y, 1, 1); ag.addWidget(btn_go_y, 1, 2)
        ag.addWidget(QLabel("Z:"), 2, 0); ag.addWidget(self._goto_z, 2, 1); ag.addWidget(btn_go_z, 2, 2)
        v.addWidget(abs_box)

        # ----- Homing & Zero -----
        home_box = QGroupBox("Homing / Zero"); home_box.setProperty("accent", "orange")
        hg = QGridLayout(home_box)
        hg.setHorizontalSpacing(8); hg.setVerticalSpacing(8)
        hg.setContentsMargins(10, 14, 10, 10)
        for r in range(3):
            hg.setRowMinimumHeight(r, 32)

        btn_home_x   = QPushButton("Home X")
        btn_home_y   = QPushButton("Home Y")
        btn_home_z   = QPushButton("Home Z")
        btn_home_all = QPushButton("Home ALL (Z→X→Y)")
        for b in (btn_home_x, btn_home_y, btn_home_z, btn_home_all):
            b.setMinimumHeight(28)
        btn_home_all.setStyleSheet(f"background: {C_ORANGE_D}; color: white; font-weight: 600;")
        btn_zero = QPushButton("Zero XY at current position")
        btn_zero.setStyleSheet(f"background: {C_TEAL_D}; color: #0a1412; font-weight: 600;")

        btn_home_x.clicked.connect(lambda: self._run_in_thread(lambda: self._stage.home_x()))
        btn_home_y.clicked.connect(lambda: self._run_in_thread(lambda: self._stage.home_y()))
        btn_home_z.clicked.connect(lambda: self._run_in_thread(lambda: self._stage.home_z()))
        btn_home_all.clicked.connect(lambda: self._run_in_thread(lambda: self._stage.home_all()))
        btn_zero.clicked.connect(self._zero_xy)

        hg.addWidget(btn_home_x, 0, 0)
        hg.addWidget(btn_home_y, 0, 1)
        hg.addWidget(btn_home_z, 0, 2)
        hg.addWidget(btn_home_all, 1, 0, 1, 3)
        hg.addWidget(btn_zero,     2, 0, 1, 3)
        v.addWidget(home_box)

        # ----- Emergency stop -----
        btn_stop = QPushButton("⛔ EMERGENCY STOP")
        btn_stop.setStyleSheet(
            f"background: {C_RED}; color: white; font-weight: bold; "
            f"font-size: 11pt; padding: 10px; border-radius: 4px; "
            f"border: 1px solid #7f1d1d;"
        )
        btn_stop.setMinimumHeight(40)
        btn_stop.clicked.connect(self._emergency_stop)
        v.addWidget(btn_stop)

        self._pos_timer = QTimer(self)
        self._pos_timer.setInterval(500)
        self._pos_timer.timeout.connect(self._update_position)
        self._pos_timer.start()

        return box

    # ------------------------------------------------------------------
    # Measurement tab
    # ------------------------------------------------------------------

    def _build_settings_panel(self) -> QWidget:
        root = QWidget()
        v = QVBoxLayout(root)
        v.setContentsMargins(8, 8, 8, 8)
        v.setSpacing(10)
        v.addWidget(self._build_sample_box())
        v.addWidget(self._build_stage_settings_box())
        v.addWidget(self._build_iv_box())
        v.addWidget(self._build_gate_box())
        v.addWidget(self._build_stability_box())
        v.addWidget(self._build_needle_box())
        v.addWidget(self._build_utilities_box())
        v.addStretch()
        return root

    def _build_stage_settings_box(self) -> QGroupBox:
        box = QGroupBox("Stage Hardware Settings"); box.setProperty("accent", "teal")
        form = QFormLayout(box)
        form.setContentsMargins(10, 16, 10, 10)
        form.setVerticalSpacing(6)

        self._motor_vel = self._ispin(1000, 1000000, 100000)
        self._motor_acc = self._ispin(100, 100000, 5000)
        
        btn_apply = QPushButton("Apply Velocity/Accel to ALL Motors")
        btn_apply.clicked.connect(self._apply_motor_settings)
        btn_apply.setStyleSheet(f"background: {C_TEAL_D}; color: #0a1412; font-weight: 600;")

        form.addRow("Velocity (microsteps/s):", self._motor_vel)
        form.addRow("Acceleration (steps/s²):", self._motor_acc)
        form.addRow(btn_apply)
        return box

    def _apply_motor_settings(self):
        if not self._stage:
            QMessageBox.warning(self, "Not ready", "Stage not initialized.")
            return
        vel = self._motor_vel.value()
        acc = self._motor_acc.value()
        
        def task():
            print(f"--- Applying hardware settings: Vel={vel}, Acc={acc} ---")
            for m in (self._stage.motor_x, self._stage.motor_y, self._stage.motor_z, self._stage.motor_rot):
                if m:
                    try:
                        m.velocity = vel
                        m.acceleration = acc
                        m.set_setting("velocity", vel)
                        m.set_setting("acceleration", acc)
                        print(f"[{m.name}] Applied.")
                    except Exception as e:
                        print(f"[{m.name}] Failed: {e}")
            print("--- Settings applied. ---")
            
        threading.Thread(target=task, daemon=True).start()

    # --- Sample/save info (shared by single-device + chip-scan) ---
    def _build_sample_box(self) -> QGroupBox:
        box = QGroupBox("Sample"); box.setProperty("accent", "teal_d")
        form = QFormLayout(box)
        form.setContentsMargins(10, 16, 10, 10)
        form.setVerticalSpacing(6)

        self._sample_name = QLineEdit("sample")
        self._save_dir    = QLineEdit("C:/Data")
        self._threshold   = QDoubleSpinBox()
        self._threshold.setRange(0.0, 1e-6)
        self._threshold.setDecimals(10)
        self._threshold.setValue(1e-9)
        self._threshold.setSingleStep(1e-10)

        form.addRow("Sample name:", self._sample_name)
        form.addRow("Save dir:",    self._save_dir)
        form.addRow("Contact threshold (A):", self._threshold)
        return box

    # --- IV sweep ---
    def _build_iv_box(self) -> QGroupBox:
        box = QGroupBox("IV Sweep"); box.setProperty("accent", "orange")
        form = QFormLayout(box)
        form.setContentsMargins(10, 16, 10, 10)
        form.setVerticalSpacing(6)

        self._iv_start    = self._spin(-10, 10, 4, -0.5)
        self._iv_max      = self._spin(-10, 10, 4,  0.5)
        self._iv_points   = self._ispin(2, 100000, 501)
        self._iv_scanrate = self._ispin(1000, 10_000_000, 450000)
        self._iv_settle   = self._spin(0, 10, 3, 0.0)

        form.addRow("Start V:",      self._iv_start)
        form.addRow("Max V:",        self._iv_max)
        form.addRow("Points:",       self._iv_points)
        form.addRow("Scan rate:",    self._iv_scanrate)
        form.addRow("Settling (s):", self._iv_settle)
        return box

    # --- Gate sweep ---
    def _build_gate_box(self) -> QGroupBox:
        box = QGroupBox("Gate Sweep"); box.setProperty("accent", "yellow")
        form = QFormLayout(box)
        form.setContentsMargins(10, 16, 10, 10)
        form.setVerticalSpacing(6)

        self._gate_start  = self._spin(-100, 100, 3, -50.0)
        self._gate_max    = self._spin(-100, 100, 3,  50.0)
        self._gate_points = self._ispin(2, 100000, 1001)
        self._gate_bias   = self._spin(-10, 10, 4, 0.1)

        form.addRow("Start V:",   self._gate_start)
        form.addRow("Max V:",     self._gate_max)
        form.addRow("Points:",    self._gate_points)
        form.addRow("Fixed bias V:", self._gate_bias)
        return box

    # --- Stability diagram ---
    def _build_stability_box(self) -> QGroupBox:
        box = QGroupBox("Stability Diagram"); box.setProperty("accent", "red")
        form = QFormLayout(box)
        form.setContentsMargins(10, 16, 10, 10)
        form.setVerticalSpacing(6)

        self._stab_iv_min    = self._spin(-10, 10, 4, -0.2)
        self._stab_iv_max    = self._spin(-10, 10, 4,  0.2)
        self._stab_iv_points = self._ispin(2, 100000, 1001)
        self._stab_gate_min  = self._spin(-100, 100, 3, -0.5)
        self._stab_gate_max  = self._spin(-100, 100, 3,  0.5)
        self._stab_gate_dV   = self._spin(0.0001, 10, 4, 0.001)
        self._stab_gate_wait = self._spin(0, 10, 3, 0.1)

        form.addRow("IV min V:",   self._stab_iv_min)
        form.addRow("IV max V:",   self._stab_iv_max)
        form.addRow("IV points:",  self._stab_iv_points)
        form.addRow("Gate min V:", self._stab_gate_min)
        form.addRow("Gate max V:", self._stab_gate_max)
        form.addRow("Gate dV:",    self._stab_gate_dV)
        form.addRow("Wait (s):",   self._stab_gate_wait)
        return box

    # --- Needle alignment ---
    def _build_needle_box(self) -> QGroupBox:
        box = QGroupBox("Needle Alignment"); box.setProperty("accent", "teal_d")
        form = QFormLayout(box)
        form.setContentsMargins(10, 16, 10, 10)
        form.setVerticalSpacing(6)

        self._needle_amp  = self._spin(0, 20, 2, 10.0)
        self._needle_freq = self._spin(0.1, 1000, 2, 10.0)
        self._needle_rt   = self._spin(0.1, 60, 2, 1.2)

        form.addRow("Amplitude V:", self._needle_amp)
        form.addRow("Frequency Hz:", self._needle_freq)
        form.addRow("Runtime (s):", self._needle_rt)
        return box

    # --- Run selection + buttons ---
    def _build_run_box(self) -> QGroupBox:
        box = QGroupBox("Run"); box.setProperty("accent", "green")
        grid = QGridLayout(box)
        grid.setContentsMargins(10, 16, 10, 10)
        grid.setHorizontalSpacing(8); grid.setVerticalSpacing(8)

        self._do_iv   = QCheckBox("IV sweep")
        self._do_gate = QCheckBox("Gate sweep")
        self._do_stab = QCheckBox("Stability diagram")
        self._do_iv.setChecked(True)
        grid.addWidget(self._do_iv,   0, 0)
        grid.addWidget(self._do_gate, 0, 1)
        grid.addWidget(self._do_stab, 0, 2)

        # Single-device
        grid.addWidget(QLabel("Device label:"), 1, 0)
        self._single_dev_label = QLineEdit("dev1")
        grid.addWidget(self._single_dev_label, 1, 1, 1, 2)

        btn_single = QPushButton("▶  Run on current device")
        btn_single.setStyleSheet(f"background: {C_TEAL_D}; color: #0a1412; font-weight: 700;")
        btn_single.setMinimumHeight(32)
        btn_single.clicked.connect(self._run_single)
        grid.addWidget(btn_single, 2, 0, 1, 3)

        # Chip scan controls
        grid.addWidget(self._hline(), 3, 0, 1, 3)
        grid.addWidget(QLabel("Layout:"),       4, 0)
        self._layout_combo = QComboBox()
        self._layout_combo.addItems(list(LAYOUTS.keys()))
        grid.addWidget(self._layout_combo,      4, 1, 1, 2)

        grid.addWidget(QLabel("Start device:"), 5, 0)
        self._start_dev = QSpinBox()
        self._start_dev.setRange(1, 9999)
        self._start_dev.setValue(1)
        grid.addWidget(self._start_dev,         5, 1, 1, 2)

        self._test_move_check = QCheckBox("Test movement only (no measurements)")
        grid.addWidget(self._test_move_check,   6, 0, 1, 3)

        btn_scan = QPushButton("▶  START CHIP SCAN")
        btn_scan.setStyleSheet(f"background: {C_ORANGE}; color: #1a0a02; font-weight: 700;")
        btn_scan.setMinimumHeight(36)
        btn_scan.clicked.connect(self._start_chip_scan)
        grid.addWidget(btn_scan, 7, 0, 1, 2)

        btn_scan_stop = QPushButton("■  STOP")
        btn_scan_stop.setStyleSheet(f"background: {C_RED}; color: white; font-weight: 700;")
        btn_scan_stop.setMinimumHeight(36)
        btn_scan_stop.clicked.connect(self._stop_chip_scan)
        grid.addWidget(btn_scan_stop, 7, 2)

        return box

    def _build_utilities_box(self) -> QGroupBox:
        box = QGroupBox("Utilities"); box.setProperty("accent", "orange")
        h = QHBoxLayout(box)
        h.setContentsMargins(10, 16, 10, 10)
        h.setSpacing(6)
        btn_needle = QPushButton("Needle Align")
        btn_needle.clicked.connect(self._run_needle_alignment)
        btn_switch = QPushButton("Switch Box")
        btn_switch.clicked.connect(self._toggle_switch_box)
        btn_yield  = QPushButton("Analyze Yield")
        btn_yield.clicked.connect(self._analyze_yield)
        for b in (btn_needle, btn_switch, btn_yield):
            b.setMinimumHeight(30)
            h.addWidget(b)
        return box

    def _build_console_panel(self) -> QWidget:
        root = QWidget()
        v = QVBoxLayout(root)
        v.setContentsMargins(8, 8, 8, 8)
        v.setSpacing(4)
        self._console = QTextEdit()
        self._console.setReadOnly(True)
        self._console.setFont(QFont("Consolas", 9))
        self._console.setStyleSheet(
            f"background: #0a0c0f; color: #a0e8a0; border: 1px solid {C_BORDER};"
        )
        btn_clear = QPushButton("Clear")
        btn_clear.setMaximumWidth(80)
        btn_clear.clicked.connect(self._console.clear)
        v.addWidget(self._console, stretch=1)
        v.addWidget(btn_clear)
        return root

    def _drain_console(self):
        updated = False
        try:
            while True:
                line = _console_q.get_nowait()
                self._console.append(line)
                updated = True
        except _queue.Empty:
            pass
        if updated:
            sb = self._console.verticalScrollBar()
            sb.setValue(sb.maximum())

    # --- widget factory helpers ---
    def _spin(self, lo: float, hi: float, decimals: int, value: float) -> QDoubleSpinBox:
        w = QDoubleSpinBox()
        w.setRange(lo, hi); w.setDecimals(decimals); w.setValue(value)
        return w

    def _ispin(self, lo: int, hi: int, value: int) -> QSpinBox:
        w = QSpinBox()
        w.setRange(lo, hi); w.setValue(value)
        return w

    def _hline(self) -> QFrame:
        f = QFrame()
        f.setFrameShape(QFrame.HLine)
        f.setStyleSheet("color: #3a3d43; background: #3a3d43; max-height: 1px;")
        return f

    # ------------------------------------------------------------------
    # Camera
    # ------------------------------------------------------------------

    def _start_camera(self):
        self._camera.on_frame = lambda f: self._signals.new_frame.emit(f)
        try:
            self._camera.start()
            QTimer.singleShot(500, self._populate_resolutions)
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
        threading.Thread(target=self._stage_init_thread, daemon=True).start()
        threading.Thread(target=self._matlab_init_thread, daemon=True).start()

    def _stage_init_thread(self):
        try:
            self._stage = StageController()
        except Exception as e:
            QTimer.singleShot(0, lambda: QMessageBox.warning(
                self, "Stage init warning",
                f"Stage init error:\n{e}\n\nMotor controls unavailable."
            ))

    def _matlab_init_thread(self):
        try:
            self._matlab.start()
        except Exception as e:
            QTimer.singleShot(0, lambda: QMessageBox.warning(
                self, "MATLAB init warning",
                f"MATLAB init error:\n{e}\n\nMeasurement routines unavailable."
            ))

    # ------------------------------------------------------------------
    # Motor jog
    # ------------------------------------------------------------------

    def _jog_x(self, sign: int):
        self._run_in_thread(lambda: self._stage.move_x(sign * self._step_mm.value()))

    def _jog_y(self, sign: int):
        self._run_in_thread(lambda: self._stage.move_y(sign * self._step_mm.value()))

    def _jog_z(self, sign: int):
        self._run_in_thread(lambda: self._stage.move_z(sign * self._step_mm.value()))

    def _jog_theta(self, sign: int):
        self._run_in_thread(lambda: self._stage.move_theta(sign * self._rot_step.value()))

    def _zero_xy(self):
        if self._stage:
            self._stage.zero_xy()
            self._update_position()

    def _goto_x_clicked(self):
        self._run_in_thread(lambda: self._stage.move_to_x(self._goto_x.value()))

    def _goto_y_clicked(self):
        self._run_in_thread(lambda: self._stage.move_to_y(self._goto_y.value()))

    def _goto_z_clicked(self):
        self._run_in_thread(lambda: self._stage.move_to_z(self._goto_z.value()))

    def _emergency_stop(self):
        self._flag_stop = True
        if self._stage:
            self._stage.stop()

    def _update_position(self):
        if not self._stage:
            return
        try:
            x = self._stage.get_position_x()
            y = self._stage.get_position_y()
            z = self._stage.get_position_z()
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

        # Generate coordinates from the selected layout
        layout_cls = LAYOUTS[self._layout_combo.currentText()]
        self._device_coordinates = generate_device_coordinates(layout_cls())
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
                self._run_routines(f"{sample}-{dev_id}")

        self._set_status("Scan complete." if not self._flag_stop else "Scan stopped.")

    def _ask_alignment(self, event: threading.Event):
        QMessageBox.information(
            self, "Alignment",
            f"Align on device {self._start_dev.value()}, then click OK."
        )
        event.set()

    # ------------------------------------------------------------------
    # Utilities
    # ------------------------------------------------------------------

    def _run_needle_alignment(self):
        if not self._matlab.is_started:
            QMessageBox.warning(self, "MATLAB not ready",
                                "MATLAB engine is still initializing.")
            return
        settings = self._build_settings("NeedleAlign", dev_label="align")
        threading.Thread(
            target=lambda: self._matlab.run_needle_alignment(settings),
            daemon=True
        ).start()

    def _toggle_switch_box(self):
        if not self._matlab.is_started:
            QMessageBox.warning(self, "MATLAB not ready",
                                "MATLAB engine is still initializing.")
            return
        threading.Thread(
            target=self._matlab.run_switch_box, daemon=True
        ).start()

    def _analyze_yield(self):
        folder = self._save_dir.text()
        sample = self._sample_name.text()
        if not folder or not sample:
            QMessageBox.warning(self, "Missing info",
                                "Enter save dir and sample name first.")
            return
        threshold = self._threshold.value()
        result = process_yield(folder, sample, threshold=threshold)
        if not result:
            QMessageBox.information(self, "Yield", "No matching files found.")
            return
        passed = sum(1 for v in result.values() if v)
        total  = len(result)
        QMessageBox.information(
            self, "Yield",
            f"Yield for '{sample}': {passed}/{total} devices above {threshold:.2g} A"
        )

    def _build_settings(self, m_type: str, dev_label: str = "") -> dict:
        """Common MATLAB settings struct (sample/save/ADwin + type-specific params)."""
        base = {
            "filename": dev_label or self._sample_name.text(),
            "sample":   self._sample_name.text(),
            "save_dir": self._save_dir.text(),
            "type":     m_type,
            "ADwin":    "GoldII",
            "auto":     "FEMTO",
            "res4p":    0,
            "T":        300,
        }
        if m_type == "IV":
            base.update({
                "iv_startV":    self._iv_start.value(),
                "iv_maxV":      self._iv_max.value(),
                "iv_points":    self._iv_points.value(),
                "iv_scanrate":  self._iv_scanrate.value(),
                "iv_settling":  self._iv_settle.value(),
            })
        elif m_type == "Gatesweep":
            base.update({
                "gate_startV": self._gate_start.value(),
                "gate_maxV":   self._gate_max.value(),
                "gate_points": self._gate_points.value(),
                "bias_setV":   self._gate_bias.value(),
            })
        elif m_type == "Stability":
            base.update({
                "iv_minV":       self._stab_iv_min.value(),
                "iv_maxV":       self._stab_iv_max.value(),
                "iv_points":     self._stab_iv_points.value(),
                "gate_minV":     self._stab_gate_min.value(),
                "gate_maxV":     self._stab_gate_max.value(),
                "gate_dV":       self._stab_gate_dV.value(),
                "gate_waiting":  self._stab_gate_wait.value(),
            })
        elif m_type == "NeedleAlign":
            base.update({
                "needle_amp":  self._needle_amp.value(),
                "needle_freq": self._needle_freq.value(),
                "needle_runtime": self._needle_rt.value(),
            })
        return base

    def _run_routines(self, dev_label: str):
        try:
            if self._do_iv.isChecked():
                self._set_status(f"{dev_label}: IV sweep…")
                self._matlab.run_iv_aps2(self._build_settings("IV", dev_label))
            if self._do_gate.isChecked():
                self._set_status(f"{dev_label}: Gate sweep…")
                self._matlab.run_gate_aps2(self._build_settings("Gatesweep", dev_label))
            if self._do_stab.isChecked():
                self._set_status(f"{dev_label}: Stability diagram…")
                self._matlab.run_stability_aps2(self._build_settings("Stability", dev_label))
            self._set_status(f"{dev_label}: done")
        except Exception as e:
            self._set_status(f"Error on {dev_label}: {e}")
            print(f"Routine error on {dev_label}: {e}")

    # ------------------------------------------------------------------
    # Single device run
    # ------------------------------------------------------------------

    def _run_single(self):
        if not self._sample_name.text():
            QMessageBox.warning(self, "No sample", "Enter a sample name.")
            return
        if not self._matlab.is_started:
            QMessageBox.warning(self, "MATLAB not ready",
                                "MATLAB engine is still initializing.")
            return
        if not (self._do_iv.isChecked() or self._do_gate.isChecked() or self._do_stab.isChecked()):
            QMessageBox.warning(self, "No measurement selected",
                                "Tick at least one measurement (IV / Gate / Stability).")
            return
        label = self._single_dev_label.text().strip() or "dev"
        dev_label = f"{self._sample_name.text()}-{label}"
        threading.Thread(target=self._run_routines, args=(dev_label,), daemon=True).start()

    # ------------------------------------------------------------------
    # Helpers
    # ------------------------------------------------------------------

    def _run_in_thread(self, fn):
        if self._stage:
            threading.Thread(target=fn, daemon=True).start()

    def _set_status(self, msg: str):
        QTimer.singleShot(0, lambda: self._status_bar.showMessage(msg))

    # ------------------------------------------------------------------
    # Cleanup
    # ------------------------------------------------------------------

    def closeEvent(self, event):
        self._flag_stop = True
        self._console_timer.stop()
        sys.stdout = sys.__stdout__
        self._camera.stop()
        self._matlab.stop()
        if self._stage:
            self._stage.close()
        event.accept()
