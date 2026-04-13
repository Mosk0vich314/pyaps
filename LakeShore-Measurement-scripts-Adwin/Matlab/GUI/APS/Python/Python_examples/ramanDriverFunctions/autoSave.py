# -*- coding: utf-8 -*-
"""
Created on Mon Jul 10 15:37:09 2023

@author: vafr
"""
import sys
import pythoncom
import win32com.client
from socket import gethostname
import time
    
def autoSave():
    hostname = gethostname()
    CLSID = "{C45E77CE-3D66-489A-B5E2-159F443BD1AA}"
    IBUCSAccess = win32com.client.DispatchEx(CLSID, machine=hostname, clsctx=pythoncom.CLSCTX_REMOTE_SERVER)
    IBUCSCore = win32com.client.CastTo(IBUCSAccess, 'IBUCSCore')
    IBUCSAccess.RequestWriteAccess(True)
    
    
    
    name = sys.argv[1]
    saveNamer = IBUCSCore.GetSubSystemDefaultInterface("UserParameters|AutoSaveProject|FileName")
    saveNamer.SetValue(name)

    projectSaver = IBUCSCore.GetSubSystemDefaultInterface("UserParameters|AutoSaveProject|StoreProject")
    projectSaver.OperateTrigger()
    
    IBUCSAccess.RequestWriteAccess(False)
    
    print(1)
    time.sleep(2)
    
if __name__ == "__main__":
    autoSave()
    