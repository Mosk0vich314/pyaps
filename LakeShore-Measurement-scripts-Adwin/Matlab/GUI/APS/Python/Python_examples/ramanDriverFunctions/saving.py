# -*- coding: utf-8 -*-
"""
Created on Fri Jun 30 16:19:29 2023

@author: vafr
"""


import pythoncom
import win32com.client
from socket import gethostname
import time
    
def autoFocus():
    # Connect to WITec Control
    hostname = gethostname()
    CLSID = "{C45E77CE-3D66-489A-B5E2-159F443BD1AA}"
    IBUCSAccess = win32com.client.DispatchEx(CLSID, machine=hostname, clsctx=pythoncom.CLSCTX_REMOTE_SERVER)
    IBUCSCore = win32com.client.CastTo(IBUCSAccess, 'IBUCSCore')
    IBUCSAccess.RequestWriteAccess(True)
    

    autoFocusser = IBUCSCore.GetSubSystemDefaultInterface("MultiComm|MicroscopeControl|Video|AutoFocus|Execute")
    autoFocusser.OperateTrigger()
    
    IBUCSAccess.RequestWriteAccess(False)
    time.sleep(3)
    
if __name__ == "__main__":
    autoFocus()
    
    
    
hostname = gethostname()
CLSID = "{C45E77CE-3D66-489A-B5E2-159F443BD1AA}"
IBUCSAccess = win32com.client.DispatchEx(CLSID, machine=hostname, clsctx=pythoncom.CLSCTX_REMOTE_SERVER)
IBUCSCore = win32com.client.CastTo(IBUCSAccess, 'IBUCSCore')
IBUCSAccess.RequestWriteAccess(True)

saveMode = IBUCSCore.GetSubSystemDefaultInterface("UserParameters|AutoSaveProject|DirectoryMode")

print(dir(saveMode))


print(saveMode.GetAvailableValues())


fileNamer = IBUCSCore.GetSubSystemDefaultInterface("UserParameters|AutoSaveProject|FileName")
directoryNamer = IBUCSCore.GetSubSystemDefaultInterface("UserParameters|AutoSaveProject|StartDirectory")
saveTrigger = IBUCSCore.GetSubSystemDefaultInterface("UserParameters|AutoSaveProject|StoreProject")


fileNamer.SetValue('fork1')
directoryNamer.SetValue(r'Desktop/'.replace('\\', '/'))

saveTrigger.OperateTrigger()
print(dir(saveTrigger))


IBUCSAccess.RequestWriteAccess(False)
time.sleep(3)
    
    
