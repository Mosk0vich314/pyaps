"""
Camera capture using OpenCV.
Emits frames via a callback; GUI connects its own slot to receive them.
"""

import threading
import cv2
import numpy as np


class Camera:
    def __init__(self, device_index: int = 0, fps: float = 10.0):
        self._index = device_index
        self._interval = 1.0 / fps
        self._cap: cv2.VideoCapture | None = None
        self._thread: threading.Thread | None = None
        self._running = False
        self.on_frame = None   # callback(frame: np.ndarray)

    def _open(self) -> cv2.VideoCapture:
        # Try DSHOW first (known to produce frames on this setup),
        # fall back to MSMF, then ANY. Validate with a test read.
        for backend in (cv2.CAP_DSHOW, cv2.CAP_MSMF, cv2.CAP_ANY):
            cap = cv2.VideoCapture(self._index, backend)
            if cap.isOpened():
                ret, _ = cap.read()
                if ret:
                    print(f"[camera] opened with backend {backend}")
                    return cap
                print(f"[camera] backend {backend} opened but no frame; trying next")
            cap.release()
        raise RuntimeError(f"Cannot open camera index {self._index}")

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
        """Single synchronous frame grab (for saving reference images etc.)."""
        if self._cap and self._cap.isOpened():
            ret, frame = self._cap.read()
            return frame if ret else None
        return None

    def _loop(self):
        import time
        fail_streak = 0
        while self._running:
            t0 = time.monotonic()
            if self._cap and self._cap.isOpened():
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
