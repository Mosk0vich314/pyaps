'<ADbasic Header, Headerversion 001.001>
' Process_Number                 = 2
' Initial_Processdelay           = 1000
' Eventsource                    = Timer
' Control_long_Delays_for_Stop   = No
' Priority                       = High
' Version                        = 1
' ADbasic_Version                = 6.3.0
' Optimize                       = Yes
' Optimize_Level                 = 1
' Stacksize                      = 1000
' Info_Last_Save                 = DDM06513  EMPA\Lab405
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
'PAR_10 = ADC resolution
'PAR_20 = Number of ADC pairs

'FPAR_26 = IV convert 1 autoranging 0 no, 1 lin, 2 log
'FPAR_27 = IV convert 2 autoranging 0 no, 1 lin, 2 log
'FPAR_28 = IV convert 3 autoranging 0 no, 1 lin, 2 log
'FPAR_29 = IV convert 4 autoranging 0 no, 1 lin, 2 log
'FPAR_44 = IV convert 5 autoranging 0 no, 1 lin, 2 log
'FPAR_45 = IV convert 6 autoranging 0 no, 1 lin, 2 log
'FPAR_46 = IV convert 7 autoranging 0 no, 1 lin, 2 log
'FPAR_47 = IV convert 8 autoranging 0 no, 1 lin, 2 log

'Measurement parameters:
'FPAR_1 = actual AI2 value in bin
'FPAR_2 = actual AI3 value in bin
'FPAR_3 = actual AI4 value in bin
'FPAR_4 = actual AI5 value in bin

'Inputs Gt:
'PAR_11 = initial voltage point
'PAR_12 = set voltage point
'PAR_13 = final voltage point
'PAR_14 = length of time array
'PAR_21 = no of points to average over
'PAR_22 = no of loops to wait before measure
'PAR_17 = loops to wait to limit AO rate
'PAR_18 = actual time counter
'PAR_19 = actual V counter
'measureflag = measurements flag

'Outputs:
'DATA_2 = averaged AI1 bin array 
'DATA_3 = averaged AI2 bin array 
'DATA_4 = averaged AI3 bin array 
'DATA_5 = averaged AI4 bin array 
'DATA_6 = averaged AI5 bin array 
'DATA_7 = averaged AI6 bin array 
'DATA_8 = averaged AI7 bin array 
'DATA_9 = averaged AI7 bin array 

#INCLUDE ADwinGoldII.inc
'#INCLUDE C:\Users\lab405\Desktop\Lakeshore-ADwin-GoldII\Matlab\ADwin_script\Additional_functions.Inc

DIM DATA_2[2000000] as float
DIM DATA_3[2000000] as float
DIM DATA_4[2000000] as float
DIM DATA_5[2000000] as float
DIM DATA_6[2000000] as float
DIM DATA_7[2000000] as float
DIM DATA_8[2000000] as float
DIM DATA_9[2000000] as float
DIM DATA_11[8] as long

DIM measureflag as long
DIM actual_V as long
DIM totalcurrent1,totalcurrent2,totalcurrent3,totalcurrent4,totalcurrent5,totalcurrent6,totalcurrent7,totalcurrent8 as float
DIM avgcounter,waitcounter,timecounter as long
DIM bin1,bin2,bin3,bin4,bin5,bin6,bin7,bin8 as long
DIM output_min, output_max, bin_size as float
DIM IV_gain1,IV_gain2,IV_gain3,IV_gain4,IV_gain5,IV_gain6,IV_gain7,IV_gain8 as float
DIM ADC_gain1, ADC_gain2, ADC_gain3, ADC_gain4, ADC_gain5, ADC_gain6, ADC_gain7, ADC_gain8 as float

