"""
ESCO stepper motor driver over serial.
Mirrors StepperMotor.m from APS2/Hardware/.
"""

import time
import serial


class StepperMotor:
    DEFAULT_BAUD = 115200
    DEFAULT_TIMEOUT = 2.0

    def __init__(self, name: str, port: str, address: int = 1,
                 conversion_factor: float = 1.0):
        self.name = name
        self.port = port
        self.address = address
        self.conversion_factor = conversion_factor  # meters per step (or deg/step for Rot)

        self._serial = serial.Serial(
            port=port,
            baudrate=self.DEFAULT_BAUD,
            timeout=self.DEFAULT_TIMEOUT,
        )
        time.sleep(0.2)
        print(f"--- Connecting to {name} ({port})...", end="", flush=True)

        idn = self.get_id()
        if not idn:
            self._serial.close()
            raise RuntimeError(f"No response from {name} on {port}")

        actual_addr = self.get_address()
        if actual_addr != self.address:
            print(f" WARNING: address mismatch (expected {self.address}, got {actual_addr})")
        else:
            print(f" Connected (Addr: {actual_addr}).")

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
    # Calibrated movement
    # ------------------------------------------------------------------

    def move_relative(self, distance: float):
        """Move by distance in calibrated units (meters or degrees)."""
        steps = round(distance / self.conversion_factor)
        self._move_relative_steps(steps)

    def move_absolute(self, position: float):
        """Move to absolute position in calibrated units (meters or degrees)."""
        steps = round(position / self.conversion_factor)
        self._move_absolute_steps(steps)

    # ------------------------------------------------------------------
    # Status
    # ------------------------------------------------------------------

    def get_position(self) -> float:
        """Return current position in calibrated units."""
        resp = self._query("get_position")
        return int(resp) * self.conversion_factor

    def get_status(self) -> dict:
        resp = self._query("get_status")
        val = int(resp)
        return {
            "raw": val,
            "undervoltage":    bool(val & (1 << 0)),
            "comm_error":      bool(val & (1 << 1)),
            "moving":          bool(val & (1 << 2)),
            "moving_dir":      bool(val & (1 << 3)),
            "motor_error":     bool(val & (1 << 4)),
            "overtemp_pre":    bool(val & (1 << 5)),
            "overtemp":        bool(val & (1 << 6)),
            "open_cable":      bool(val & (1 << 7)),
            "short_circuit":   bool(val & (1 << 8)),
            "stall":           bool(val & (1 << 9)),
            "upper_limit_hit": bool(val & (1 << 10)),
            "lower_limit_hit": bool(val & (1 << 11)),
            "home_switch_hit": bool(val & (1 << 12)),
        }

    def is_moving(self) -> bool:
        return self.get_status()["moving"]

    def wait_until_done(self, timeout: float = 30.0):
        deadline = time.monotonic() + timeout
        while time.monotonic() < deadline:
            if not self.is_moving():
                return
            time.sleep(0.05)
        raise TimeoutError(f"{self.name}: motion did not complete within {timeout}s")

    # ------------------------------------------------------------------
    # Low-level hardware commands
    # ------------------------------------------------------------------

    def get_id(self) -> str:
        return self._query("*IDN?")

    def get_address(self) -> int:
        return int(self._query("get_address"))

    def zero_position(self):
        self._send("zero_position")

    def stop_movement(self):
        self._send("stop_movement")

    def drive_on(self):
        self._send("drive_on")

    def drive_off(self):
        self._send("drive_off")

    def apply_settings(self, **kwargs):
        for key, val in kwargs.items():
            self._send(f"set_setting {key} {val}")

    def _move_relative_steps(self, steps: int):
        self._send(f"move_relative {steps}")

    def _move_absolute_steps(self, steps: int):
        self._send(f"move_absolute {steps}")

    # ------------------------------------------------------------------
    # Serial helpers
    # ------------------------------------------------------------------

    def _query(self, cmd: str) -> str:
        self._serial.reset_input_buffer()
        self._serial.write((cmd + "\r\n").encode())
        resp = self._serial.readline().decode(errors="replace").strip()
        # Strip command echo if present
        if resp.startswith(cmd):
            resp = resp[len(cmd):].strip()
        return resp

    def _send(self, cmd: str):
        self._serial.reset_input_buffer()
        self._serial.write((cmd + "\r\n").encode())
        time.sleep(0.05)
        if self._serial.in_waiting:
            self._serial.readline()
