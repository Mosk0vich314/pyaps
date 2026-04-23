"""
Yield analysis for I-V measurement files.
Port of APS2/Utilities/processYield.m.
"""

from __future__ import annotations
import glob
import os
import re
import numpy as np
from scipy.io import loadmat


def process_yield(folder_path: str, sample_name: str,
                  threshold: float = 1e-9) -> dict[int, bool]:
    """
    Scan <folder_path>/*<sample_name>-*.mat and return
    {device_id: exceeded_threshold} for each matching IV file.

    A device is counted as yielding if |mean(current)| > threshold
    on any column of IV.current.
    """
    pattern = os.path.join(folder_path, f"*{sample_name}-*.mat")
    files = sorted(glob.glob(pattern))
    out: dict[int, bool] = {}

    if not files:
        print(f"No files found for sample: {sample_name} in {folder_path}")
        return out

    id_re = re.compile(re.escape(sample_name) + r"-(\d+)_IV")

    for path in files:
        name = os.path.basename(path)
        m = id_re.search(name)
        if not m:
            continue
        dev_id = int(m.group(1))

        try:
            data = loadmat(path, variable_names=["IV"], squeeze_me=True)
            iv = data.get("IV")
            if iv is None or not hasattr(iv, "current"):
                print(f"Warning: invalid structure in {name}")
                continue

            current = iv.current
            # current may be a cell array (list of arrays) or a 2-D array
            if isinstance(current, np.ndarray) and current.dtype == object:
                cols = list(current)
            elif isinstance(current, np.ndarray) and current.ndim == 2:
                cols = [current[:, i] for i in range(current.shape[1])]
            else:
                cols = [np.asarray(current).ravel()]

            out[dev_id] = any(
                np.mean(np.abs(col)) > threshold for col in cols if col.size
            )
        except Exception as e:
            print(f"Error processing {name}: {e}")

    return out
