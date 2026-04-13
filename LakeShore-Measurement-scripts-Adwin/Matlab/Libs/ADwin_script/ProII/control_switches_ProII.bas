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
' Info_Last_Save                 = DDM05334  EMPA\Lab405
'<Header End>
'Gt_18b: ramps voltage on AO1, recording voltage on AI 1-4

'PAR_43 = clock bit 
'PAR_44 = latch bit 
'PAR_45 = data bit 
'PAR_46 = disable bit 
'PAR_47 = clock bit value
'PAR_48 = latch bit value
'PAR_49 = data bit value

#INCLUDE ADwinPro_all.Inc

INIT:

  'set DIO input and outputs. 0-15 as inputs, 16-31 as outputs
  P2_DigProg(PAR_7, 1100b)
  
EVENT:

  P2_Digout(PAR_7, PAR_43, PAR_47)
  P2_Digout(PAR_7, PAR_44, PAR_48)
  P2_Digout(PAR_7, PAR_45, PAR_49)
  P2_Digout(PAR_7, PAR_46, PAR_50)
  
  end
  
FINISH:
