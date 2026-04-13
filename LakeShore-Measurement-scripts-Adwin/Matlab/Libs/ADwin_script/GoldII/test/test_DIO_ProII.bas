'<ADbasic Header, Headerversion 001.001>
' Process_Number                 = 5
' Initial_Processdelay           = 2000
' Eventsource                    = Timer
' Control_long_Delays_for_Stop   = No
' Priority                       = High
' Version                        = 1
' ADbasic_Version                = 6.2.0
' Optimize                       = Yes
' Optimize_Level                 = 1
' Stacksize                      = 1000
' Info_Last_Save                 = DDM05754  EMPA\lab405
'<Header End>
'Gt_18b: ramps voltage on AO1, recording voltage on AI 1-4

'PAR_43 = number of coils 
'PAR_44 = bit number to set
'PAR_45 = bit value to set

#INCLUDE ADwinPro_all.Inc
#INCLUDE C:\Users\lab405\Desktop\ARS_cryo-ADwin_ProII\Matlab\ADwin_script\Additional_functions.Inc
DIM clock, latch, data, disable as long
DIM coil_counter as long

INIT:
  coil_counter = 1
  
  'set DIO input and outputs. 0-15 as inputs, 16-31 as outputs
  P2_DigProg(3, 1100b)
  
EVENT:

  
  
  P2_Digout(PAR_7, PAR_44, PAR_45)
  
  
FINISH:
