"""
Port of APS2/Hardware/switchBox.m.

Controls the switching relay via ADwin Digital Output.
Runs in MATLAB (ADwin hardware) so this class delegates to MatlabBridge.
"""

from __future__ import annotations


class SwitchBox:
    MATLAB_CLASS = "SwitchBox"

    def __init__(self, bridge, var: str = "switchingBox"):
        self.bridge = bridge
        self._var = var

    def create(self, settings_var: str = "ADwinSettings"):
        self.bridge.eval(f"{self._var} = {self.MATLAB_CLASS}({settings_var});")

    def start_routine(self):
        self.bridge.eval(f"{self._var}.StartRoutine();")
