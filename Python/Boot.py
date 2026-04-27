###################################
## Driver written by M.L. Perrin ##
## contact: m.l.perrin@tudelft.nl #
###################################

##### IMPORT MODULES #####
import os
import ADwin
import ctypes
import serial
from math import log10
from time import *
from visa import *
import platform

pc_name = platform.node()
if pc_name == 'TUD203025':
    resolution_input = 16.0                                          # ADWin is 16 or 18 bits?
    AO_gate = 2
    AO_piezo = 3
    AO_switch = 4   
    cali_path = '../Mickael_calibration/Calibration S4c - LowT/S4c_lowT' 
if pc_name == 'TUD205839':
    resolution_input = 16.0                                          # ADWin is 16 or 18 bits?
    cali_path = '../Mickael_calibration/Calibration S4c - Piezo/S4c_piezo' 
    AO_gate = 2
    AO_piezo = 2
    AO_switch = 2
if pc_name == 'TUD205822':
    resolution_input = 18.0                                          # ADWin is 16 or 18 bits?
    cali_path = '../Mickael_calibration/Calibration S4c - Liquid/S4c_liquidcell' 
    AO_gate = 2
    AO_piezo = 3
    AO_switch = 4
   
resolution_output = 16.0                                          # ADWin is 16 or 18 bits?


##### LOAD DRIVERS #####
execfile('Libs/Functions.py')
execfile('Libs/ADwin_driver.py')
execfile('Libs/Measurement_routines.py')
execfile('Libs/data_processing.py')
#execfile('Libs/SR830.py')

##### GENERAL SETTINGS #####
output_range = 10.0                                        # AO1 output range
input_range = 2.5                                          # AI1 input range

refresh_rate = 100.0                                         # Hz
G0 = 7.74809173e-5                                          # conductance quantum
motor_min = 1e6                                             # counts
motor_max = -5e6                                             # counts
date, runnumber = make_filename('set')         


##### Reset PIEZO####
try:
    piezo_V=int(ADwin_get_Par(1))
    if resolution_input==16 :
        ADwin_load_process('set_piezo.T97') # load piezo voltage ramp as process 7
    if resolution_input==18:
        ADwin_load_process('set_piezo_18b.TB7') # load piezo voltage ramp as process 7
        
    if piezo_V!=0:
        if piezo_V > 65535:
           piezo_V = 65535
        if piezo_V < 32768:
           piezo_V = 32768
        ADwin_set_Par(1,piezo_V)
        ADwin_ramp_piezo(0.0,5000)
        print "Piezo ramped to zero"

    else:
        print "Piezo not ramped"
except: 
    print "Rebooting Adwin"

##### BOOT ADWIN #####
if resolution_input==16:
    clockfrequency = 40.0e6                                    # ADwin frequency 
    ADwin_boot(16)                                    # boot ADwin
    ADwin_load_process('AO1_read_MUX12.T91') # load record_IV as process 1
    ADwin_load_process('Gt_MUX12.T92') # load record_G(t) as process 2
    ADwin_load_process('piezo_histogram.T94') # load piezo histogram as process 4
    ADwin_load_process('AO_gate.T95') # load apply gate voltage as process 5
    ADwin_load_process('AO_switch.T96') # load switch voltage as process 6
    ADwin_load_process('set_piezo.T97') # load piezo voltage ramp as process 7
    log_conversion = read_data_file(cali_path + '_16bit.txt',2) # logarithmic amplifier conversion table


if resolution_input==18:
    clockfrequency = 300.0e6                                    # ADwin frequency 
    ADwin_boot(18)                                    # boot ADwin
    ADwin_load_process('AO1_read_MUX12_18b.TB1') # load record_IV as process 1
    ADwin_load_process('Gt_MUX12_18b.TB2') # load record_G(t) as process 2
    #ADwin_load_process('read_lockin_MUX12_18b.TB3') # load read_lockin as process 3
    ADwin_load_process('CV_18b.TB3') # load CV sweep as process 3
    ADwin_load_process('piezo_histogram_18b.TB4') # load piezo histogram as process 4
    ADwin_load_process('AO_gate_18b.TB5') # load apply gate voltage as process 5
    ADwin_load_process('AO_switch_18b.TB6') # load switch voltage as process 6
    ADwin_load_process('set_piezo_18b.TB7') # load piezo voltage ramp as process 7
    ADwin_load_process('IVg_sweep_18b.TB8') # load piezo histogram resume as process 8
    ADwin_load_process('piezo_histogram_18b_resume.TB9') # load piezo histogram as process 9

    ADwin_load_process('DIO_M1b_18b.TB0') # load M1b switch as process 10
   
    log_conversion = read_data_file(cali_path + '_18bit.txt',2) # logarithmic amplifier conversion table

##### INITIALIZE FAULHABER #####
execfile('Libs/Faulhaber_driver.py')
if motor == True:
    Faulhaber_command('en')             # initialize motor
    Faulhaber_command('LL 500000')        # set max postion
    Faulhaber_command('LL -7200000')    # set min position
    Faulhaber_command('APL 1')          # use limits (1 = on)
    Faulhaber_command('SP 300')         # set max speed (rpm)
    Faulhaber_command('AC 40')          # set max acceleration (rpm/s)
    Faulhaber_command('di') 

ADwin_set_Par(77,AO_gate)
ADwin_set_Par(78,AO_piezo)
ADwin_set_Par(79,AO_switch)

print "Boot successful"