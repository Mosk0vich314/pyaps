# -*- coding: utf-8 -*-
"""
Created on Tue Jun  6 20:49:39 2023

@author: vafr
"""


import sys
import pythoncom
import win32com.client
from socket import gethostname
import time


def takeAreaScan():
    # Connect to WITec Control
    hostname = gethostname()
    CLSID = "{C45E77CE-3D66-489A-B5E2-159F443BD1AA}"
    IBUCSAccess = win32com.client.DispatchEx(CLSID, machine=hostname, clsctx=pythoncom.CLSCTX_REMOTE_SERVER)
    IBUCSCore = win32com.client.CastTo(IBUCSAccess, 'IBUCSCore')
    IBUCSAccess.RequestWriteAccess(True)
    
    LargeAreaScanStarter = IBUCSCore.GetSubSystemDefaultInterface("UserParameters|SequencerLargeScaleImaging|Start")

    name = str(sys.argv[1])
    namer = IBUCSCore.GetSubSystemDefaultInterface("UserParameters|Naming|SampleName")
    namer.SetValue(name)      
    
    videoAcquier = IBUCSCore.GetSubSystemDefaultInterface("MultiComm|MicroscopeControl|Video|AcquireVideoImage")
    videoAcquier.OperateTrigger()
        
    integrationTime = float(sys.argv[2])
    intTime = IBUCSCore.GetSubSystemDefaultInterface("UserParameters|SequencerLargeScaleImaging|SmoothScanIntegrationTime")
    intTime = win32com.client.CastTo(intTime, 'IBUCSFloat')
    intTime.SetValue(integrationTime)  
    
    scanMethod = IBUCSCore.GetSubSystemDefaultInterface("UserParameters|SequencerLargeScaleImaging|ScanMethod")
    scanMethod.SetValueString('Area')
    
    width = float(sys.argv[3])
    GeometryWidth = IBUCSCore.GetSubSystemDefaultInterface("UserParameters|SequencerLargeScaleImaging|Geometry|Width")
    GeometryWidth = win32com.client.CastTo(GeometryWidth, 'IBUCSFloat')
    GeometryWidth.SetValue(width)

    height = float(sys.argv[4])
    GeometryHeight = IBUCSCore.GetSubSystemDefaultInterface("UserParameters|SequencerLargeScaleImaging|Geometry|Height")
    GeometryHeight = win32com.client.CastTo(GeometryHeight, 'IBUCSFloat')
    GeometryHeight.SetValue(height)

    points = int(sys.argv[5])
    GeometryPoints = IBUCSCore.GetSubSystemDefaultInterface("UserParameters|SequencerLargeScaleImaging|PointsPerLine")
    GeometryPoints = win32com.client.CastTo(GeometryPoints, 'IBUCSInt')
    GeometryPoints.SetValue(points)

    lines = int(sys.argv[6])
    GeometryLines = IBUCSCore.GetSubSystemDefaultInterface("UserParameters|SequencerLargeScaleImaging|LinesPerImage")
    GeometryLines = win32com.client.CastTo(GeometryLines, 'IBUCSInt')
    GeometryLines.SetValue(lines)
    
    centerX = float(sys.argv[7])
    GeometryCenterX = IBUCSCore.GetSubSystemDefaultInterface("UserParameters|SequencerLargeScaleImaging|Geometry|CenterX")
    GeometryCenterX = win32com.client.CastTo(GeometryCenterX, 'IBUCSFloat')
    GeometryCenterX.SetValue(centerX)
    
    centerY = float(sys.argv[8])
    GeometryCenterY = IBUCSCore.GetSubSystemDefaultInterface("UserParameters|SequencerLargeScaleImaging|Geometry|CenterY")
    GeometryCenterY = win32com.client.CastTo(GeometryCenterY, 'IBUCSFloat')
    GeometryCenterY.SetValue(centerY)
    
    centerZ = float(sys.argv[9])
    GeometryCenterZ = IBUCSCore.GetSubSystemDefaultInterface("UserParameters|SequencerLargeScaleImaging|Geometry|CenterZ")
    GeometryCenterZ = win32com.client.CastTo(GeometryCenterZ, 'IBUCSFloat')
    GeometryCenterZ.SetValue(centerZ)

    rotation = float(sys.argv[10])
    GeometryRotation = IBUCSCore.GetSubSystemDefaultInterface("UserParameters|SequencerLargeScaleImaging|Geometry|Gamma")
    GeometryRotation = win32com.client.CastTo(GeometryRotation, 'IBUCSFloat')
    GeometryRotation.SetValue(rotation)

    power = float(sys.argv[11])
    laserPowerSetter = IBUCSCore.GetSubSystemDefaultInterface("MultiComm|MicroscopeControl|Laser|Selected|Power")
    laserPowerSetter = win32com.client.CastTo(laserPowerSetter, 'IBUCSFloat')
    laserPowerSetter.SetValue(power)

    LargeAreaScanStarter.OperateTrigger()
    
    
    videoCameraCouplerChecker = IBUCSCore.GetSubSystemDefaultInterface("MultiComm|MicroscopeControl|Video|VideoCameraCoupler")
        
    camDecoupled = 0
    while(camDecoupled == 0):
        if videoCameraCouplerChecker.GetValue()==False:
            camDecoupled = 1
        time.sleep(0.1)
        
        
    time.sleep(1)
    while(videoCameraCouplerChecker.GetValue()==False):
        time.sleep(0.01)
    
    time.sleep(0.1)
    
    IBUCSAccess.RequestWriteAccess(False)
    print('Area scan completed')
    
    
    
    
if __name__ == "__main__":
    takeAreaScan()
    
    
    






