'<ADbasic Header, Headerversion 001.001>
' Process_Number                 = 1
' Initial_Processdelay           = 3000
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

#INCLUDE ADwinPro_all.Inc
'#INCLUDE C:\Users\lab405\Desktop\Lakeshore-ADwin-GoldII\Matlab\ADwin_script\Additional_functions.Inc

DIM DATA_1[50000] as long     'voltage input  
DIM DATA_2[50000] as float    'AI1
DIM DATA_3[50000] as float    'AI1
DIM DATA_10[8] as long       'ADC values read
DIM DATA_11[8] as long       'ADC pre amplifier gains 

DIM measureflag as long
DIM totalcurrent1, totalcurrent2 as float
DIM voltage1, voltage2 as float
DIM avgcounter,waitcounter,voltagecounter,voltagecounter_new, waitcounterFirstpoint as long
DIM bin1, bin2 as long
DIM IV1_bit0, IV1_bit1, IV1_bit2, IV1_bit3 as long
DIM IV2_bit0, IV2_bit1, IV2_bit2, IV2_bit3 as long
DIM actual_V as long
DIM output_min, output_max, bin_size as float
DIM IV_gain1, IV_gain2 as float
DIM ADC_gain1, ADC_gain2 as long
DIM upper_gain1, upper_gain2  as float
DIM idx as long

INIT:
  measureflag = 9 'to start measurement directly after start voltage is reached, then increase output 
  avgcounter = 0
  waitcounter = 0
  voltagecounter = 1
  waitcounterFirstpoint = 0
  actual_V = DATA_1[1]
  
  'convert bin to V
  output_min = -10
  output_max = 9.99969
  bin_size = (output_max-output_min) / (2^PAR_10)
  
  'set DAC to first value
  P2_Write_DAC(PAR_6, PAR_8, actual_V)
  P2_Start_DAC(PAR_6)
  
  'set ADC gain
  P2_Set_gain(PAR_5, 1, DATA_11[1])
  P2_Set_gain(PAR_5, 2, DATA_11[2])
  
  ADC_gain1 = 2^DATA_11[1]
  ADC_gain2 = 2^DATA_11[2]
    
  ' set gain     
  upper_gain1 = FPAR_27
  upper_gain2 = FPAR_28
  IF (FPAR_27 = 4) THEN
    IV1_bit0 = 0
    IV1_bit1 = 0
    IV1_bit2 = 0
    IV1_bit3 = 0
  ENDIF     
  IF (FPAR_27 = 5) THEN
    IV1_bit0 = 1
    IV1_bit1 = 0
    IV1_bit2 = 0
    IV1_bit3 = 0
  ENDIF     
  IF (FPAR_27 = 6) THEN
    IV1_bit0 = 0
    IV1_bit1 = 1
    IV1_bit2 = 0
    IV1_bit3 = 0
  ENDIF     
  IF (FPAR_27 = 7) THEN
    IV1_bit0 = 1
    IV1_bit1 = 1
    IV1_bit2 = 0
    IV1_bit3 = 0
  ENDIF     
  IF (FPAR_27 = 8) THEN
    IV1_bit0 = 0
    IV1_bit1 = 0
    IV1_bit2 = 1
    IV1_bit3 = 0
  ENDIF     
  IF (FPAR_27 = 9) THEN
    IV1_bit0 = 1
    IV1_bit1 = 0
    IV1_bit2 = 1
    IV1_bit3 = 0
  ENDIF
  IF (FPAR_27 = 10) THEN
    IV1_bit0 = 0
    IV1_bit1 = 1
    IV1_bit2 = 1
    IV1_bit3 = 0
  ENDIF
  IF (FPAR_27 = 11) THEN
    IV1_bit0 = 1
    IV1_bit1 = 1
    IV1_bit2 = 1
    IV1_bit3 = 0
  ENDIF
  IF (FPAR_27 = 12) THEN
    IV1_bit0 = 0
    IV1_bit1 = 0
    IV1_bit2 = 0
    IV1_bit3 = 1
  ENDIF
  IF (FPAR_27 = 13) THEN
    IV1_bit0 = 1
    IV1_bit1 = 0
    IV1_bit2 = 0
    IV1_bit3 = 1
  ENDIF      
  
  IF (FPAR_28 = 4) THEN
    IV2_bit0 = 0
    IV2_bit1 = 0
    IV2_bit2 = 0
    IV2_bit3 = 0
  ENDIF     
  IF (FPAR_28 = 5) THEN
    IV2_bit0 = 1
    IV2_bit1 = 0
    IV2_bit2 = 0
    IV2_bit3 = 0
  ENDIF     
  IF (FPAR_28 = 6) THEN
    IV2_bit0 = 0
    IV2_bit1 = 1
    IV2_bit2 = 0
    IV2_bit3 = 0
  ENDIF     
  IF (FPAR_28 = 7) THEN
    IV2_bit0 = 1
    IV2_bit1 = 1
    IV2_bit2 = 0
    IV2_bit3 = 0
  ENDIF     
  IF (FPAR_28 = 8) THEN
    IV2_bit0 = 0
    IV2_bit1 = 0
    IV2_bit2 = 1
    IV2_bit3 = 0
  ENDIF     
  IF (FPAR_28 = 9) THEN
    IV2_bit0 = 1
    IV2_bit1 = 0
    IV2_bit2 = 1
    IV2_bit3 = 0
  ENDIF
  IF (FPAR_28 = 10) THEN
    IV2_bit0 = 0
    IV2_bit1 = 1
    IV2_bit2 = 1
    IV2_bit3 = 0
  ENDIF
  IF (FPAR_28 = 11) THEN
    IV2_bit0 = 1
    IV2_bit1 = 1
    IV2_bit2 = 1
    IV2_bit3 = 0
  ENDIF
  IF (FPAR_28 = 12) THEN
    IV2_bit0 = 0
    IV2_bit1 = 0
    IV2_bit2 = 0
    IV2_bit3 = 1
  ENDIF
  IF (FPAR_28 = 13) THEN
    IV2_bit0 = 1
    IV2_bit1 = 0
    IV2_bit2 = 0
    IV2_bit3 = 1
  ENDIF      
  P2_DigProg(PAR_7, 1111b)
 
  P2_Digout(PAR_7, 12, IV1_bit0)
  P2_Digout(PAR_7, 13, IV1_bit1)
  P2_Digout(PAR_7, 14, IV1_bit2)
  P2_Digout(PAR_7, 15, IV1_bit3)
  
  P2_Digout(PAR_7, 24, IV2_bit0)
  P2_Digout(PAR_7, 25, IV2_bit1)
  P2_Digout(PAR_7, 26, IV2_bit2)
  P2_Digout(PAR_7, 27, IV2_bit3)
   
  IV_gain1 = 10^(-1*FPAR_27)
  IV_gain2 = 10^(-1*FPAR_28)
 
  
