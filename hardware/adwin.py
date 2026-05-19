"""
Low-level ADwin wrapper.

Boots the processor, loads compiled processes (.TBx for GoldII, .TCx for ProII),
and exposes the parameter / data / process primitives used by the measurement
layer. Uses the official `ADwin` Python package (Jaeger Computergesteuerte Messtechnik).
"""

from __future__ import annotations
import pathlib
from typing import Iterable

import numpy as np
import ADwin as _ADwin


_REPO_ROOT = pathlib.Path(__file__).resolve().parent.parent
PROCESSES_ROOT = _REPO_ROOT / "adwin_processes"

# ADwin process index numbers (slot in the processor; matches the .TB1..TB6 / TC1..TC6 suffix)
PROCESS_NUMBERS = {
    "Sweep_AO":    1,
    "Read_AI":     2,
    "Fixed_AO":    3,
    "Single_DO":   5,
    "Waveform_AO": 6,
}

# ADC/DAC fixed config (matches Init_ADwin_boot_only.m)
INPUT_RESOLUTION  = 18    # bits
OUTPUT_RESOLUTION = 16    # bits
OUTPUT_MIN        = -10.0
OUTPUT_MAX        = 9.99969
INPUT_RANGE       = 10.0
AI_ADDRESS  = 1
AO_ADDRESS  = 2
DIO_ADDRESS = 3

# Boot files (ADwin firmware) — paths are conventional on the lab PC
BOOT_FILES = {
    "GoldII": r"C:\ADwin\ADwin11.btl",
    "ProII":  r"C:\ADwin\ADwin12.btl",
}

CLOCK_FREQUENCY = {
    "GoldII": 0.3e9,   # 300 MHz
    "ProII":  1.0e9,   # 1 GHz
}


class ADwin:
    """Thin object wrapping the `ADwin.ADwin(addr,1)` driver.

    Parameters
    ----------
    model : "GoldII" | "ProII"
        Selects boot file, clock frequency, and which process binaries to load.
    device_no : int
        ADwin device number (default 1, matches the MATLAB code).
    """

    def __init__(self, model: str = "GoldII", device_no: int = 1):
        if model not in BOOT_FILES:
            raise ValueError(f"Unknown ADwin model: {model}")
        self.model = model
        self.clock_frequency = CLOCK_FREQUENCY[model]
        # 18-bit ADC sits at address 1; 16-bit at 0x150 (legacy)
        addr = 1 if INPUT_RESOLUTION == 18 else 0x150
        self._adw = _ADwin.ADwin(addr, device_no)
        self._loaded: set[str] = set()

    # ------------------------------------------------------------------
    # Boot / process loading
    # ------------------------------------------------------------------

    def boot(self):
        """Boot the processor if it isn't already booted."""
        try:
            ptype = self._adw.Processor_Type()
        except Exception:
            ptype = 0
        if ptype == 0:
            self._adw.Boot(BOOT_FILES[self.model])
            print(f"[ADwin] Booted ({self.model}).")
        else:
            print(f"[ADwin] Already booted (processor type {ptype}).")

    def load_process(self, process_name: str):
        """Load a compiled process binary by base name (e.g. 'Sweep_AO_read_AI_dual')."""
        slot = PROCESS_NUMBERS[self._slot_key(process_name)]
        ext = "TB" if self.model == "GoldII" else "TC"
        fname = f"{process_name}_{self.model}.{ext}{slot}"
        path = PROCESSES_ROOT / self.model / fname
        if not path.is_file():
            raise FileNotFoundError(f"ADwin process binary not found: {path}")
        self._adw.Load_Process(str(path))
        self._loaded.add(process_name)
        print(f"[ADwin] Loaded {fname} → process #{slot}")

    @staticmethod
    def _slot_key(process_name: str) -> str:
        for key in PROCESS_NUMBERS:
            if process_name.startswith(key):
                return key
        raise ValueError(f"Unknown ADwin process family: {process_name!r}")

    @staticmethod
    def slot_for(process_name: str) -> int:
        return PROCESS_NUMBERS[ADwin._slot_key(process_name)]

    # ------------------------------------------------------------------
    # Process control
    # ------------------------------------------------------------------

    def start_process(self, slot: int):
        self._adw.Start_Process(slot)

    def stop_process(self, slot: int):
        self._adw.Stop_Process(slot)

    def process_status(self, slot: int) -> int:
        return self._adw.Process_Status(slot)

    def set_processdelay(self, slot: int, delay: int):
        self._adw.Set_Processdelay(slot, int(delay))

    # ------------------------------------------------------------------
    # Parameters
    # ------------------------------------------------------------------

    def set_par(self, idx: int, value: int):
        self._adw.Set_Par(idx, int(value))

    def get_par(self, idx: int) -> int:
        return int(self._adw.Get_Par(idx))

    def set_fpar(self, idx: int, value: float):
        self._adw.Set_FPar(idx, float(value))

    def get_fpar(self, idx: int) -> float:
        return float(self._adw.Get_FPar(idx))

    # ------------------------------------------------------------------
    # Data arrays (Double = float64)
    # ------------------------------------------------------------------

    def set_data_double(self, array_no: int, data: Iterable[float], start_idx: int = 1):
        arr = np.asarray(data, dtype=np.float64)
        self._adw.SetData_Double(arr, array_no, start_idx, len(arr))

    def get_data_double(self, array_no: int, start_idx: int, count: int) -> np.ndarray:
        return np.asarray(self._adw.GetData_Double(array_no, start_idx, count),
                          dtype=np.float64)

    def get_data_long(self, array_no: int, start_idx: int, count: int) -> np.ndarray:
        return np.asarray(self._adw.GetData_Long(array_no, start_idx, count),
                          dtype=np.int64)


# ----------------------------------------------------------------------
# Module-level singleton (one ADwin per process is the only thing that makes
# sense; the driver itself is a singleton inside the DLL).
# ----------------------------------------------------------------------

_singleton: ADwin | None = None


def get_adwin(model: str = "GoldII") -> ADwin:
    """Return the process-wide ADwin instance, booting on first call."""
    global _singleton
    if _singleton is None:
        _singleton = ADwin(model)
        _singleton.boot()
    elif _singleton.model != model:
        raise RuntimeError(
            f"ADwin already initialized as {_singleton.model}, requested {model}"
        )
    return _singleton
