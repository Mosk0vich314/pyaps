'<ADbasic Header, Headerversion 001.001>
' Process_Number                 = 5
' Initial_Processdelay           = 1000
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

'Inputs general:
'PAR_1 = Gain DAC 1
'PAR_2 = Gain DAC 2
'PAR_3 = Gain DAC 3
'PAR_4 = Gain DAC 4
'PAR_5 = Address AIN F4/18
'PAR_6 = Address AOUT 4/16
'PAR_7 = Address DIO-32
'PAR_8 = V output channel

'Measurement parameters:
'FPAR_1 = actual AI2 value in bin
'FPAR_2 = actual AI3 value in bin
'FPAR_3 = actual AI4 value in bin
'FPAR_4 = actual AI5 value in bin

'Inputs Gt:
'PAR_11 = total run time
'PAR_12 = initial voltage point
'PAR_13 = set voltage point
'PAR_14 = final voltage point
'PAR_15 = no of points to average over
'PAR_16 = no of loops to wait before measure
'PAR_17 = length of voltage array
'PAR_18 = actual counter

'Outputs:
'DATA_2 = averaged AI1 bin array 
'DATA_3 = averaged AI2 bin array 
'DATA_4 = averaged AI3 bin array 
'DATA_5 = averaged AI4 bin array 
'DATA_6 = read ADC values

#INCLUDE ADwinPro_all.Inc

DIM piezoflag as long
DIM piezocounter_low, piezocounter_high as long

INIT:
  piezoflag = 0 'to start measurement directly after start voltage is reached, then increase output 
  piezocounter_low = 0
  piezocounter_high = 0

  'set DIO input and outputs. 0-15 as inputs, 16-31 as outputs; 0=input, 1=output
  P2_DigProg(3, 1111b)
  P2_Digout(3, 16, 0 )
  PAR_20 = 1000000
  PAR_21 = 100
  
EVENT:
  
    
  SELECTCASE piezoflag 'measurement: 0 = wait ; 1 = pulse
  
    CASE 0 'output desired voltage on DAC1
      IF(piezocounter_low >= PAR_20) THEN
        piezocounter_low = 0
        P2_Digout(3, 16, 1 ) ' start pulse 
        piezoflag = 1
      ELSE
        piezocounter_low = piezocounter_low + 1
      ENDIF
   
    CASE 1 
      IF(piezocounter_high >= PAR_21) THEN
        piezocounter_high = 0
        P2_Digout(3, 16, 0 ) ' end pulse 
        piezoflag = 0
      ELSE
        piezocounter_high = piezocounter_high + 1
      ENDIF
      

  ENDSELECT
  
FINISH:
