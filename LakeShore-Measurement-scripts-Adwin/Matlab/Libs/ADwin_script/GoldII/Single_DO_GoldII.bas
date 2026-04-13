'<ADbasic Header, Headerversion 001.001>
' Process_Number                 = 5
' Initial_Processdelay           = 10000
' Eventsource                    = Timer
' Control_long_Delays_for_Stop   = No
' Priority                       = High
' Version                        = 1
' ADbasic_Version                = 6.3.0
' Optimize                       = Yes
' Optimize_Level                 = 1
' Stacksize                      = 1000
' Info_Last_Save                 = DDM05364  EMPA\lab405
'<Header End>
#INCLUDE ADwinGoldII.inc

INIT:
  Conf_DIO(1111b)


EVENT:
  Digout(PAR_50, PAR_51)
  
FINISH:

