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

DIM DATA_1[50000] as long     'voltage input  
DIM DATA_2[50000] as float    'AI1
DIM DATA_3[50000] as float    'AI2
DIM DATA_4[50000] as float    'AI3
DIM DATA_5[50000] as float    'AI4
DIM DATA_6[50000] as float    'AI5
DIM DATA_7[50000] as float    'AI6
DIM DATA_8[50000] as float    'AI7
DIM DATA_9[50000] as float    'AI8
DIM DATA_11[8] as long

DIM measureflag as long
DIM totalcurrent1,totalcurrent2,totalcurrent3,totalcurrent4,totalcurrent5,totalcurrent6,totalcurrent7,totalcurrent8 as float
DIM avgcounter,waitcounter,voltagecounter, waitcounterFirstpoint as long
DIM actual_V as long
DIM bin1,bin2,bin3,bin4,bin5,bin6,bin7,bin8 as long
DIM output_min, output_max, bin_size as float
DIM IV_gain1,IV_gain2,IV_gain3,IV_gain4,IV_gain5,IV_gain6,IV_gain7,IV_gain8 as float
DIM ADC_gain1, ADC_gain2, ADC_gain3, ADC_gain4, ADC_gain5, ADC_gain6, ADC_gain7, ADC_gain8 as long

