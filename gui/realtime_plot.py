"""Real-time plotting widgets for measurements.

Replaces the MATLAB `Realtime_sweep.m` / `Realtime_sweep3D.m` figures.
Uses pyqtgraph, which streams updates at >100 Hz comfortably.
"""

from __future__ import annotations
from typing import Sequence
import numpy as np
import pyqtgraph as pg
from PySide6.QtWidgets import QWidget, QHBoxLayout, QVBoxLayout, QLabel, QFrame
from PySide6.QtCore import Qt
from PySide6.QtGui import QFont


# ---------------------------------------------------------------------------
# Visual theme — matches the main window palette (charcoal / teal accent)
# ---------------------------------------------------------------------------

_BG       = "#0d0f12"
_PANEL    = "#16181c"
_GRID     = "#2a2e35"
_FG       = "#e4e6ea"
_FG_DIM   = "#9aa1ab"
_ACCENT   = "#2dd4bf"
_AXIS_PEN = pg.mkPen(color="#3a3e44", width=1)

pg.setConfigOption("background", _BG)
pg.setConfigOption("foreground", _FG)
pg.setConfigOption("antialias", True)

# Carefully tuned for dark theme — softer than MATLAB defaults, more saturated
# than pyqtgraph defaults. Order picked so 1- and 2-trace cases look good.
_TRACE_COLORS = [
    "#2dd4bf",   # teal
    "#f97316",   # orange
    "#eab308",   # amber
    "#a78bfa",   # violet
    "#84cc16",   # lime
    "#38bdf8",   # sky
    "#f87171",   # red
    "#cbd5e1",   # slate
]


def _style_axes(plot_item: pg.PlotItem):
    """Apply the dark theme to a single PlotItem."""
    for name in ("left", "bottom", "right", "top"):
        ax = plot_item.getAxis(name)
        ax.setPen(_AXIS_PEN)
        ax.setTextPen(_FG)
        font = QFont("Segoe UI", 9)
        ax.setStyle(tickFont=font, tickTextOffset=4)
    plot_item.getAxis("left").setWidth(64)
    plot_item.getAxis("bottom").setHeight(28)
    plot_item.showGrid(x=True, y=True, alpha=0.12)
    plot_item.getViewBox().setBackgroundColor(_PANEL)
    # Tighter default padding so the data hugs the box edges.
    plot_item.getViewBox().setDefaultPadding(0.02)


def _make_plot(title: str, x_label: str, y_label: str,
                x_range: tuple[float, float],
                log_y: bool = False) -> pg.PlotWidget:
    pw = pg.PlotWidget()
    pw.setMinimumHeight(320)
    pi: pg.PlotItem = pw.getPlotItem()
    _style_axes(pi)
    title_html = (f"<span style='color:{_ACCENT}; font-size:10pt; "
                  f"font-weight:600; letter-spacing:0.6px'>"
                  f"{title.upper()}</span>")
    pi.setTitle(title_html)
    label_style = {"color": _FG_DIM, "font-size": "9pt"}
    pi.setLabel("bottom", x_label, **label_style)
    pi.setLabel("left", y_label, **label_style)
    pi.setXRange(*x_range, padding=0)
    if log_y:
        pi.setLogMode(False, True)
    legend = pi.addLegend(offset=(-8, 8), labelTextColor=_FG,
                          brush=pg.mkBrush("#16181c"),
                          pen=pg.mkPen("#2a2e35"))
    legend.setLabelTextSize("8pt")
    return pw


