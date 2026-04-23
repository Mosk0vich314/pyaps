"""
Thin wrapper around matlab.engine.
Starts a headless MATLAB session, loads LakeShore + APS2 libs, and exposes
low-level eval helpers plus high-level measurement routines.
"""

from __future__ import annotations
import pathlib


_REPO_ROOT = pathlib.Path(__file__).parent.parent
LAKESHORE_ROOT = str(_REPO_ROOT / "LakeShore-Measurement-scripts-Adwin" / "Matlab")
APS2_ROOT      = str(_REPO_ROOT.parent / "automatedMeasurements" / "APS2")


def _esc(v) -> str:
    """Format a Python value as a MATLAB literal."""
    if isinstance(v, bool):
        return "true" if v else "false"
    if isinstance(v, (int, float)):
        return repr(v)
    if isinstance(v, str):
        escaped = v.replace("'", "''")
        return f"'{escaped}'"
    if v is None:
        return "[]"
    if isinstance(v, (list, tuple)):
        return "[" + " ".join(_esc(x) for x in v) + "]"
    raise TypeError(f"Cannot format {type(v)} for MATLAB")


class MatlabBridge:
    def __init__(self):
        self._eng = None

    # ------------------------------------------------------------------
    # Lifecycle
    # ------------------------------------------------------------------

    def start(self):
        import matlab.engine
        print("Starting MATLAB engine...", flush=True)
        self._eng = matlab.engine.start_matlab("-nodesktop -nosplash")
        print("MATLAB engine started.")
        self._load_paths()
        self._init_adwin()

    def stop(self):
        if self._eng:
            self._eng.quit()
            self._eng = None
            print("MATLAB engine stopped.")

    @property
    def is_started(self) -> bool:
        return self._eng is not None

    # ------------------------------------------------------------------
    # Low-level MATLAB helpers
    # ------------------------------------------------------------------

    def eval(self, expr: str, nargout: int = 0):
        return self._eng.eval(expr, nargout=nargout)

    def push_settings_struct(self, var_name: str, fields: dict):
        """Create/overwrite a MATLAB struct from a Python dict (scalar fields only)."""
        self.eval(f"{var_name} = struct();")
        self.assign_fields(var_name, fields)

    def assign_fields(self, target: str, fields: dict):
        """target is a MATLAB lvalue like 'obj.Settings' or 'ADwinSettings'."""
        for k, v in fields.items():
            self.eval(f"{target}.{k} = {_esc(v)};")

    # ------------------------------------------------------------------
    # High-level routines (legacy LakeShore-style, kept for compatibility)
    # ------------------------------------------------------------------

    def run_needle_contact(self, side: str) -> bool:
        return bool(self.eval(f"needleContact.startRoutine('{side}')", nargout=1))

    def run_iv(self, device_id: str, save_dir: str):
        self.eval(f"makeIV.startRoutine('{device_id}', '{save_dir}');")

    def run_gate_sweep(self, device_id: str, save_dir: str):
        self.eval(f"makeGateSweep.startRoutine('{device_id}', '{save_dir}');")

    def run_stability(self, device_id: str, save_dir: str):
        self.eval(f"makeStability.startRoutine('{device_id}', '{save_dir}');")

    def run_switch_box(self):
        self.eval("switchingBox.StartRoutine();")

    def set_threshold(self, value: float):
        self.eval(f"needleContact.threshold = {value};")

    # ------------------------------------------------------------------
    # APS2 measurement helpers
    # ------------------------------------------------------------------

    def run_iv_aps2(self, settings: dict):
        """One-shot IV using APS2/IVMeasurement.m."""
        self.push_settings_struct("_ivSettings", settings)
        self.eval("_iv = IVMeasurement(_ivSettings); _iv.Run(); clear _iv _ivSettings;")

    def run_gate_aps2(self, settings: dict):
        self.push_settings_struct("_gSettings", settings)
        self.eval("_g = GateSweepMeasurement(_gSettings); _g.Run(); clear _g _gSettings;")

    def run_stability_aps2(self, settings: dict):
        self.push_settings_struct("_sSettings", settings)
        self.eval("_s = StabilityMeasurement(_sSettings); _s.Run(); clear _s _sSettings;")

    def run_needle_alignment(self, settings: dict):
        self.push_settings_struct("_naSettings", settings)
        self.eval("_na = NeedleAlignment(_naSettings); _na.Run(); clear _na _naSettings;")

    # ------------------------------------------------------------------
    # Internal
    # ------------------------------------------------------------------

    def _load_paths(self):
        for root in (LAKESHORE_ROOT, APS2_ROOT):
            r = root.replace("\\", "/")
            self.eval(f"addpath(genpath('{r}'));")
        print("MATLAB paths loaded (LakeShore + APS2).")

    def _init_adwin(self):
        self.eval("ADwinSettings.ADC = {1e7,'off','off','off','off','off','off','off'};")
        self.eval("ADwinSettings.auto = 'FEMTO';")
        self.eval("ADwinSettings.ADC_gain = [0 0 0 0 0 0 0 0];")
        self.eval("ADwinSettings.ADwin = 'GoldII';")
        self.eval("ADwinSettings.res4p = 0;")
        self.eval("ADwinSettings.get_sample_T = '';")
        self.eval("ADwinSettings.T = 300;")
        self.eval("ADwinSettings = Init_ADwin_boot_only(ADwinSettings);")
        # Legacy LakeShore routine handles (kept for backward compatibility)
        try:
            self.eval("needleContact = needleRoutine(ADwinSettings);")
            self.eval("switchingBox  = SwitchBox(ADwinSettings);")
            self.eval("makeIV        = makeIVRoutine(ADwinSettings);")
            self.eval("makeGateSweep = makeGateSweepRoutine(ADwinSettings);")
            self.eval("makeStability = makeStabilityRoutine(ADwinSettings);")
        except Exception as e:
            print(f"Legacy routines unavailable: {e}")
        print("ADwin and measurement routines initialized.")