INIT:
  measureflag = 9 'to start measurement directly after start voltage is reached, then increase output 
  avgcounter = 0
  waitcounter = 0
  waitcounterFirstpoint = 0
  voltagecounter = 1
  totalcurrent1 = 0
  totalcurrent2 = 0
  totalcurrent3 = 0
  totalcurrent4 = 0
  totalcurrent5 = 0
  totalcurrent6 = 0
  totalcurrent7 = 0
  totalcurrent8 = 0
  
  actual_V = DATA_1[1]
  
  'convert bin to V
  output_min = -10
  output_max = 9.99969
  bin_size = (output_max-output_min) / (2^PAR_10)
  
  'set DAC to first value
  DAC(PAR_8, actual_V)
  
  'set DIO input and outputs. 0-15 as inputs, 16-31 as outputs; 0=input, 1=output
  'P2_DigProg(PAR_7, 1100b)
  
  'set IV gain
  IV_gain1 = 10^(-1*FPAR_27)
  IV_gain2 = 10^(-1*FPAR_28)
  IV_gain3 = 10^(-1*FPAR_29)
  IV_gain4 = 10^(-1*FPAR_30)
  IV_gain5 = 10^(-1*FPAR_31)
  IV_gain6 = 10^(-1*FPAR_32)
  IV_gain7 = 10^(-1*FPAR_33)
  IV_gain8 = 10^(-1*FPAR_34)  
  
  ' get ADC gains
  ADC_gain1 = DATA_11[1] 
  ADC_gain2 = DATA_11[2] 
  ADC_gain3 = DATA_11[3] 
  ADC_gain4 = DATA_11[4] 
  ADC_gain5 = DATA_11[5] 
  ADC_gain6 = DATA_11[6] 
  ADC_gain7 = DATA_11[7] 
  ADC_gain8 = DATA_11[8] 
    
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
        totalcurrent2 = 0
        totalcurrent3 = 0
        totalcurrent4 = 0
        totalcurrent5 = 0
        totalcurrent6 = 0
        totalcurrent7 = 0
        totalcurrent8 = 0
      ELSE
        waitcounter = waitcounter + 1
      ENDIF
        
    CASE 2    

      ' select multiplexer
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

      IF (ADC_gain2 = 0) THEN
        Set_Mux2(00000b) 'set MUX1
      ENDIF
      IF (ADC_gain2 = 1) THEN
        Set_Mux2(01000b) 'set MUX1
      ENDIF
      IF (ADC_gain2 = 2) THEN
        Set_Mux2(10000b) 'set MUX1
      ENDIF
      IF (ADC_gain2 = 3) THEN
        Set_Mux2(11000b) 'set MUX1
      ENDIF
      IO_Sleep(200)
      
      'read data
      START_CONV(11b)
      WAIT_EOC(11b)
      bin1 = READ_ADC24(1)/64
      bin2 = READ_ADC24(2)/64
      
      totalcurrent1 = totalcurrent1 + bin1
      totalcurrent2 = totalcurrent2 + bin2

      ' select multiplexer
      IF (ADC_gain3 = 0) THEN
        Set_Mux1(00001b) 'set MUX1
      ENDIF
      IF (ADC_gain3 = 1) THEN
        Set_Mux1(01001b) 'set MUX1
      ENDIF
      IF (ADC_gain3 = 2) THEN
        Set_Mux1(10001b) 'set MUX1
      ENDIF
      IF (ADC_gain3 = 3) THEN
        Set_Mux1(11001b) 'set MUX1
      ENDIF

      IF (ADC_gain4 = 0) THEN
        Set_Mux2(00001b) 'set MUX2
      ENDIF
      IF (ADC_gain4 = 1) THEN
        Set_Mux2(01001b) 'set MUX2
      ENDIF
      IF (ADC_gain4 = 2) THEN
        Set_Mux2(10001b) 'set MUX2
      ENDIF
      IF (ADC_gain4 = 3) THEN
        Set_Mux2(11001b) 'set MUX2
      ENDIF
      IO_Sleep(200)
      
      'read data
      START_CONV(11b)
      WAIT_EOC(11b)
      bin3 = READ_ADC24(1)/64
      bin4 = READ_ADC24(2)/64
      
      totalcurrent3 = totalcurrent3 + bin3
      totalcurrent4 = totalcurrent4 + bin4

      IF (PAR_20 > 2) THEN
        ' select multiplexer
        IF (ADC_gain5 = 0) THEN
          Set_Mux1(00010b) 'set MUX1
        ENDIF
        IF (ADC_gain5 = 1) THEN
          Set_Mux1(01010b) 'set MUX1
        ENDIF
        IF (ADC_gain5 = 2) THEN
          Set_Mux1(10010b) 'set MUX1
        ENDIF
        IF (ADC_gain5 = 3) THEN
          Set_Mux1(11010b) 'set MUX1
        ENDIF

        IF (ADC_gain6 = 0) THEN
          Set_Mux2(00010b) 'set MUX2
        ENDIF
        IF (ADC_gain6 = 1) THEN
          Set_Mux2(01010b) 'set MUX2
        ENDIF
        IF (ADC_gain6 = 2) THEN
          Set_Mux2(10010b) 'set MUX2
        ENDIF
        IF (ADC_gain6 = 3) THEN
          Set_Mux2(11010b) 'set MUX2
        ENDIF
        IO_Sleep(200)
      
        'read data
        START_CONV(11b)
        WAIT_EOC(11b)
        bin5 = READ_ADC24(1)/64
        bin6 = READ_ADC24(2)/64
      
        totalcurrent5 = totalcurrent1 + bin5
        totalcurrent6 = totalcurrent2 + bin6

      ENDIF
      
      IF (PAR_20 > 3) THEN
        ' select multiplexer
        IF (ADC_gain7 = 0) THEN
          Set_Mux1(00011b) 'set MUX1
        ENDIF
        IF (ADC_gain7 = 1) THEN
          Set_Mux1(01011b) 'set MUX1
        ENDIF
        IF (ADC_gain7 = 2) THEN
          Set_Mux1(10011b) 'set MUX1
        ENDIF
        IF (ADC_gain7 = 3) THEN
          Set_Mux1(11011b) 'set MUX1
        ENDIF

        IF (ADC_gain8 = 0) THEN
          Set_Mux2(00011b) 'set MUX2
        ENDIF
        IF (ADC_gain8 = 1) THEN
          Set_Mux2(01011b) 'set MUX2
        ENDIF
        IF (ADC_gain8 = 2) THEN
          Set_Mux2(10011b) 'set MUX2
        ENDIF
        IF (ADC_gain8 = 3) THEN
          Set_Mux2(11011b) 'set MUX2
        ENDIF
        IO_Sleep(200)
      
        'read data
        START_CONV(11b)
        WAIT_EOC(11b)
        bin7 = READ_ADC24(1)/64
        bin8 = READ_ADC24(2)/64
      
        totalcurrent7 = totalcurrent7 + bin7
        totalcurrent8 = totalcurrent8 + bin8
      ENDIF
      
      avgcounter = avgcounter + 1
          
      ' get averaging
      IF(avgcounter = PAR_21) THEN
        
        FPAR_1 = ((output_min + (totalcurrent1 * bin_size / PAR_21)) * IV_gain1 / 2^ADC_gain1)
        FPAR_2 = ((output_min + (totalcurrent2 * bin_size / PAR_21)) * IV_gain2 / 2^ADC_gain2)
        FPAR_3 = ((output_min + (totalcurrent3 * bin_size / PAR_21)) * IV_gain3 / 2^ADC_gain3)
        FPAR_4 = ((output_min + (totalcurrent4 * bin_size / PAR_21)) * IV_gain4 / 2^ADC_gain4)
        
        DATA_2[voltagecounter]= FPAR_1
        DATA_3[voltagecounter]= FPAR_2
        DATA_4[voltagecounter]= FPAR_3
        DATA_5[voltagecounter]= FPAR_4
        
        totalcurrent1 = 0
        totalcurrent2 = 0
        totalcurrent3 = 0
        totalcurrent4 = 0
        
        IF (PAR_20 > 2) THEN
          FPAR_5 = ((output_min + (totalcurrent5 * bin_size / PAR_21)) * IV_gain5 / 2^ADC_gain5)
          FPAR_6 = ((output_min + (totalcurrent6 * bin_size / PAR_21)) * IV_gain6 / 2^ADC_gain6)
          DATA_6[voltagecounter]= FPAR_5
          DATA_7[voltagecounter]= FPAR_6
          totalcurrent5 = 0
          totalcurrent6 = 0
        ENDIF
        IF (PAR_20 > 3) THEN
          FPAR_7 = ((output_min + (totalcurrent7 * bin_size / PAR_21)) * IV_gain7 / 2^ADC_gain7)
          FPAR_8 = ((output_min + (totalcurrent8 * bin_size / PAR_21)) * IV_gain8 / 2^ADC_gain8)
          DATA_8[voltagecounter]= FPAR_7
          DATA_9[voltagecounter]= FPAR_8
          totalcurrent7 = 0
          totalcurrent8 = 0
        ENDIF
                   
        measureflag = 0
        voltagecounter = voltagecounter + 1
        FPAR_9 = voltagecounter
      ENDIF

      ' stop when reached end of vector
      IF (voltagecounter  = PAR_23 + 1) THEN   
        end  
      ENDIF
          
  ENDSELECT
  
FINISH:
  '  DAC(PAR_8, DATA_1[PAR_23])
