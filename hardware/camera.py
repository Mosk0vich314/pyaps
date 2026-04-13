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

    def start(self):
        self._cap = cv2.VideoCapture(self._index, cv2.CAP_DSHOW)
        if not self._cap.isOpened():
            raise RuntimeError(f"Cannot open camera index {self._index}")
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
        while self._running:
            t0 = time.monotonic()
            if self._cap and self._cap.isOpened():
                ret, frame = self._cap.read()
                if ret and self.on_frame:
                    self.on_frame(frame)
            elapsed = time.monotonic() - t0
            sleep = self._interval - elapsed
            if sleep > 0:
                time.sleep(sleep)
