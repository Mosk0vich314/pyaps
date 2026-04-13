# -*- coding: utf-8 -*-
"""
Created on Tue Jun  6 18:01:30 2023

@author: vafr
"""


import os
import sys
import pythoncom
import win32com.client
from socket import gethostname

    
def move():
    # Connect to WITec Control
    hostname = gethostname()
    CLSID = "{C45E77CE-3D66-489A-B5E2-159F443BD1AA}"
    IBUCSAccess = win32com.client.DispatchEx(CLSID, machine=hostname, clsctx=pythoncom.CLSCTX_REMOTE_SERVER)
    IBUCSCore = win32com.client.CastTo(IBUCSAccess, 'IBUCSCore')
    IBUCSAccess.RequestWriteAccess(True)
        
    setterPosMotorX = IBUCSCore.GetSubSystemDefaultInterface("UserParameters|SamplePositioning|AbsolutePositionX")
    setterPosMotorX = win32com.client.CastTo(setterPosMotorX, 'IBUCSFloat')
    setterPosMotorY = IBUCSCore.GetSubSystemDefaultInterface("UserParameters|SamplePositioning|AbsolutePositionY")
    setterPosMotorY = win32com.client.CastTo(setterPosMotorY, 'IBUCSFloat')
    
    triggerMotorMovement = IBUCSCore.GetSubSystemDefaultInterface("UserParameters|SamplePositioning|GoToPosition")

    x = float(sys.argv[1])
    y = float(sys.argv[2])

    setterPosMotorX.SetValue(x)
    setterPosMotorY.SetValue(y)

    triggerMotorMovement.OperateTrigger()

    IBUCSAccess.RequestWriteAccess(False)

    print(1)
    
if __name__ == "__main__":
    move()