class RealtimeSweepPlot(QWidget):
    """Linear + log side-by-side, one trace per ADC channel."""

    def __init__(self, title: str, n_adc: int,
                 x_range: tuple[float, float],
                 x_label: str = "Bias (V)",
                 y_label: str = "Current (A)",
                 parent=None):
        super().__init__(parent)
        self.setWindowTitle(title)
        self.resize(1200, 560)
        self.setStyleSheet(f"background: {_BG}; color: {_FG};")
        self._n_adc = n_adc

        outer = QVBoxLayout(self)
        outer.setContentsMargins(14, 12, 14, 10)
        outer.setSpacing(8)

        # Header strip: title + readout
        header = QHBoxLayout()
        header.setSpacing(16)
        self._title_lbl = QLabel(title)
        self._title_lbl.setStyleSheet(
            f"color: {_ACCENT}; font-weight: 700; font-size: 13pt; "
            "letter-spacing: 0.8px;")
        header.addWidget(self._title_lbl)
        header.addStretch()
        self._stats_lbl = QLabel("— pts")
        self._stats_lbl.setStyleSheet(
            f"color: {_FG_DIM}; font-family: 'Consolas', monospace; "
            "font-size: 9pt;")
        header.addWidget(self._stats_lbl)
        outer.addLayout(header)

        # Thin divider line
        line = QFrame()
        line.setFrameShape(QFrame.HLine)
        line.setStyleSheet(f"background: {_GRID}; max-height: 1px; border: none;")
        outer.addWidget(line)

        plots_row = QHBoxLayout()
        plots_row.setSpacing(10)
        outer.addLayout(plots_row, stretch=1)

        self._plot_lin = _make_plot("Linear", x_label, y_label, x_range)
        self._plot_log = _make_plot("Log |y|", x_label, f"|{y_label}|",
                                    x_range, log_y=True)
        # Link the X axes so panning/zooming on one mirrors to the other.
        self._plot_log.getPlotItem().setXLink(self._plot_lin.getPlotItem())
        plots_row.addWidget(self._plot_lin)
        plots_row.addWidget(self._plot_log)

        self._curves_lin: list[pg.PlotDataItem] = []
        self._curves_log: list[pg.PlotDataItem] = []
        for i in range(n_adc):
            color = _TRACE_COLORS[i % len(_TRACE_COLORS)]
            pen = pg.mkPen(color=color, width=2.2)
            # White semi-transparent symbol for the latest point (drawn after
            # the line) is added via setData — we use no symbols, just a clean
            # antialiased line.
            self._curves_lin.append(self._plot_lin.plot(
                [], [], pen=pen, name=f"ADC {i+1}"))
            self._curves_log.append(self._plot_log.plot(
                [], [], pen=pen, name=f"ADC {i+1}"))

        self._x = np.array([], dtype=np.float64)
        self._y = [np.array([], dtype=np.float64) for _ in range(n_adc)]

    def append(self, x_chunk: Sequence[float], y_chunks: Sequence[Sequence[float]]):
        x_chunk = np.asarray(x_chunk, dtype=np.float64)
        if x_chunk.size == 0:
            return
        self._x = np.concatenate([self._x, x_chunk])
        for i in range(self._n_adc):
            yc = np.asarray(y_chunks[i], dtype=np.float64)
            self._y[i] = np.concatenate([self._y[i], yc])
            self._curves_lin[i].setData(self._x, self._y[i])
            self._curves_log[i].setData(self._x, np.abs(self._y[i]))
        # Live numeric readout
        last = self._y[0][-1] if self._y[0].size else 0.0
        self._stats_lbl.setText(
            f"{self._x.size:>5d} pts   last = {_fmt_eng(last)}A")

    def clear(self):
        self._x = np.array([], dtype=np.float64)
        for i in range(self._n_adc):
            self._y[i] = np.array([], dtype=np.float64)
            self._curves_lin[i].setData([], [])
            self._curves_log[i].setData([], [])
        self._stats_lbl.setText("— pts")


def _fmt_eng(v: float) -> str:
    """Engineering-notation formatter (1.23 µ, 4.56 m, etc.)."""
    if v == 0 or not np.isfinite(v):
        return f"{v:+.3f} "
    exp = int(np.floor(np.log10(abs(v)) / 3) * 3)
    exp = max(-15, min(12, exp))
    mantissa = v / 10**exp
    suffix = {-15: "f", -12: "p", -9: "n", -6: "µ", -3: "m",
              0: " ", 3: "k", 6: "M", 9: "G", 12: "T"}[exp]
    return f"{mantissa:+7.3f} {suffix}"


# ---------------------------------------------------------------------------
# Stability (2-D)
# ---------------------------------------------------------------------------

class RealtimeStabilityPlot(QWidget):
    """Heatmap for stability diagrams (gate voltage × bias × current)."""

    def __init__(self, title: str,
                 x_range: tuple[float, float],
                 y_range: tuple[float, float],
                 x_label: str = "Bias (V)",
                 y_label: str = "Gate (V)",
                 parent=None):
        super().__init__(parent)
        self.setWindowTitle(title)
        self.resize(820, 640)
        self.setStyleSheet(f"background: {_BG}; color: {_FG};")

        outer = QVBoxLayout(self)
        outer.setContentsMargins(14, 12, 14, 10)
        outer.setSpacing(8)

        title_lbl = QLabel(title)
        title_lbl.setStyleSheet(
            f"color: {_ACCENT}; font-weight: 700; font-size: 13pt; "
            "letter-spacing: 0.8px;")
        outer.addWidget(title_lbl)
        line = QFrame()
        line.setFrameShape(QFrame.HLine)
        line.setStyleSheet(f"background: {_GRID}; max-height: 1px; border: none;")
        outer.addWidget(line)

        self._plot = _make_plot("Stability", x_label, y_label, x_range)
        self._plot.getPlotItem().setYRange(*y_range, padding=0)
        outer.addWidget(self._plot, stretch=1)

        self._img = pg.ImageItem()
        # Use a perceptually uniform colormap (viridis) — cleaner than the
        # MATLAB jet default.
        self._img.setLookupTable(pg.colormap.get("viridis").getLookupTable(0.0, 1.0, 256))
        self._plot.addItem(self._img)
        self._x_range = x_range
        self._y_range = y_range
        self._data: np.ndarray | None = None

    def set_grid(self, n_x: int, n_y: int):
        self._data = np.full((n_x, n_y), np.nan, dtype=np.float64)
        x_span = self._x_range[1] - self._x_range[0]
        y_span = self._y_range[1] - self._y_range[0]
        self._img.setRect(self._x_range[0], self._y_range[0], x_span, y_span)

    def set_column(self, j: int, column_values: Sequence[float]):
        if self._data is None:
            return
        col = np.asarray(column_values, dtype=np.float64)
        n_x = self._data.shape[0]
        if col.size < n_x:
            col = np.concatenate([col, np.full(n_x - col.size, np.nan)])
        else:
            col = col[:n_x]
        self._data[:, j] = col
        self._img.setImage(self._data, autoLevels=True)
