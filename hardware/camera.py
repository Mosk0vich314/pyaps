"""
Camera capture using OpenCV.
Emits frames via a callback; GUI connects its own slot to receive them.
"""

import threading
import cv2
import numpy as np

# Comprehensive probe list (high → low). Any that round-trip via cap.get()
# are considered supported by the driver.
_PROBE_RESOLUTIONS = [
    (4096, 2160), (3840, 2160), (3264, 2448), (3088, 2316),
    (2592, 1944), (2560, 1440), (2048, 1536), (1920, 1200),
    (1920, 1080), (1600, 1200), (1280,  960), (1280,  720),
    (1024,  768), ( 800,  600), ( 640,  480), ( 320,  240),
]


class Camera:
    def __init__(self, device_index: int = 0, fps: float = 10.0):
        self._index = device_index
        self._interval = 1.0 / fps
        self._cap: cv2.VideoCapture | None = None
        self._thread: threading.Thread | None = None
        self._running = False
        self._cap_lock = threading.Lock()
        self.on_frame = None   # callback(frame: np.ndarray)

    def _open(self) -> cv2.VideoCapture:
        for backend in (cv2.CAP_DSHOW, cv2.CAP_MSMF, cv2.CAP_ANY):
            cap = cv2.VideoCapture(self._index, backend)
            if cap.isOpened():
                ret, _ = cap.read()
                if ret:
                    print(f"[camera] opened with backend {backend}")
                    self._negotiate_resolution(cap)
                    return cap
                print(f"[camera] backend {backend} opened but no frame; trying next")
            cap.release()
        raise RuntimeError(f"Cannot open camera index {self._index}")

    def _negotiate_resolution(self, cap: cv2.VideoCapture):
        for w, h in _PROBE_RESOLUTIONS:
            cap.set(cv2.CAP_PROP_FRAME_WIDTH,  w)
            cap.set(cv2.CAP_PROP_FRAME_HEIGHT, h)
            aw = int(cap.get(cv2.CAP_PROP_FRAME_WIDTH))
            ah = int(cap.get(cv2.CAP_PROP_FRAME_HEIGHT))
            if aw == w and ah == h:
                print(f"[camera] initial resolution set to {w}x{h}")
                return
        aw = int(cap.get(cv2.CAP_PROP_FRAME_WIDTH))
        ah = int(cap.get(cv2.CAP_PROP_FRAME_HEIGHT))
        print(f"[camera] using driver default resolution {aw}x{ah}")

    def discover_resolutions(self) -> list[tuple[int, int]]:
        """Probe the device and return a list of (w, h) it actually accepts,
        ordered highest-first. Preserves the current resolution on exit."""
        if not (self._cap and self._cap.isOpened()):
            return []
        with self._cap_lock:
            cur_w = int(self._cap.get(cv2.CAP_PROP_FRAME_WIDTH))
            cur_h = int(self._cap.get(cv2.CAP_PROP_FRAME_HEIGHT))
            found: list[tuple[int, int]] = []
            for w, h in _PROBE_RESOLUTIONS:
                self._cap.set(cv2.CAP_PROP_FRAME_WIDTH,  w)
                self._cap.set(cv2.CAP_PROP_FRAME_HEIGHT, h)
                aw = int(self._cap.get(cv2.CAP_PROP_FRAME_WIDTH))
                ah = int(self._cap.get(cv2.CAP_PROP_FRAME_HEIGHT))
                if (aw, ah) == (w, h) and (w, h) not in found:
                    found.append((w, h))
            # Restore previous resolution
            self._cap.set(cv2.CAP_PROP_FRAME_WIDTH,  cur_w)
            self._cap.set(cv2.CAP_PROP_FRAME_HEIGHT, cur_h)
        print(f"[camera] discovered resolutions: {found}")
        return found

    def set_resolution(self, w: int, h: int):
        if not (self._cap and self._cap.isOpened()):
            return
        with self._cap_lock:
            self._cap.set(cv2.CAP_PROP_FRAME_WIDTH,  w)
            self._cap.set(cv2.CAP_PROP_FRAME_HEIGHT, h)
            aw = int(self._cap.get(cv2.CAP_PROP_FRAME_WIDTH))
            ah = int(self._cap.get(cv2.CAP_PROP_FRAME_HEIGHT))
        print(f"[camera] resolution set to {aw}x{ah}")

    def get_current_resolution(self) -> tuple[int, int]:
        if self._cap and self._cap.isOpened():
            return (int(self._cap.get(cv2.CAP_PROP_FRAME_WIDTH)),
                    int(self._cap.get(cv2.CAP_PROP_FRAME_HEIGHT)))
        return (0, 0)

    def set_property(self, prop: int, value: float):
        if self._cap and self._cap.isOpened():
            with self._cap_lock:
                self._cap.set(prop, value)

    def get_property(self, prop: int) -> float:
        if self._cap and self._cap.isOpened():
            return float(self._cap.get(prop))
        return 0.0

    def set_exposure(self, val: float):        self.set_property(cv2.CAP_PROP_EXPOSURE,   val)
    def set_brightness(self, val: float):      self.set_property(cv2.CAP_PROP_BRIGHTNESS, val)
    def set_contrast(self, val: float):        self.set_property(cv2.CAP_PROP_CONTRAST,   val)
    def set_saturation(self, val: float):      self.set_property(cv2.CAP_PROP_SATURATION, val)
    def set_gain(self, val: float):            self.set_property(cv2.CAP_PROP_GAIN,       val)

    def set_auto_exposure(self, enabled: bool):
        # DSHOW quirk: 0.75 = auto, 0.25 = manual
        self.set_property(cv2.CAP_PROP_AUTO_EXPOSURE, 0.75 if enabled else 0.25)

    def start(self):
        self._cap = self._open()
        self._running = True
        self._thread = threading.Thread(target=self._loop, daemon=True)
        self._thread.start()

    def stop(self):
        self._running = False
        if self._thread:
            self._thread.join(timeout=2.0)
        if self._cap:
            self._cap.release()
            self._cap = None

    def capture_frame(self) -> np.ndarray | None:
        if self._cap and self._cap.isOpened():
            with self._cap_lock:
                ret, frame = self._cap.read()
            return frame if ret else None
        return None

    def _loop(self):
        import time
        fail_streak = 0
        while self._running:
            t0 = time.monotonic()
            if self._cap and self._cap.isOpened():
                with self._cap_lock:
                    ret, frame = self._cap.read()
                if ret and frame is not None:
                    fail_streak = 0
                    if self.on_frame:
                        self.on_frame(frame)
                else:
                    fail_streak += 1
                    if fail_streak == 1:
                        print("[camera] read failed — frame dropped")
                    if fail_streak >= 3:
                        print(f"[camera] {fail_streak} consecutive failures — reopening")
                        try:
                            with self._cap_lock:
                                self._cap.release()
                        except Exception:
                            pass
                        try:
                            self._cap = self._open()
                        except RuntimeError as e:
                            print(f"[camera] reopen failed: {e}; retrying in 2s")
                            time.sleep(2.0)
                        fail_streak = 0
            elapsed = time.monotonic() - t0
            sleep = self._interval - elapsed
            if sleep > 0:
                time.sleep(sleep)
