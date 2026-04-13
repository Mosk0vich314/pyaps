

import os
import sys
from pylablib.devices import SmarAct
import pylablib as pll
pll.par["devices/dlls/smaract_scu"] = "C:/Users/lab405/Documents/GitHub/LakeShore-Measurement-scripts-Adwin/Matlab/APS_GUI/Python/SCU3DControl.dll"



SmarAct.list_scu_devices()
#[TDeviceInfo(device_id=0, firmware_version='1.3.0.0', dll_version='4.3.0.0')]
stage = SmarAct.SCU3D(idx=0)  # connect to the first device in the list
#stage.move_by('x', 100, 10)
stage.move_macrostep('x', -1000, 100, 1000)