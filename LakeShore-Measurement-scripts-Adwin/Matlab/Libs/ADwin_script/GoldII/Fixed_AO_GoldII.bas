'<ADbasic Header, Headerversion 001.001>
' Process_Number                 = 3
' Initial_Processdelay           = 3000
' Eventsource                    = Timer
' Control_long_Delays_for_Stop   = No
' Priority                       = High
' Version                        = 1
' ADbasic_Version                = 6.4.0
' Optimize                       = Yes
' Optimize_Level                 = 1
' Stacksize                      = 1000
' Info_Last_Save                 = DDM04617  EMPA\Lab405
'<Header End>
' fixed_voltage.bas: ramps voltage

'Inputs general:
'PAR_5 = Address AIN F4/18
'PAR_6 = Address AOUT 4/16
'PAR_7 = Address DIO-32
'PAR_9 = output channel

'Inputs:
'PAR_40 = current voltage
'PAR_41 = initial voltage point 
'PAR_42 = set voltage point 

#INCLUDE ADwinGoldII.inc

DIM actual_V as long

INIT:
   
  actual_V = PAR_41
  'PAR_40 = actual_V
  'set DAC to first value
  DAC(PAR_9, actual_V)

   
EVENT:

  IF(PAR_42 > actual_V) THEN INC(actual_V)      
  IF(PAR_42 < actual_V) THEN DEC(actual_V) 
  DAC(PAR_9, actual_V)
  PAR_40 = actual_V
  
  IF  (actual_V = PAR_42) THEN
    DAC(PAR_9, actual_V) 
    end
  ENDIF
  
FINISH:
  'DAC(PAR_9, PAR_42)  
