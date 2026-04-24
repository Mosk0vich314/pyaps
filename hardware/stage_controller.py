"""
Controls the 4 ESCO stepper motors (X, Y, Z, Rot).
Port of APS2/Hardware/StageController.m.

Units: mm for X/Y/Z, degrees for Rot.
"""

from __future__ import annotations
import dataclasses
import time
from dataclasses import dataclass
from typing import Optional

from hardware.stepper_motor import StepperMotor


@dataclass
class AxisConfig:
    port: str
    address: int
    conv: float          # units per step (mm/step or deg/step)
    enc_ratio: float     # encoder ratio (sign indicates direction)
    home_dir: int        # 0=Pos, 1=Neg
    lim_lower: int
    lim_upper: int
    home_sw: int
    enc_type: int
    velocity: int = 100000


# Values copied from StageController.m GetDefaultConfig() (MAC_Setup_v1.0_current20260107.xml)
# X/Y inverted to follow Cross (probe) position on chip (conv flipped)
# enc_ratio remains original to handle reverse-mounted encoders
DEFAULT_CONFIG = {
    "X":   AxisConfig(port="COM5", address=1, conv=-3.98438e-6, enc_ratio=-6.42,   home_dir=1, lim_lower=4, lim_upper=2, home_sw=4, enc_type=2),
    "Y":   AxisConfig(port="COM6", address=2, conv=-3.98438e-6, enc_ratio=-6.42,   home_dir=1, lim_lower=4, lim_upper=0, home_sw=4, enc_type=2),
    "Z":   AxisConfig(port="COM8", address=3, conv=9.75e-6,     enc_ratio=2.56261, home_dir=1, lim_lower=3, lim_upper=1, home_sw=3, enc_type=2, velocity=80000),
    "Rot": AxisConfig(port="COM7", address=0, conv=3.9062e-5,   enc_ratio=1.0,     home_dir=0, lim_lower=0, lim_upper=0, home_sw=2, enc_type=0),
}


