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
VERSION = "1.0.10"

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
        self._init_hardware()

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
        tabs.addTab(self._wrap_scroll(self._build_settings_panel()), "Settings")
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

    _CL_ACTIVE_STYLE = (
        "QPushButton { background: %(bg)s; color: %(fg)s; font-weight: 700; "
        "border: 1px solid %(border)s; %(radius)s padding: 6px; }"
    )
    _CL_INACTIVE_STYLE = (
        "QPushButton { background: #24262a; color: #6a6d73; font-weight: 500; "
        "border: 1px solid #30333a; %(radius)s padding: 6px; }"
        "QPushButton:hover { background: #2c2f33; color: #a8adb4; }"
    )

    def _set_cl_mode(self, closed_loop: bool, push_to_stage: bool = True):
        if push_to_stage and self._stage:
            self._stage.use_closed_loop = closed_loop
        # Joined segmented look: left button rounded on left, right button rounded on right.
        left_radius  = "border-top-left-radius: 4px; border-bottom-left-radius: 4px; border-top-right-radius: 0; border-bottom-right-radius: 0;"
        right_radius = "border-top-right-radius: 4px; border-bottom-right-radius: 4px; border-top-left-radius: 0; border-bottom-left-radius: 0;"
        if closed_loop:
            self._cl_btn_loop.setStyleSheet(self._CL_ACTIVE_STYLE % {
                "bg": C_TEAL_D, "fg": "#0a1412", "border": C_TEAL, "radius": left_radius})
            self._cl_btn_direct.setStyleSheet(self._CL_INACTIVE_STYLE % {"radius": right_radius})
        else:
            self._cl_btn_loop.setStyleSheet(self._CL_INACTIVE_STYLE % {"radius": left_radius})
            self._cl_btn_direct.setStyleSheet(self._CL_ACTIVE_STYLE % {
                "bg": C_ORANGE_D, "fg": "white", "border": C_ORANGE, "radius": right_radius})
        if push_to_stage:
            print(f"[Stage] Absolute motion mode: {'Closed-Loop (Python)' if closed_loop else 'Firmware Direct'}")

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
        
        # Segmented mode switch: two buttons, active one is lit.
        mode_row = QHBoxLayout()
        mode_row.setContentsMargins(0, 0, 0, 0)
        mode_row.setSpacing(0)
        self._cl_btn_loop = QPushButton("Closed-Loop")
        self._cl_btn_direct = QPushButton("Firmware Direct")
        for b in (self._cl_btn_loop, self._cl_btn_direct):
            b.setMinimumHeight(30)
            b.setSizePolicy(QSizePolicy.Expanding, QSizePolicy.Fixed)
        self._cl_btn_loop.clicked.connect(lambda: self._set_cl_mode(True))
        self._cl_btn_direct.clicked.connect(lambda: self._set_cl_mode(False))
        mode_row.addWidget(self._cl_btn_loop)
        mode_row.addWidget(self._cl_btn_direct)
        mode_label = QLabel("Mode:")
        mode_label.setStyleSheet("color: #a8adb4; font-size: 9pt;")
        ag.addWidget(mode_label, 3, 0)
        ag.addLayout(mode_row, 3, 1, 1, 2)
        self._set_cl_mode(True, push_to_stage=False)
        v.addWidget(abs_box)

        # ----- Real-time motor status -----
        v.addWidget(self._build_status_panel())

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
    # Settings tab
    # ------------------------------------------------------------------

    def _build_settings_panel(self) -> QWidget:
        root = QWidget()
        v = QVBoxLayout(root)
        v.setContentsMargins(8, 8, 8, 8)
        v.setSpacing(10)
        v.addWidget(self._build_sample_box())
        v.addWidget(self._build_stage_settings_box())
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

    # --- Sample/save info (shared by chip-scan) ---
    def _build_sample_box(self) -> QGroupBox:
        box = QGroupBox("Sample / Data"); box.setProperty("accent", "teal_d")
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
        form.addRow("Yield threshold (A):", self._threshold)
        return box

    # --- Run selection + buttons ---
    def _build_run_box(self) -> QGroupBox:
        box = QGroupBox("Chip Scan"); box.setProperty("accent", "green")
        grid = QGridLayout(box)
        grid.setContentsMargins(10, 16, 10, 10)
        grid.setHorizontalSpacing(8); grid.setVerticalSpacing(8)

        grid.addWidget(QLabel("Layout:"),       0, 0)
        self._layout_combo = QComboBox()
        self._layout_combo.addItems(list(LAYOUTS.keys()))
        grid.addWidget(self._layout_combo,      0, 1, 1, 2)

        grid.addWidget(QLabel("Start device:"), 1, 0)
        self._start_dev = QSpinBox()
        self._start_dev.setRange(1, 9999)
        self._start_dev.setValue(1)
        grid.addWidget(self._start_dev,         1, 1, 1, 2)

        btn_scan = QPushButton("▶  START CHIP SCAN")
        btn_scan.setStyleSheet(f"background: {C_ORANGE}; color: #1a0a02; font-weight: 700;")
        btn_scan.setMinimumHeight(36)
        btn_scan.clicked.connect(self._start_chip_scan)
        grid.addWidget(btn_scan, 2, 0, 1, 2)

        btn_scan_stop = QPushButton("■  STOP")
        btn_scan_stop.setStyleSheet(f"background: {C_RED}; color: white; font-weight: 700;")
        btn_scan_stop.setMinimumHeight(36)
        btn_scan_stop.clicked.connect(self._stop_chip_scan)
        grid.addWidget(btn_scan_stop, 2, 2)

        return box

    def _build_utilities_box(self) -> QGroupBox:
        box = QGroupBox("Utilities"); box.setProperty("accent", "orange")
        h = QHBoxLayout(box)
        h.setContentsMargins(10, 16, 10, 10)
        h.setSpacing(6)
        btn_yield  = QPushButton("Analyze Yield")
        btn_yield.clicked.connect(self._analyze_yield)
        btn_yield.setMinimumHeight(30)
        h.addWidget(btn_yield)
        return box

    # Status bits shown in the motor status panel (order = column order)
    _STATUS_BITS = [
        ("moving",          "MVNG",   "#eab308"),  # yellow  — in motion
        ("motor_error",     "ERR",    "#dc2626"),  # red     — fault
        ("stall",           "STALL",  "#dc2626"),
        ("upper_limit_hit", "↑LIM",   "#f97316"),  # orange  — limit warning
        ("lower_limit_hit", "↓LIM",   "#f97316"),
        ("overtemp",        "TEMP",   "#dc2626"),
        ("undervoltage",    "UV",     "#dc2626"),
        ("comm_error",      "COMM",   "#dc2626"),
    ]
    _STATUS_OFF_COLOR = "#2a2d31"   # dark grey when bit is False

    def _build_status_panel(self) -> QGroupBox:
        box = QGroupBox("Motor Status"); box.setProperty("accent", "yellow")
        grid = QGridLayout(box)
        grid.setContentsMargins(10, 14, 10, 10)
        grid.setHorizontalSpacing(4)
        grid.setVerticalSpacing(4)

        # Header row
        grid.addWidget(QLabel(""), 0, 0)
        for col, (_, short, _color) in enumerate(self._STATUS_BITS, start=1):
            h = QLabel(short)
            h.setAlignment(Qt.AlignCenter)
            h.setStyleSheet("color: #a8adb4; font-size: 8pt;")
            grid.addWidget(h, 0, col)

        self._status_leds: dict[str, dict[str, QLabel]] = {}
        for row, motor_name in enumerate(("X", "Y", "Z", "Rot"), start=1):
            name_lbl = QLabel(motor_name)
            name_lbl.setStyleSheet("font-weight: 600; min-width: 28px;")
            grid.addWidget(name_lbl, row, 0)
            self._status_leds[motor_name] = {}
            for col, (bit, _, color) in enumerate(self._STATUS_BITS, start=1):
                led = QLabel("●")
                led.setAlignment(Qt.AlignCenter)
                led.setStyleSheet(f"color: {self._STATUS_OFF_COLOR}; font-size: 10pt;")
                grid.addWidget(led, row, col)
                self._status_leds[motor_name][bit] = led

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
    # Hardware initialization
    # ------------------------------------------------------------------

    def _init_hardware(self):
        threading.Thread(target=self._stage_init_thread, daemon=True).start()

    def _stage_init_thread(self):
        try:
            self._stage = StageController()
        except Exception as e:
            QTimer.singleShot(0, lambda: QMessageBox.warning(
                self, "Stage init warning",
                f"Stage init error:\n{e}\n\nMotor controls unavailable."
            ))

    # ------------------------------------------------------------------
    # Motor jog
    # ------------------------------------------------------------------

    # GUI works in PROBE coordinates; the stage moves opposite to the probe,
    # so X and Y commands sent to the stage are negated. Z and Rot are unchanged.
    def _jog_x(self, sign: int):
        self._run_in_thread(lambda: self._stage.move_x(-sign * self._step_mm.value()))

    def _jog_y(self, sign: int):
        self._run_in_thread(lambda: self._stage.move_y(-sign * self._step_mm.value()))

    def _jog_z(self, sign: int):
        self._run_in_thread(lambda: self._stage.move_z(sign * self._step_mm.value()))

    def _jog_theta(self, sign: int):
        self._run_in_thread(lambda: self._stage.move_theta(sign * self._rot_step.value()))

    def _zero_xy(self):
        if self._stage:
            self._stage.zero_xy()
            self._update_position()

    def _goto_x_clicked(self):
        self._run_in_thread(lambda: self._stage.move_to_x(-self._goto_x.value()))

    def _goto_y_clicked(self):
        self._run_in_thread(lambda: self._stage.move_to_y(-self._goto_y.value()))

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
            # Display PROBE coordinates: negate X/Y stage readouts.
            x = -self._stage.get_position_x()
            y = -self._stage.get_position_y()
            z = self._stage.get_position_z()
            self._pos_label.setText(f"X: {x:.3f} mm  Y: {y:.3f} mm  Z: {z:.3f} mm")
        except Exception:
            pass

        motors = {
            "X":   self._stage.motor_x,
            "Y":   self._stage.motor_y,
            "Z":   self._stage.motor_z,
            "Rot": self._stage.motor_rot,
        }
        for motor_name, motor in motors.items():
            if motor is None:
                continue
            try:
                status = motor.get_status_parsed()
                for bit, short, on_color in self._STATUS_BITS:
                    led = self._status_leds[motor_name][bit]
                    if status.get(bit, False):
                        led.setStyleSheet(f"color: {on_color}; font-size: 10pt;")
                    else:
                        led.setStyleSheet(f"color: {self._STATUS_OFF_COLOR}; font-size: 10pt;")
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

        for i, dev_id in enumerate(dev_ids[self._chip_ref_dev_id - 1:], start=self._chip_ref_dev_id):
            if self._flag_stop:
                break

            if dev_id != self._chip_ref_dev_id:
                # target_x/target_y are in PROBE coordinates → negate for the stage.
                target_x = (dev_x[i - 1] - ref_x) * self.UNIT_MULT
                target_y = -(dev_y[i - 1] - ref_y) * self.UNIT_MULT
                self._stage.move_to_x(-target_x)
                self._stage.move_to_y(-target_y)

            self._set_status(f"Device {dev_id}")

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
        if self._stage:
            self._stage.close()
        event.accept()
