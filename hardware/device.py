"""
Device layout data classes.
Port of APS2/DataTypes/{Device,doubleQDot,twoTGNR}.m.

All dimensions are in microns (matching MATLAB convention).
"""

from __future__ import annotations
from dataclasses import dataclass


@dataclass
class Device:
    width:   float = 100.0    # µm
    height:  float = 100.0    # µm
    rows:    int   = 5
    columns: int   = 6
    x_line:  float = 100.0    # µm
    y_line:  float = 0.0      # µm
    x_cells: int   = 0
    y_cells: int   = 0


@dataclass
class DoubleQDot(Device):
    width:   float = 1860.0
    height:  float = 660.0
    y_line:  float = -320.0
    x_line:  float = 140.0
    rows:    int   = 2
    columns: int   = 1
    x_cells: int   = 7
    y_cells: int   = 14


@dataclass
class TwoTGNR(Device):
    width:   float = 400.0
    height:  float = 200.0
    x_line:  float = 200.0
    y_line:  float = 200.0
    rows:    int   = 5
    columns: int   = 3
    x_cells: int   = 4
    y_cells: int   = 5


# Registry for GUI layout selector
LAYOUTS: dict[str, type[Device]] = {
    "twoTGNR":    TwoTGNR,
    "doubleQDot": DoubleQDot,
}


def generate_device_coordinates(layout: Device) -> dict:
    """
    Generate (deviceID, deviceX, deviceY) triplets for a chip layout.

    The chip is divided into rows × columns super-cells, each containing
    x_cells × y_cells devices, for a total of rows*cols*x_cells*y_cells.
    Returns dict with arrays (device ID starts at 1).
    """
    ids: list[int] = []
    xs:  list[float] = []
    ys:  list[float] = []

    dx = layout.width  / max(layout.x_cells, 1)
    dy = layout.height / max(layout.y_cells, 1)

    dev_id = 1
    for r in range(layout.rows):
        for c in range(layout.columns):
            ox = c * (layout.width  + layout.x_line)
            oy = r * (layout.height + layout.y_line)
            for iy in range(layout.y_cells):
                for ix in range(layout.x_cells):
                    ids.append(dev_id)
                    xs.append(ox + ix * dx)
                    ys.append(oy + iy * dy)
                    dev_id += 1

    return {"deviceID": ids, "deviceX": xs, "deviceY": ys}
