# -*- coding: utf-8 -*-
"""
Created on Tue Jun  6 12:28:31 2023

@author: vafr
"""
import os
import sys
import pythoncom
import win32com.client
from socket import gethostname

# Connect to WITec Control
hostname = gethostname()
CLSID = "{C45E77CE-3D66-489A-B5E2-159F443BD1AA}"
IBUCSAccess = win32com.client.DispatchEx(CLSID, machine=hostname, clsctx=pythoncom.CLSCTX_REMOTE_SERVER)
IBUCSCore = win32com.client.CastTo(IBUCSAccess, 'IBUCSCore')

IBUCSAccess.RequestWriteAccess(True)
#%%



# make parameter modifiers for large image scan
intTime = IBUCSCore.GetSubSystemDefaultInterface("UserParameters|SequencerLargeScaleImaging|SmoothScanIntegrationTime")
intTime = win32com.client.CastTo(intTime, 'IBUCSFloat')


scanMethod = IBUCSCore.GetSubSystemDefaultInterface("UserParameters|SequencerLargeScaleImaging|ScanMethod")

autoFocus = IBUCSCore.GetSubSystemDefaultInterface("UserParameters|SequencerAutoFocus|Start")

LargeAreaScanStarter = IBUCSCore.GetSubSystemDefaultInterface("UserParameters|SequencerLargeScaleImaging|Start")

GeometryDepth = IBUCSCore.GetSubSystemDefaultInterface("UserParameters|SequencerLargeScaleImaging|Geometry|Depth")
GeometryDepth = win32com.client.CastTo(GeometryDepth, 'IBUCSFloat')

GeometryWidth = IBUCSCore.GetSubSystemDefaultInterface("UserParameters|SequencerLargeScaleImaging|Geometry|Width")
GeometryWidth = win32com.client.CastTo(GeometryWidth, 'IBUCSFloat')

GeometryHeight = IBUCSCore.GetSubSystemDefaultInterface("UserParameters|SequencerLargeScaleImaging|Geometry|Height")
GeometryHeight = win32com.client.CastTo(GeometryHeight, 'IBUCSFloat')

GeometryPoints = IBUCSCore.GetSubSystemDefaultInterface("UserParameters|SequencerLargeScaleImaging|PointsPerLine")
GeometryPoints = win32com.client.CastTo(GeometryPoints, 'IBUCSInt')

GeometryLines = IBUCSCore.GetSubSystemDefaultInterface("UserParameters|SequencerLargeScaleImaging|LinesPerImage")
GeometryLines = win32com.client.CastTo(GeometryLines, 'IBUCSInt')

GeometryLayers = IBUCSCore.GetSubSystemDefaultInterface("UserParameters|SequencerLargeScaleImaging|LayersPerScan")
GeometryLayers = win32com.client.CastTo(GeometryLayers, 'IBUCSInt')

GeometryCenterX = IBUCSCore.GetSubSystemDefaultInterface("UserParameters|SequencerLargeScaleImaging|Geometry|CenterX")
GeometryCenterX = win32com.client.CastTo(GeometryCenterX, 'IBUCSFloat')

GeometryCenterY = IBUCSCore.GetSubSystemDefaultInterface("UserParameters|SequencerLargeScaleImaging|Geometry|CenterX")
GeometryCenterY = win32com.client.CastTo(GeometryCenterY, 'IBUCSFloat')

GeometryCenterZ = IBUCSCore.GetSubSystemDefaultInterface("UserParameters|SequencerLargeScaleImaging|Geometry|CenterX")
GeometryCenterZ = win32com.client.CastTo(GeometryCenterZ, 'IBUCSFloat')

GeometryGamma = IBUCSCore.GetSubSystemDefaultInterface("UserParameters|SequencerLargeScaleImaging|Geometry|Gamma")
GeometryGamma = win32com.client.CastTo(GeometryGamma, 'IBUCSFloat')