INIT:
  measureflag = 0  
  avgcounter = 0
  waitcounter = 0
  totalcurrent1 = 0
  totalcurrent2 = 0
  totalcurrent3 = 0
  totalcurrent4 = 0
  totalcurrent5 = 0
  totalcurrent6 = 0
  totalcurrent7 = 0
  totalcurrent8 = 0
  timecounter = 1
    
  'convert bin to V
  output_min = -10
  output_max = 9.99969
  bin_size = (output_max-output_min) / (2^PAR_10)
        
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

  SELECTCASE measureflag 'measurement: 0 = ramp to next voltage point ; 1 = limit sweep rate;  2 = wait for measurement; 3 = measure; 4 = ramp to next voltage point; 5 = limit sweep rate;
  
    CASE 0 ' wait for measurement 
      IF(waitcounter = PAR_22) THEN
        avgcounter = 0
        waitcounter = 0
        measureflag = 1
      ELSE
        waitcounter = waitcounter + 1
      ENDIF
      
    CASE 1 'perform measurement
      
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
      Set_Mux1(00000b) 'set MUX1
      Set_Mux2(00000b) 'set MUX1
      IO_Sleep(200)
      
      'read data
      START_CONV(11b)
      WAIT_EOC(11b)
      bin1 = READ_ADC24(1)/64
      bin2 = READ_ADC24(2)/64
      
      totalcurrent1 = totalcurrent1 + ((output_min + (bin1 * bin_size)) * IV_gain1 / 2^ADC_gain1)
      totalcurrent2 = totalcurrent2 + ((output_min + (bin2 * bin_size)) * IV_gain2 / 2^ADC_gain2)

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
     
      totalcurrent3 = totalcurrent3 + ((output_min + (bin3 * bin_size)) * IV_gain3 / 2^ADC_gain3)
      totalcurrent4 = totalcurrent4 + ((output_min + (bin4 * bin_size)) * IV_gain4 / 2^ADC_gain4)

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
      
        totalcurrent5 = totalcurrent5 + ((output_min + (bin5 * bin_size)) * IV_gain5 / 2^ADC_gain5)
        totalcurrent6 = totalcurrent6 + ((output_min + (bin6 * bin_size)) * IV_gain6 / 2^ADC_gain6)

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
      
        totalcurrent7 = totalcurrent7 + ((output_min + (bin7 * bin_size)) * IV_gain7 / 2^ADC_gain7)
        totalcurrent8 = totalcurrent8 + ((output_min + (bin8 * bin_size)) * IV_gain8 / 2^ADC_gain8)

      ENDIF
      
      avgcounter = avgcounter + 1
      
      ' get averaging
      IF(avgcounter = PAR_21) THEN
        FPAR_1 = totalcurrent1 / PAR_21
        FPAR_2 = totalcurrent2 / PAR_21
        FPAR_3 = totalcurrent3 / PAR_21
        FPAR_4 = totalcurrent4 / PAR_21

        DATA_2[timecounter]= FPAR_1
        DATA_3[timecounter]= FPAR_2
        DATA_4[timecounter]= FPAR_3
        DATA_5[timecounter]= FPAR_4
        
        totalcurrent1 = 0
        totalcurrent2 = 0
        totalcurrent3 = 0
        totalcurrent4 = 0
      
        IF (PAR_20 > 2) THEN
          FPAR_5 = totalcurrent5 / PAR_21
          FPAR_6 = totalcurrent6 / PAR_21
          DATA_6[timecounter]= FPAR_5
          DATA_7[timecounter]= FPAR_6
          totalcurrent5 = 0
          totalcurrent6 = 0
        ENDIF
        IF (PAR_20 > 3) THEN
          FPAR_7 = totalcurrent7 / PAR_21
          FPAR_8 = totalcurrent8 / PAR_21
          DATA_8[timecounter]= FPAR_7
          DATA_9[timecounter]= FPAR_8
          totalcurrent7 = 0
          totalcurrent8 = 0
        ENDIF
        
        timecounter = timecounter + 1
        PAR_19 = timecounter 
        IF (timecounter = PAR_14 + 1) THEN
          end
        ELSE
          measureflag = 0
        ENDIF
      ENDIF
   
       
  ENDSELECT
  
FINISH:
  DAC(PAR_8, PAR_13)