class StageController:
    WAIT_TIMEOUT = 60.0   # seconds per move

    def __init__(self, overrides: Optional[dict] = None):
        print("--- StageController: Initializing 4 Motors...")
        cfg = {k: dataclasses.replace(v) for k, v in DEFAULT_CONFIG.items()}
        if overrides:
            for axis, o in overrides.items():
                if axis in cfg:
                    if "port" in o:    cfg[axis].port = o["port"]
                    if "address" in o: cfg[axis].address = o["address"]

        self.motor_x:   Optional[StepperMotor] = None
        self.motor_y:   Optional[StepperMotor] = None
        self.motor_z:   Optional[StepperMotor] = None
        self.motor_rot: Optional[StepperMotor] = None

        try:
            self.motor_x   = self._init_axis("X",   cfg["X"])
            self.motor_y   = self._init_axis("Y",   cfg["Y"])
            self.motor_z   = self._init_axis("Z",   cfg["Z"])
            self.motor_rot = self._init_axis("Rot", cfg["Rot"])
            from hardware.stepper_motor import _LOG_PATH
            open(_LOG_PATH, "w").close()
            self.motor_x.debug = True
            self.motor_y.debug = True
            self.motor_z.debug = True
            self.motor_rot.debug = True
            self.is_connected = True
            print("--- StageController: All 4 Motors Ready.")
        except Exception as e:
            print(f"StageController init failed: {e}")
            self.close()
            self.is_connected = False
            raise

    def close(self):
        for m in (self.motor_x, self.motor_y, self.motor_z, self.motor_rot):
            if m is not None:
                try:
                    m.close()
                except Exception:
                    pass

    # ------------------------------------------------------------------
    # Relative moves (user-facing)
    # ------------------------------------------------------------------

    def move_x(self, mm: float):      self._move(self.motor_x, mm)
    def move_y(self, mm: float):      self._move(self.motor_y, mm)
    def move_z(self, mm: float):      self._move(self.motor_z, mm)
    def move_theta(self, deg: float): self._move(self.motor_rot, deg)

    # Absolute moves (relative to last zero_xy call)
    def move_to_x(self, mm: float): self._move_abs(self.motor_x, mm)
    def move_to_y(self, mm: float): self._move_abs(self.motor_y, mm)
    def move_to_z(self, mm: float): self._move_abs(self.motor_z, mm)

    def zero_xy(self):
        if self.motor_x: self.motor_x.zero_position()
        if self.motor_y: self.motor_y.zero_position()

    # ------------------------------------------------------------------
    # Homing (finds the limit/home switch, then zeroes position)
    # ------------------------------------------------------------------

    HOME_TIMEOUT = 300.0  # homing may take a while

    def home_x(self):   self._home(self.motor_x)
    def home_y(self):   self._home(self.motor_y)
    def home_z(self):   self._home(self.motor_z)
    def home_rot(self): self._home(self.motor_rot)

    def home_all(self):
        # 1. Safety first: Home Z first to avoid crashing into the sample while X/Y move.
        print("[Stage] Homing Z (Safety first)...")
        self.home_z()
        
        # 2. Home X and Y simultaneously.
        print("[Stage] Homing X and Y in parallel...")
        if self.motor_x: self.motor_x.home()
        if self.motor_y: self.motor_y.home()
        
        # 3. Wait for both to finish (shared deadline so total wait ≤ HOME_TIMEOUT).
        deadline = time.monotonic() + self.HOME_TIMEOUT
        if self.motor_x: self.motor_x.wait_until_done(max(0.0, deadline - time.monotonic()))
        if self.motor_y: self.motor_y.wait_until_done(max(0.0, deadline - time.monotonic()))
        
        # 4. Zero the coordinate system for both.
        if self.motor_x: self.motor_x.zero_position()
        if self.motor_y: self.motor_y.zero_position()
        print("[Stage] Home ALL complete.")

    def _home(self, motor: Optional[StepperMotor]):
        if motor is None:
            return
        motor.home()
        motor.wait_until_done(self.HOME_TIMEOUT)
        motor.zero_position()

    # ------------------------------------------------------------------
    # Position readback (returns calibrated units — mm/deg)
    # ------------------------------------------------------------------

    def get_position_x(self) -> float: return self.motor_x.get_position()
    def get_position_y(self) -> float: return self.motor_y.get_position()
    def get_position_z(self) -> float: return self.motor_z.get_position()

    def stop(self):
        for m in (self.motor_x, self.motor_y, self.motor_z, self.motor_rot):
            if m is None:
                continue
            try:
                m.stop_movement()
            except Exception:
                pass

    # ------------------------------------------------------------------
    # Internal
    # ------------------------------------------------------------------

    def _init_axis(self, name: str, c: AxisConfig) -> StepperMotor:
        m = StepperMotor(name, c.port, c.address)
        m.conversion_factor = c.conv
        m.encoder_ratio     = c.enc_ratio
        m.homing_dir        = c.home_dir
        m.limit_lower       = c.lim_lower
        m.limit_upper       = c.lim_upper
        m.home_switch       = c.home_sw
        m.encoder_type      = c.enc_type
        m.velocity          = c.velocity
        m.apply_settings()
        m.drive_on()
        return m

    def _move(self, motor: Optional[StepperMotor], value: float):
        if motor is None:
            return
        pos_before = motor.get_position()
        print(f"[Stage] RELATIVE {motor.name}: target={value:+.4f}, pos_before={pos_before:.4f}")
        if "Rot" in motor.name:
            motor.move_relative_degrees(value)
        else:
            motor.move_relative_mms(value)
        motor.wait_until_done(self.WAIT_TIMEOUT)
        pos_after = motor.get_position()
        print(f"[Stage] {motor.name}: pos_after={pos_after:.4f}  Δ={pos_after-pos_before:+.4f}")

    def _move_abs(self, motor: Optional[StepperMotor], value: float):
        if motor is None:
            return
        pos_before = motor.get_position()
        print(f"[Stage] ABSOLUTE {motor.name}: target={value:.4f}, pos_before={pos_before:.4f}")
        if "Rot" in motor.name:
            motor.move_absolute_degrees(value)
        else:
            motor.move_absolute_mms(value)
        motor.wait_until_done(self.WAIT_TIMEOUT)
        pos_after = motor.get_position()
        print(f"[Stage] {motor.name}: pos_after={pos_after:.4f}  Δ={pos_after-pos_before:+.4f}")