EVENT:

  SELECTCASE measureflag 'measurement: 0 = ramp to next voltage point ; 1 = wait ; 2 = measure 
  
    CASE 9 
      IF(waitcounterFirstpoint = 30e6/2000) THEN
        measureflag = 0
        P2_Start_ConvF(PAR_5, 11111111) ' 0Fh = 000...0001111
        P2_Wait_EOC(PAR_5)
      ELSE
        waitcounterFirstpoint = waitcounterFirstpoint + 1
      ENDIF
     
    CASE 0 'output desired voltage on DAC1
      PAR_24 = actual_V   
      PAR_25 = voltagecounter
      IF(DATA_1[voltagecounter] > actual_V) THEN INC(actual_V)      
      IF(DATA_1[voltagecounter] < actual_V) THEN DEC(actual_V) 
      IF  (actual_V = (DATA_1[voltagecounter])) THEN 
        IF (PAR_22 = 0) THEN
          measureflag = 2 
          waitcounter = 0
          avgcounter = 0
        ELSE
          measureflag = 1 
        ENDIF 
      ENDIF
      IF (voltagecounter <= PAR_23) THEN 
        P2_Write_DAC(PAR_6, PAR_8, actual_V)
        P2_Start_DAC(PAR_6)
      ENDIF
      
    CASE 1 'measure voltage on ADC1

      IF(waitcounter = PAR_22) THEN
        measureflag = 2
        waitcounter = 0
        avgcounter = 0
        
        voltage1 = 0
        voltage2 = 0
      ELSE
        waitcounter = waitcounter + 1
      ENDIF
        
    CASE 2    
      'P2_Wait_EOC(PAR_5)
      P2_Read_ADCF8_24B(PAR_5, DATA_10, 1)
      P2_Start_ConvF(PAR_5, 0000000011111111b) ' 0Fh = 000...0001111     
       
      bin1 = DATA_10[1] / 64
      voltage1 = voltage1 + bin1
      
      bin2 = DATA_10[2] / 64
      voltage2 = voltage2 + bin2
                   
      avgcounter = avgcounter + 1
          
      ' get averaging
      IF(avgcounter = PAR_21) THEN
        FPAR_1 = ((output_min + (voltage1 * bin_size / PAR_21)) * IV_gain1 / 2^ADC_gain1)
        voltage1 = FPAR_1 / IV_gain1
        DATA_2[voltagecounter]= FPAR_1
        
        FPAR_2 = ((output_min + (voltage2 * bin_size / PAR_21)) * IV_gain2 / 2^ADC_gain2)
        voltage2 = FPAR_2 / IV_gain2
        DATA_3[voltagecounter]= FPAR_2
                          
        measureflag = 0

        voltagecounter = voltagecounter + 1
        
        ' reverse bias at current limit 
        IF (((FPAR_9 <> 0) AND (voltagecounter < PAR_23 / 4)) AND ((FPAR_1 > FPAR_9) OR (FPAR_2 > FPAR_9))) THEN
          FPAR_10 = 2
          FOR idx =  PAR_23 / 4 TO (PAR_23 / 2 + 1) STEP 1
            IF (DATA_1[idx] =  DATA_1[voltagecounter - 1]) THEN
              voltagecounter_new = idx 
            ENDIF
          NEXT idx
          
          FOR idx = voltagecounter TO voltagecounter_new
            DATA_2[idx] = 0
            DATA_3[idx] = 0
          NEXT idx
         
          voltagecounter = voltagecounter_new 
        ENDIF
                         
        IF (((FPAR_9 <> 0) AND ((FPAR_1 < -1*FPAR_9) OR (FPAR_2 < -1*FPAR_9) )) AND ((voltagecounter > PAR_23 / 2) AND (voltagecounter < 3 * PAR_23 / 4))) THEN
          FOR idx =  3 * PAR_23 / 4 TO PAR_23 STEP 1
            IF (DATA_1[idx] =  DATA_1[voltagecounter - 1]) THEN
              voltagecounter_new = idx 
            ENDIF
          NEXT idx
        
          FOR idx = voltagecounter TO voltagecounter_new
            DATA_2[idx] = 0
            DATA_3[idx] = 0
          NEXT idx
         
          voltagecounter = voltagecounter_new 
                          
        ENDIF
        
        IF (( abs(voltage1) > 8) AND (FPAR_27 > 4)) THEN
          FPAR_27 = FPAR_27 - 1
          measureflag = 3
          voltagecounter = voltagecounter - 1
        ENDIF 
              
        IF (( abs(voltage1) < 0.5) AND (FPAR_27 < upper_gain1)) THEN    
          FPAR_27 = FPAR_27 + 1
          measureflag = 3
          voltagecounter = voltagecounter - 1
        ENDIF
               
        IF (( abs(voltage2) > 8) AND (FPAR_28 > 4)) THEN
          FPAR_28 = FPAR_28 - 1
          measureflag = 3
          voltagecounter = voltagecounter - 1
        ENDIF 
              
        IF (( abs(voltage2) < 0.5) AND (FPAR_28 < upper_gain2)) THEN    
          FPAR_28 = FPAR_28 + 1
          measureflag = 3
          voltagecounter = voltagecounter - 1
        ENDIF
        
          
      ENDIF

      ' stop when reached end of vector
      IF (voltagecounter  = PAR_23 + 1) THEN   
        end  
      ENDIF
      
    CASE 3 ' set new gain and wait
        
      IF (FPAR_27 = 4) THEN
        IV1_bit0 = 0
        IV1_bit1 = 0
        IV1_bit2 = 0
        IV1_bit3 = 0
      ENDIF     
      IF (FPAR_27 = 5) THEN
        IV1_bit0 = 1
        IV1_bit1 = 0
        IV1_bit2 = 0
        IV1_bit3 = 0
      ENDIF     
      IF (FPAR_27 = 6) THEN
        IV1_bit0 = 0
        IV1_bit1 = 1
        IV1_bit2 = 0
        IV1_bit3 = 0
      ENDIF     
      IF (FPAR_27 = 7) THEN
        IV1_bit0 = 1
        IV1_bit1 = 1
        IV1_bit2 = 0
        IV1_bit3 = 0
      ENDIF     
      IF (FPAR_27 = 8) THEN
        IV1_bit0 = 0
        IV1_bit1 = 0
        IV1_bit2 = 1
        IV1_bit3 = 0
      ENDIF     
      IF (FPAR_27 = 9) THEN
        IV1_bit0 = 1
        IV1_bit1 = 0
        IV1_bit2 = 1
        IV1_bit3 = 0
      ENDIF
      IF (FPAR_27 = 10) THEN
        IV1_bit0 = 0
        IV1_bit1 = 1
        IV1_bit2 = 1
        IV1_bit3 = 0
      ENDIF
      IF (FPAR_27 = 11) THEN
        IV1_bit0 = 1
        IV1_bit1 = 1
        IV1_bit2 = 1
        IV1_bit3 = 0
      ENDIF
      IF (FPAR_27 = 12) THEN
        IV1_bit0 = 0
        IV1_bit1 = 0
        IV1_bit2 = 0
        IV1_bit3 = 1
      ENDIF
      IF (FPAR_27 = 13) THEN
        IV1_bit0 = 1
        IV1_bit1 = 0
        IV1_bit2 = 0
        IV1_bit3 = 1
      ENDIF      

      
  
      IF (FPAR_28 = 4) THEN
        IV2_bit0 = 0
        IV2_bit1 = 0
        IV2_bit2 = 0
        IV2_bit3 = 0
      ENDIF     
      IF (FPAR_28 = 5) THEN
        IV2_bit0 = 1
        IV2_bit1 = 0
        IV2_bit2 = 0
        IV2_bit3 = 0
      ENDIF     
      IF (FPAR_28 = 6) THEN
        IV2_bit0 = 0
        IV2_bit1 = 1
        IV2_bit2 = 0
        IV2_bit3 = 0
      ENDIF     
      IF (FPAR_28 = 7) THEN
        IV2_bit0 = 1
        IV2_bit1 = 1
        IV2_bit2 = 0
        IV2_bit3 = 0
      ENDIF     
      IF (FPAR_28 = 8) THEN
        IV2_bit0 = 0
        IV2_bit1 = 0
        IV2_bit2 = 1
        IV2_bit3 = 0
      ENDIF     
      IF (FPAR_28 = 9) THEN
        IV2_bit0 = 1
        IV2_bit1 = 0
        IV2_bit2 = 1
        IV2_bit3 = 0
      ENDIF
      IF (FPAR_28 = 10) THEN
        IV2_bit0 = 0
        IV2_bit1 = 1
        IV2_bit2 = 1
        IV2_bit3 = 0
      ENDIF
      IF (FPAR_28 = 11) THEN
        IV2_bit0 = 1
        IV2_bit1 = 1
        IV2_bit2 = 1
        IV2_bit3 = 0
      ENDIF
      IF (FPAR_28 = 12) THEN
        IV2_bit0 = 0
        IV2_bit1 = 0
        IV2_bit2 = 0
        IV2_bit3 = 1
      ENDIF
      IF (FPAR_28 = 13) THEN
        IV2_bit0 = 1
        IV2_bit1 = 0
        IV2_bit2 = 0
        IV2_bit3 = 1
      ENDIF  
               
      P2_Digout(PAR_7, 12, IV1_bit0)
      P2_Digout(PAR_7, 13, IV1_bit1)
      P2_Digout(PAR_7, 14, IV1_bit2)
      P2_Digout(PAR_7, 15, IV1_bit3)
        
      P2_Digout(PAR_7, 24, IV2_bit0)
      P2_Digout(PAR_7, 25, IV2_bit1)
      P2_Digout(PAR_7, 26, IV2_bit2)
      P2_Digout(PAR_7, 27, IV2_bit3)
      
      IV_gain1 = 10^(-1*FPAR_27)
      IV_gain2 = 10^(-1*FPAR_28)
        
      ' wait
      IF(waitcounter = PAR_26) THEN
        measureflag = 2
        waitcounter = 0
        avgcounter = 0
        voltage1 = 0
        voltage2 = 0               
      ELSE
        waitcounter = waitcounter + 1
      ENDIF
          
  ENDSELECT
  
FINISH:
  P2_Write_DAC(PAR_6, PAR_8, DATA_1[PAR_23])
  P2_Start_DAC(PAR_6)
