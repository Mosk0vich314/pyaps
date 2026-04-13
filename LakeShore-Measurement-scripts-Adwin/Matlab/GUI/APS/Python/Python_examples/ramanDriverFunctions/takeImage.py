# -*- coding: utf-8 -*-
"""
Created on Tue Jun  6 18:01:30 2023

@author: vafr
"""

import sys
import pythoncom
import win32com.client
from socket import gethostname
import time

    
def takeImage():
    # Connect to WITec Control
    hostname = gethostname()
    CLSID = "{C45E77CE-3D66-489A-B5E2-159F443BD1AA}"
    IBUCSAccess = win32com.client.DispatchEx(CLSID, machine=hostname, clsctx=pythoncom.CLSCTX_REMOTE_SERVER)
    IBUCSCore = win32com.client.CastTo(IBUCSAccess, 'IBUCSCore')
    IBUCSAccess.RequestWriteAccess(True)
    
    
    name = str(sys.argv[1])

    namer = IBUCSCore.GetSubSystemDefaultInterface("UserParameters|Naming|SampleName")
    namer.SetValue(name)      

    videoAcquier = IBUCSCore.GetSubSystemDefaultInterface("MultiComm|MicroscopeControl|Video|AcquireVideoImage")
    videoAcquier.OperateTrigger()
    
    IBUCSAccess.RequestWriteAccess(False)
    
    time.sleep(3)
    
    
if __name__ == "__main__":
    takeImage()
    
    
    
    


    
    
