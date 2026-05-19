'<ADbasic Header, Headerversion 001.001>
' Process_Number                 = 5
' Initial_Processdelay           = 3000
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
'Gt_18b: ramps voltage on AO1, recording voltage on AI 1-4

'PAR_43 = clock bit 
'PAR_44 = latch bit 
'PAR_45 = data bit 
'PAR_46 = disable bit 

'PAR_47 = clock bit value
'PAR_48 = latch bit value 
'PAR_49 = data bit value
'PAR_50 = disable bit value

#INCLUDE ADwinGoldII.Inc

'DIM DATA_1[100000] as long     'voltage input  
'DIM DATA_2[100000] as long     'voltage input  
'DIM DATA_3[100000] as long     'voltage input  
'DIM DATA_4[100000] as long     'voltage input  
'DIM counter as long     

INIT:
  ' counter = 1
  'set DIO input and outputs. 0-15 as inputs, 16-31 as outputs
  Conf_DIO(1111b)
  
EVENT:

  'DATA_1[counter] = PAR_47
  'DATA_2[counter] = PAR_48
  'DATA_3[counter] = PAR_49
  'DATA_4[counter] = PAR_50
  
  Digout(PAR_43, PAR_47)
  Digout(PAR_44, PAR_48)
  Digout(PAR_45, PAR_49)
  Digout(PAR_46, PAR_50)
  'counter = counter + 1
  
FINISH:
