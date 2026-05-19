'<ADbasic Header, Headerversion 001.001>
' Process_Number                 = 1
' Initial_Processdelay           = 1000
' Eventsource                    = Timer
' Control_long_Delays_for_Stop   = No
' Priority                       = High
' Version                        = 1
' ADbasic_Version                = 6.4.0
' Optimize                       = Yes
' Optimize_Level                 = 1
' Stacksize                      = 1000
' Info_Last_Save                 = DDM08248  EMPA\qdev405
'<Header End>
' AO1_read_AI_18b.bas: ramps voltage on AO1, recording voltage on AI 1-4

'Inputs general:
'PAR_1 = Gain DAC 1
'PAR_2 = Gain DAC 2
'PAR_3 = Gain DAC 3
'PAR_4 = Gain DAC 4
'PAR_5 = Address AIN F4/18
'PAR_6 = Address AOUT 4/16
'PAR_7 = Address DIO-32
'PAR_8 = voltage sweep output channel
'PAR_10 = ADC resolution

'Measurement parameters:
'FPAR_1 = actual AI2 value in bin
'FPAR_2 = actual AI3 value in bin
'FPAR_3 = actual AI4 value in bin
'FPAR_4 = actual AI5 value in bin

'Inputs:
'PAR_21 = no of points to average over
'PAR_22 = no of loops to wait before measure
'PAR_23 = length of voltage array
'PAR_24 = actual counter

'DATA_1 = AO1 voltage values array (maximum length 1048576, so 4 arrays can be handled in parallel)

'Outputs:
'DATA_2 = averaged AI1 bin array 
'DATA_3 = averaged AI2 bin array 
'DATA_4 = averaged AI3 bin array 
'DATA_5 = averaged AI4 bin array 
'DATA_6 = read ADC values

#INCLUDE ADwinGoldII.inc
'#INCLUDE C:\Users\lab405\Desktop\Lakeshore-ADwin-GoldII\Matlab\ADwin_script\Additional_functions.Inc

DIM DATA_1[200000] as long     'voltage input  
DIM DATA_2[200000] as float    'ADC1
DIM DATA_11[8] as long

DIM DATA_6[4] as long         ' new ADC values

DIM measureflag as long
DIM totalcurrent1 as float
DIM avgcounter,waitcounter,voltagecounter,voltagecounter_new, waitcounterFirstpoint as long
DIM actual_V as long
DIM bin1 as long
DIM bit, IV1_bit0, IV1_bit1, IV1_bit2 as long
DIM output_min, output_max, bin_size as float
DIM IV_gain1 as float
DIM ADC_gain1 as long
DIM idx as long

INIT:
  measureflag = 9 'to start measurement directly after start voltage is reached, then increase output 
  avgcounter = 0
  waitcounter = 0
  waitcounterFirstpoint = 0
  voltagecounter = 1
  
  actual_V = DATA_1[1]
  
  'convert bin to V
  output_min = -10
  output_max = 9.99969
  bin_size = (output_max-output_min) / (2^PAR_10)
  

  'ADC gains
  ADC_gain1 = DATA_11[1] 
  IF (ADC_gain1 = 0) THEN
    Set_Mux1(00000b) 'set MUX1
  ENDIF
  IF (ADC_gain1 = 1) THEN
    Set_Mux1(01000b) 'set MUX1
  ENDIF
  IF (ADC_gain1 = 2) THEN
    Set_Mux1(10000b) 'set MUX1
  ENDIF
  IF (ADC_gain1 = 3) THEN
    Set_Mux1(11000b) 'set MUX1
  ENDIF
  
  'set DAC to first value
  DAC(PAR_8, actual_V)
  
  'set DIO input and outputs. 0-15 as inputs, 16-31 as outputs; 0=input, 1=output
  'P2_DigProg(PAR_7, 1100b)
   
  START_CONV(11b)
  Wait_EOC(11b)  
  
  'set IV gain
  IV_gain1 = 10^(-1*FPAR_27)
  
EVENT:

  SELECTCASE measureflag 'measurement: 0 = ramp to next voltage point ; 1 = wait ; 2 = measure 
      
    CASE 9 
      IF(waitcounterFirstpoint = 10e6/2000) THEN
        measureflag = 0
        START_CONV(11b)
        WAIT_EOC(11b)
      ELSE
        waitcounterFirstpoint = waitcounterFirstpoint + 1
      ENDIF
      
    CASE 0 'output desired voltage on DAC1
      PAR_24 = actual_V   
      PAR_25 = voltagecounter
      IF(DATA_1[voltagecounter] > actual_V) THEN INC(actual_V)      
      IF(DATA_1[voltagecounter] < actual_V) THEN DEC(actual_V) 
      IF  (actual_V = (DATA_1[voltagecounter])) THEN 
        measureflag = 1 
      ENDIF
      IF (voltagecounter <= PAR_23) THEN 
        DAC(PAR_8, actual_V)
      ENDIF
      
    CASE 1 'measure voltage on ADC1

      IF(waitcounter = PAR_22) THEN
        measureflag = 2
        waitcounter = 0
        avgcounter = 0
        totalcurrent1 = 0
      ELSE
        waitcounter = waitcounter + 1
      ENDIF
        
    CASE 2    
      ' read ADC
      ' WAIT_EOC(11b)
      bin1 = READ_ADC24(1)/64
      START_CONV(11b)
       
      totalcurrent1 = totalcurrent1 + bin1
      avgcounter = avgcounter + 1
          
      ' get averaging
      IF(avgcounter = PAR_21) THEN
        FPAR_1 = ((output_min + (totalcurrent1 * bin_size / PAR_21)) * IV_gain1 / 2^ADC_gain1)
        DATA_2[voltagecounter]= FPAR_1
                   
        measureflag = 0
        voltagecounter = voltagecounter + 1
      ENDIF

      ' stop when reached end of vector
      IF (voltagecounter  = PAR_23 + 1) THEN   
        end  
      ENDIF
          
  ENDSELECT
  
FINISH:
  '  DAC(PAR_8, DATA_1[PAR_23])
