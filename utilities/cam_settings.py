"""
Camera settings container with XML load/save.
Port of APS2/Hardware/camSettings.m.
"""

from __future__ import annotations
import os
from dataclasses import dataclass, field, asdict
from typing import Optional
import xml.etree.ElementTree as ET


@dataclass
class CHC:
    Xl: int = 0
    Xc: int = 0
    Xr: int = 0
    Yt: int = 0
    Yc: int = 0
    Yb: int = 0


@dataclass
class VideoSettings:
    DeviceID: int = 1
    VidResX: int = 1280
    VidResY: int = 720
    ExposureMode: str = "manual"
    Exposure: int = -5
    Brightness: int = 128
    WhiteBalanceMode: str = "auto"
    Saturation: int = 32
    CHC: CHC = field(default_factory=CHC)


class CamSettings:
    def __init__(self, path: Optional[str] = None):
        self.video = VideoSettings()
        if path and os.path.isfile(path):
            try:
                self.load(path)
            except Exception as e:
                print(f"Error reading {path}: {e}. Using defaults.")

    def load(self, path: str):
        root = ET.parse(path).getroot()
        # Accept either <Video>... at root or <...><Video>...
        vid = root.find("Video") if root.tag != "Video" else root
        if vid is None:
            return
        for child in vid:
            if child.tag == "CHC":
                for c in child:
                    if hasattr(self.video.CHC, c.tag) and c.text is not None:
                        setattr(self.video.CHC, c.tag, int(c.text))
            elif hasattr(self.video, child.tag) and child.text is not None:
                cur = getattr(self.video, child.tag)
                val = child.text
                try:
                    val = type(cur)(val) if not isinstance(cur, str) else val
                except (TypeError, ValueError):
                    pass
                setattr(self.video, child.tag, val)

    def save(self, path: str):
        root = ET.Element("camSettings")
        vid = ET.SubElement(root, "Video")
        d = asdict(self.video)
        chc = d.pop("CHC")
        for k, v in d.items():
            ET.SubElement(vid, k).text = str(v)
        chc_el = ET.SubElement(vid, "CHC")
        for k, v in chc.items():
            ET.SubElement(chc_el, k).text = str(v)
        ET.ElementTree(root).write(path, encoding="utf-8", xml_declaration=True)