SetterZeroXY = IBUCSCore.GetSubSystemDefaultInterface("UserParameters|SamplePositioning|SetZeroXY")

setterPosMotorX = IBUCSCore.GetSubSystemDefaultInterface("UserParameters|SamplePositioning|AbsolutePositionX")
setterPosMotorX = win32com.client.CastTo(setterPosMotorX, 'IBUCSFloat')

setterPosMotorY = IBUCSCore.GetSubSystemDefaultInterface("UserParameters|SamplePositioning|AbsolutePositionY")
setterPosMotorY = win32com.client.CastTo(setterPosMotorY, 'IBUCSFloat')

triggerMotorMovement = IBUCSCore.GetSubSystemDefaultInterface("UserParameters|SamplePositioning|GoToPosition")

movePosPiezoX = IBUCSCore.GetSubSystemDefaultInterface("UserParameters|ScanTable|PositionX")
movePosPiezoX = win32com.client.CastTo(movePosPiezoX, 'IBUCSFloat')

movePosPiezoY = IBUCSCore.GetSubSystemDefaultInterface("UserParameters|ScanTable|PositionY")
movePosPiezoY = win32com.client.CastTo(movePosPiezoY, 'IBUCSFloat')


setterName = IBUCSCore.GetSubSystemDefaultInterface("UserParameters|Naming|SampleName")
setterName = win32com.client.CastTo(setterName, 'IBUCSString')

print(dir(autoFocus))



#%%
def setScanMethod(method):
    if method == 'A':
        scanMethod.SetValueString('Area')
    if method == 'D':
        scanMethod.SetValueString('Depth')
    if method == 'S':
        scanMethod.SetValueString('Stack')

def setIntegrationTime(value):
    intTime.SetValue(value)
    

def startAutofocus():
    autoFocus.OperateTrigger()
    

def SetZeroXY():
    SetterZeroXY.OperateTrigger()
    

def specifyAreaScan(height, width, points, lines, x ,y, z, angle):
    setScanMethod('A')
    
    GeometryWidth.SetValue(width)
    GeometryHeight.SetValue(height)
    GeometryPoints.SetValue(points)
    GeometryLines.SetValue(lines)

    
    GeometryCenterX.SetValue(x)
    GeometryCenterY.SetValue(y)
    GeometryCenterZ.SetValue(z)
    
    GeometryGamma.SetValue(angle)

def startLargeAreaScan():
    LargeAreaScanStarter.OperateTrigger()


def moveToPositionMotor(x,y):
    setterPosMotorX.SetValue(x)
    setterPosMotorY.SetValue(y)
    triggerMotorMovement.OperateTrigger()

def moveToPositionPiezo(x,y):
    movePosPiezoX.SetValue(x)
    movePosPiezoY.SetValue(y)

#%%
moveToPositionMotor(0,0)


specifyAreaScan(4, 4, 4, 4, 0, 0, 0, 10)
startLargeAreaScan()

moveToPositionMotor(30,30)

specifyAreaScan(4, 4, 4, 4, 0, 0, 0, 10)
startLargeAreaScan()

moveToPositionPiezo(0,0)


#%%

# Get a parameter modifier

# parameterModifier = IBUCSCore.GetSubSystemDefaultInterface("UserParameters|SequencerLargeScaleImaging|SmoothScanIntegrationTime")
# parameterModifierFloat = win32com.client.CastTo(parameterModifier, 'IBUCSFloat')

# # Read the value of a float parameter
# value = parameterModifierFloat.GetValue()
# print(value)




# # Get a parameter modifier

# parameterModifier = IBUCSCore.GetSubSystemDefaultInterface("UserParameters|SequencerLargeScaleImaging|SmoothScanIntegrationTime")
# parameterModifierFloat = win32com.client.CastTo(parameterModifier, 'IBUCSFloat')

# # Read the value of a float parameter
# value = parameterModifierFloat.GetValue()
# print(value)




