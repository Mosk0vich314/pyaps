# -*- coding: utf-8 -*-
"""
Created on Tue Jun  6 18:01:30 2023

@author: moan
"""

import time



import sys
start = time.perf_counter()
from pylablib.devices.SmarAct import SCU3D
end = time.perf_counter()
eta = end - start
print(f'time = {eta}')
#import pylablib as pll
#pll.par["devices/dlls/smaract_scu"] = "C:/Users/lab405/Documents/GitHub/LakeShore-Measurement-scripts-Adwin/Matlab/APS_GUI/Python/SCU3DControl.dll"
    


#def move(device,axis,Steps,Ampl,Freq):
def move():
    
    Freq = float(sys.argv[1])
    Ampl = float(sys.argv[2])
    device = int(sys.argv[3])
    Steps = float(sys.argv[4])
    axis = sys.argv[5]
    
    #SmarAct.list_scu_devices()
    #[TDeviceInfo(device_id=0, firmware_version='1.3.0.0', dll_version='4.3.0.0')]
    stage = SCU3D(device)  # connect to the first (stage) or second (pins) device in the list
    
    #stage.move_by('x', 100, 10)
    #1746014990
    #1729237774

    stage.move_macrostep(axis, Steps, Ampl, Freq)
    
if __name__ == "__main__":
    move()
    
