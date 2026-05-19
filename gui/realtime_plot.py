"""Real-time plotting widgets for measurements.

Replaces the MATLAB `Realtime_sweep.m` / `Realtime_sweep3D.m` figures.
Uses pyqtgraph, which streams updates at >100 Hz comfortably.
"""

from __future__ import annotations
from typing import Sequence
import numpy as np
import pyqtgraph as pg
from PySide6.QtWidgets import QWidget, QHBoxLayout, QVBoxLayout, QLabel
from PySide6.QtCore import Qt


pg.setConfigOption("background", "#0a0c0f")
pg.setConfigOption("foreground", "#e4e6ea")

_TRACE_COLORS = [
    (0,   114, 189),   # blue
    (217, 83,  25),    # orange
    (237, 177, 32),    # yellow
    (126, 47,  142),   # purple
    (119, 172, 48),    # green
    (77,  190, 238),   # light blue
    (162, 20,  47),    # red
    (200, 200, 200),   # grey
]


class RealtimeSweepPlot(QWidget):
    """Linear + log side-by-side, one trace per ADC channel."""

    def __init__(self, title: str, n_adc: int,
                 x_range: tuple[float, float],
                 x_label: str = "Bias (V)",
                 y_label: str = "Current (A)",
                 parent=None):
        super().__init__(parent)
        self.setWindowTitle(title)
        self.resize(1100, 480)
        self._n_adc = n_adc

        layout = QVBoxLayout(self)
        layout.setContentsMargins(6, 6, 6, 6)

        title_lbl = QLabel(title)
        title_lbl.setAlignment(Qt.AlignCenter)
        title_lbl.setStyleSheet("color: #2dd4bf; font-weight: 700; font-size: 12pt;")
        layout.addWidget(title_lbl)

        plots_row = QHBoxLayout()
        plots_row.setSpacing(6)
        layout.addLayout(plots_row)

        self._plot_lin = pg.PlotWidget()
        self._plot_log = pg.PlotWidget()
        for p, ylabel in ((self._plot_lin, y_label), (self._plot_log, f"|{y_label}|")):
            p.setLabel("bottom", x_label)
            p.setLabel("left", ylabel)
            p.showGrid(x=True, y=True, alpha=0.3)
            p.setXRange(*x_range)
            p.addLegend()
        self._plot_log.setLogMode(False, True)
        plots_row.addWidget(self._plot_lin)
        plots_row.addWidget(self._plot_log)

        self._curves_lin: list[pg.PlotDataItem] = []
        self._curves_log: list[pg.PlotDataItem] = []
        for i in range(n_adc):
            color = _TRACE_COLORS[i % len(_TRACE_COLORS)]
            pen = pg.mkPen(color=color, width=2)
            self._curves_lin.append(self._plot_lin.plot([], [], pen=pen, name=f"ADC {i+1}"))
            self._curves_log.append(self._plot_log.plot([], [], pen=pen, name=f"ADC {i+1}"))

        self._x = np.array([], dtype=np.float64)
        self._y = [np.array([], dtype=np.float64) for _ in range(n_adc)]

    def append(self, x_chunk: Sequence[float], y_chunks: Sequence[Sequence[float]]):
        """Append new points. y_chunks is a list of length n_adc, each a 1-D array."""
        x_chunk = np.asarray(x_chunk, dtype=np.float64)
        if x_chunk.size == 0:
            return
        self._x = np.concatenate([self._x, x_chunk])
        for i in range(self._n_adc):
            yc = np.asarray(y_chunks[i], dtype=np.float64)
            self._y[i] = np.concatenate([self._y[i], yc])
            self._curves_lin[i].setData(self._x, self._y[i])
            self._curves_log[i].setData(self._x, np.abs(self._y[i]))

    def clear(self):
        self._x = np.array([], dtype=np.float64)
        for i in range(self._n_adc):
            self._y[i] = np.array([], dtype=np.float64)
            self._curves_lin[i].setData([], [])
            self._curves_log[i].setData([], [])


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
        self.resize(720, 560)

        layout = QVBoxLayout(self)
        layout.setContentsMargins(6, 6, 6, 6)

        title_lbl = QLabel(title)
        title_lbl.setAlignment(Qt.AlignCenter)
        title_lbl.setStyleSheet("color: #2dd4bf; font-weight: 700; font-size: 12pt;")
        layout.addWidget(title_lbl)

        self._plot = pg.PlotWidget()
        self._plot.setLabel("bottom", x_label)
        self._plot.setLabel("left", y_label)
        self._plot.setXRange(*x_range)
        self._plot.setYRange(*y_range)
        layout.addWidget(self._plot)

        self._img = pg.ImageItem()
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
        # Pad/truncate to grid height
        n_x = self._data.shape[0]
        if col.size < n_x:
            col = np.concatenate([col, np.full(n_x - col.size, np.nan)])
        else:
            col = col[:n_x]
        self._data[:, j] = col
        self._img.setImage(self._data, autoLevels=True)
