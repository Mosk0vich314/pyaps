"""
Controls 4 ESCO stepper motors (X, Y, Z, Rot).
Mirrors StageController.m from APS2/Hardware/.
"""

from __future__ import annotations
from dataclasses import dataclass
from typing import Optional

from hardware.stepper_motor import StepperMotor


@dataclass
class AxisConfig:
    port: str
    address: int
    conversion_factor: float   # meters/step (or deg/step for Rot)


DEFAULT_CONFIG = {
    "X":   AxisConfig(port="COM5", address=1, conversion_factor=3.98438e-6),
    "Y":   AxisConfig(port="COM6", address=1, conversion_factor=3.98438e-6),
    "Z":   AxisConfig(port="COM8", address=1, conversion_factor=3.98438e-6),
    "Rot": AxisConfig(port="COM7", address=1, conversion_factor=0.01),  # deg/step
}


class StageController:
    def __init__(self, config: Optional[dict] = None):
        cfg = config or DEFAULT_CONFIG
        self.motor_x   = StepperMotor("X",   cfg["X"].port,   cfg["X"].address,   cfg["X"].conversion_factor)
        self.motor_y   = StepperMotor("Y",   cfg["Y"].port,   cfg["Y"].address,   cfg["Y"].conversion_factor)
        self.motor_z   = StepperMotor("Z",   cfg["Z"].port,   cfg["Z"].address,   cfg["Z"].conversion_factor)
        self.motor_rot = StepperMotor("Rot", cfg["Rot"].port, cfg["Rot"].address, cfg["Rot"].conversion_factor)

    def close(self):
        for motor in (self.motor_x, self.motor_y, self.motor_z, self.motor_rot):
            try:
                motor.close()
            except Exception:
                pass

    # ------------------------------------------------------------------
    # Relative moves
    # ------------------------------------------------------------------

    def move_x(self, meters: float):
        self._move(self.motor_x, meters)

    def move_y(self, meters: float):
        self._move(self.motor_y, meters)

    def move_z(self, meters: float):
        self._move(self.motor_z, meters)

    def move_theta(self, degrees: float):
        self._move(self.motor_rot, degrees)

    # ------------------------------------------------------------------
    # Absolute moves (relative to last zero_xy call)
    # ------------------------------------------------------------------

    def move_to_x(self, meters: float):
        self._move_abs(self.motor_x, meters)

    def move_to_y(self, meters: float):
        self._move_abs(self.motor_y, meters)

    def move_to_z(self, meters: float):
        self._move_abs(self.motor_z, meters)

    def zero_xy(self):
        """Mark current XY position as origin. Call after aligning on reference device."""
        self.motor_x.zero_position()
        self.motor_y.zero_position()

    # ------------------------------------------------------------------
    # Position readback
    # ------------------------------------------------------------------

    def get_position_x(self) -> float:
        return self.motor_x.get_position()

    def get_position_y(self) -> float:
        return self.motor_y.get_position()

    def get_position_z(self) -> float:
        return self.motor_z.get_position()

    # ------------------------------------------------------------------
    # Emergency stop
    # ------------------------------------------------------------------

    def stop(self):
        for motor in (self.motor_x, self.motor_y, self.motor_z, self.motor_rot):
            try:
                motor.stop_movement()
            except Exception:
                pass

    # ------------------------------------------------------------------
    # Internal helpers
    # ------------------------------------------------------------------

    def _move(self, motor: StepperMotor, value: float):
        motor.move_relative(value)
        motor.wait_until_done()

    def _move_abs(self, motor: StepperMotor, value: float):
        motor.move_absolute(value)
        motor.wait_until_done()
