"""
ESCO stepper motor driver over serial.
Port of APS2/Hardware/StepperMotor.m.

Units convention matches MATLAB: ConversionFactor is "units per step" where
units are mm for linear axes and degrees for rotation.
"""

from __future__ import annotations
import threading
import time
import serial

_LOG_PATH = "motor_debug.log"

def _log(msg: str):
    with open(_LOG_PATH, "a") as f:
        f.write(msg + "\n")


class StepperMotor:
    BAUD = 115200
    TIMEOUT = 2.0

    def __init__(self, name: str, port: str, address: int = 1):
        self.name = name
        self.port = port
        self.address = address

        # Calibration (set by StageController after construction).
        self.conversion_factor: float = 1.0   # units per step
        self.encoder_ratio: float = 1.0

        # Configurable hardware settings (applied via apply_settings()).
        self.motor_current: int = 3    # 3 = 1A
        self.hold_current: int = 0     # 0 = 0% (documented as 0% in new MATLAB default)
        self.microstepping: int = 0    # 0 = 256
        self.velocity: int = 100000
        self.acceleration: int = 5000
        self.encoder_type: int = 2     # 2 = Quadrature
        self.limit_lower: int = 0
        self.limit_upper: int = 0
        self.home_switch: int = 0
        self.homing_dir: int = 0       # 0=Pos, 1=Neg

        self.debug   = False          # set True to print raw serial traffic
        self._lock   = threading.Lock()
        self._serial = serial.Serial(port=port, baudrate=self.BAUD, timeout=self.TIMEOUT)
        time.sleep(0.2)
        print(f"--- Connecting to {name} ({port})...", end="", flush=True)

        idn = self.get_id()
        if not idn:
            self._serial.close()
            raise RuntimeError(f"Device {name} not responding.")

        if self.address >= 0:
            actual = self.get_address()
            if actual != self.address:
                print(f" WARNING: address mismatch (expected {self.address}, got {actual})")
            else:
                print(f" Connected (Addr: {actual}).")
        else:
            print(" Connected (address check skipped).")

        self.drive_on()

    def close(self):
        if self._serial.is_open:
            try:
                self.stop_movement()
                self.drive_off()
            except Exception:
                pass
            self._serial.close()
            print(f"--- Port {self.port} ({self.name}) closed.")

    # ------------------------------------------------------------------
    # Configuration
    # ------------------------------------------------------------------

    def apply_settings(self):
        try:
            self.set_setting("motor_current",  self.motor_current)
            self.set_setting("hold_current",   self.hold_current)
            self.set_setting("microstepping",  self.microstepping)
            self.set_setting("velocity",       self.velocity)
            self.set_setting("acceleration",   self.acceleration)
            self.set_setting("encoder_type",   self.encoder_type)
            self.set_setting("set_es_lower",   self.limit_lower)
            self.set_setting("set_es_upper",   self.limit_upper)
            self.set_setting("set_home",       self.home_switch)
            print(f"--- Settings applied to {self.name}.")
        except Exception as e:
            print(f"WARNING: failed to apply settings to {self.name}: {e}")

    # ------------------------------------------------------------------
    # Calibrated movement (mm for linear axes, deg for rotation)
    # ------------------------------------------------------------------

    def move_relative_units(self, value: float):
        # conv = mm/encoder_count; move_relative takes motor steps.
        # motor_steps = encoder_counts × |enc_ratio|
        encoder_counts = value / self.conversion_factor
        motor_steps = round(encoder_counts * abs(self.encoder_ratio))
        if self.debug:
            _log(f"[{self.name}] move_relative_units({value}) -> enc={encoder_counts:.1f} -> motor_steps={motor_steps}")
        self.move_relative(motor_steps)

    def move_absolute_units(self, value: float):
        encoder_counts = value / self.conversion_factor
        motor_steps = round(encoder_counts * abs(self.encoder_ratio))
        if self.debug:
            _log(f"[{self.name}] move_absolute_units({value}) -> enc={encoder_counts:.1f} -> motor_steps={motor_steps}")
        self.move_absolute(motor_steps)

    # Aliases for semantic clarity (matching MATLAB names).
    def move_relative_mms(self, mms: float):     self.move_relative_units(mms)
    def move_absolute_mms(self, mms: float):     self.move_absolute_units(mms)
    def move_relative_degrees(self, deg: float): self.move_relative_units(deg)
    def move_absolute_degrees(self, deg: float): self.move_absolute_units(deg)

    # ------------------------------------------------------------------
    # Status
    # ------------------------------------------------------------------

    def get_status_parsed(self) -> dict:
        resp = self._query("get_status")
        val = int(resp) if resp.lstrip("-").isdigit() else 0
        return {
            "raw":              val,
            "undervoltage":     bool(val & (1 << 0)),
            "comm_error":       bool(val & (1 << 1)),
            "moving":           bool(val & (1 << 2)),
            "moving_dir":       bool(val & (1 << 3)),
            "motor_error":      bool(val & (1 << 4)),
            "overtemp_pre":     bool(val & (1 << 5)),
            "overtemp":         bool(val & (1 << 6)),
            "open_cable":       bool(val & (1 << 7)),
            "short_circuit":    bool(val & (1 << 8)),
            "stall":            bool(val & (1 << 9)),
            "upper_limit_hit":  bool(val & (1 << 10)),
            "lower_limit_hit":  bool(val & (1 << 11)),
            "home_switch_hit":  bool(val & (1 << 12)),
        }

    def is_moving(self) -> bool:
        return self.get_status_parsed()["moving"]

    def wait_until_done(self, timeout: float = 10.0):
        # Small delay so the firmware has time to set the "moving" status bit
        # before we start polling — avoids a false-idle read right after a command.
        time.sleep(0.08)
        deadline = time.monotonic() + timeout
        while time.monotonic() < deadline:
            if not self.is_moving():
                return
            time.sleep(0.05)

    def get_position(self) -> float:
        """Return current position in calibrated units (mm or degrees)."""
        resp = self._query("get_position")
        steps = int(resp) if resp.lstrip("-").isdigit() else 0
        return steps * self.conversion_factor

    # ------------------------------------------------------------------
    # Basic commands
    # ------------------------------------------------------------------

    def get_id(self) -> str:
        return self._query("*IDN?")

    def get_address(self) -> int:
        resp = self._query("get_address")
        return int(resp) if resp.lstrip("-").isdigit() else -1

    def get_version(self) -> str:
        return self._query("get_version")

    def get_voltages(self) -> str:
        return self._query("get_voltages")

    def move_relative(self, steps: int):
        self._send(f"move_relative {int(steps)}")

    def move_absolute(self, steps: int):
        self._send(f"move_absolute {int(steps)}")

    def move_velocity(self, direction):
        if isinstance(direction, str):
            cmd = "const_v-" if direction.lower().startswith("n") or direction == "-" else "const_v+"
        else:
            cmd = "const_v-" if direction == 1 else "const_v+"
        self._send(cmd)

    def home(self, direction: int | None = None):
        if direction is None:
            direction = self.homing_dir
        self._send(f"home {int(direction)}")

    def stop_movement(self):
        self._send("stop_movement")

    def zero_position(self):
        self._send("zero_position")

    def set_output(self, state: int):
        self._query(f"set_output1 {int(state)}")

    def drive_on(self):
        self._send("drive_on")

    def drive_off(self):
        self._send("drive_off")

    def set_setting(self, name: str, value):
        self._send(f"set_setting {name} {int(value)}")

    def get_setting(self, name: str) -> float:
        resp = self._query(f"get_setting {name}")
        try:
            return float(resp)
        except ValueError:
            return float("nan")

    # ------------------------------------------------------------------
    # Serial helpers
    # ------------------------------------------------------------------

    def _query(self, cmd: str) -> str:
        with self._lock:
            self._serial.reset_input_buffer()
            self._serial.write((cmd + "\r\n").encode())
            raw = self._serial.readline()
            resp = raw.decode(errors="replace").strip()
            if self.debug:
                _log(f"[{self.name}] Q: {cmd!r}  RAW: {raw!r}  RESP: {resp!r}")
            if resp.startswith(cmd):
                resp = resp[len(cmd):].strip()
            return resp

    def _send(self, cmd: str):
        with self._lock:
            self._serial.reset_input_buffer()
            self._serial.write((cmd + "\r\n").encode())
            time.sleep(0.05)
            if self._serial.in_waiting:
                ack = self._serial.readline()
                if self.debug:
                    _log(f"[{self.name}] S: {cmd!r}  ACK: {ack!r}")
