"""
Python side of APS2/Measurements/BaseMeasurement.m.

Each measurement is a thin Python object that holds the settings struct and
delegates the actual Run() / Save() to the MATLAB engine. This keeps ADwin
calls in MATLAB (where they belong) while exposing a Python-friendly API.
"""

from __future__ import annotations
from typing import Optional


class BaseMeasurement:
    MATLAB_CLASS = "BaseMeasurement"

    def __init__(self, bridge, settings: dict, var: Optional[str] = None):
        """
        bridge:   MatlabBridge instance (must be started)
        settings: dict of Settings fields (filename, sample, save_dir, ...)
        var:      optional MATLAB workspace variable name for this object
        """
        self.bridge = bridge
        self.settings = dict(settings)
        # Each instance gets a unique MATLAB workspace variable.
        self._var = var or f"_m_{id(self):x}"
        self._created = False

    # ------------------------------------------------------------------
    # Lifecycle
    # ------------------------------------------------------------------

    def create(self):
        """Instantiate the MATLAB object in the engine workspace."""
        if self._created:
            return
        self.bridge.push_settings_struct(self._var + "_settings", self.settings)
        self.bridge.eval(
            f"{self._var} = {self.MATLAB_CLASS}({self._var}_settings);"
        )
        self._created = True

    def run(self):
        self.create()
        self.bridge.eval(f"{self._var}.Run();")

    def save(self, suffix: str = ""):
        if not self._created:
            return
        arg = f"'{suffix}'" if suffix else ""
        self.bridge.eval(f"{self._var}.Save({arg});")

    def destroy(self):
        if self._created:
            self.bridge.eval(f"clear {self._var} {self._var}_settings;")
            self._created = False
