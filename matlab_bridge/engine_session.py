"""
Thin wrapper around matlab.engine.
Starts a headless MATLAB session, loads LakeShore libs and ADwin,
then exposes one method per measurement routine.
"""

from __future__ import annotations
import os
import pathlib


LAKESHORE_ROOT = str(pathlib.Path(__file__).parent.parent / "LakeShore-Measurement-scripts-Adwin" / "Matlab")


class MatlabBridge:
    def __init__(self):
        self._eng = None
        self._adwin_settings = None

    # ------------------------------------------------------------------
    # Lifecycle
    # ------------------------------------------------------------------

    def start(self):
        """Start MATLAB engine and initialize ADwin + measurement routines."""
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

    # ------------------------------------------------------------------
    # Measurement routines
    # ------------------------------------------------------------------

    def run_needle_contact(self, side: str) -> bool:
        """
        Run needle contact routine.
        side: 'Left' or 'Right'
        Returns True if contact was made.
        """
        result = self._eng.eval(f"needleContact.startRoutine('{side}')", nargout=1)
        return bool(result)

    def run_iv(self, device_id: str, save_dir: str):
        self._eng.eval(f"makeIV.startRoutine('{device_id}', '{save_dir}')", nargout=0)

    def run_gate_sweep(self, device_id: str, save_dir: str):
        self._eng.eval(f"makeGateSweep.startRoutine('{device_id}', '{save_dir}')", nargout=0)

    def run_stability(self, device_id: str, save_dir: str):
        self._eng.eval(f"makeStability.startRoutine('{device_id}', '{save_dir}')", nargout=0)

    def run_switch_box(self):
        self._eng.eval("switchingBox.startRoutine()", nargout=0)

    def set_threshold(self, value: float):
        self._eng.eval(f"needleContact.threshold = {value};", nargout=0)

    # ------------------------------------------------------------------
    # Internal
    # ------------------------------------------------------------------

    def _load_paths(self):
        libs_path = os.path.join(LAKESHORE_ROOT, "Libs")
        self._eng.eval(f"addpath(genpath('{libs_path}'));", nargout=0)
        adwin_path = os.path.join(LAKESHORE_ROOT, "Libs", "ADwin_script")
        self._eng.eval(f"addpath(genpath('{adwin_path}'));", nargout=0)
        print("MATLAB paths loaded.")

    def _init_adwin(self):
        self._eng.eval("ADwinSettings.ADC = {1e7,'off','off','off','off','off','off','off'};", nargout=0)
        self._eng.eval("ADwinSettings.auto = 'FEMTO';", nargout=0)
        self._eng.eval("ADwinSettings.ADC_gain = [0 0 0 0 0 0 0 0];", nargout=0)
        self._eng.eval("ADwinSettings.ADwin = 'GoldII';", nargout=0)
        self._eng.eval("ADwinSettings.res4p = 0;", nargout=0)
        self._eng.eval("ADwinSettings.get_sample_T = '';", nargout=0)
        self._eng.eval("ADwinSettings.T = 300;", nargout=0)
        self._eng.eval("ADwinSettings = Init_ADwin_boot_only(ADwinSettings);", nargout=0)
        self._eng.eval("needleContact = needleRoutine(ADwinSettings);", nargout=0)
        self._eng.eval("switchingBox  = switchBox(ADwinSettings);", nargout=0)
        self._eng.eval("makeIV        = makeIVRoutine(ADwinSettings);", nargout=0)
        self._eng.eval("makeGateSweep = makeGateSweepRoutine(ADwinSettings);", nargout=0)
        self._eng.eval("makeStability = makeStabilityRoutine(ADwinSettings);", nargout=0)
        print("ADwin and measurement routines initialized.")
