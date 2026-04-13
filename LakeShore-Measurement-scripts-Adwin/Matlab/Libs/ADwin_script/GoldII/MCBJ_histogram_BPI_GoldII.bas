'<ADbasic Header, Headerversion 001.001>
' Process_Number                 = 7
' Initial_Processdelay           = 1000
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
' AO1_MUX12_ramp_n_read.bas: ramps voltage on AO1, recording voltage on MUX1 and MUX2.

'Inputs:

'PAR_50 = piezo output channel
'PAR_51 = current V
'PAR_52 = array length breaking
'PAR_53 = array length making

'FPAR_50 = Target upper I 
'FPAR_51 = Target I change breaking speed 
'FPAR_52 = Target lower I

'PAR_54 = no of points to average over
'PAR_55 = wait cycles piezo breaking 1
'PAR_56 = wait cycles piezo breaking 2
'PAR_57 = wait cycles piezo making
'PAR_58 = post breaking points to record
'PAR_59 = no of loops to wait before measure
'PAR_60 = measurement flag
'PAR_61 = start bin for piezo voltage

'Outputs:
'FPAR_1 = actual MUX1 value
'PAR_2 = array length breaking
'PAR_3 = array length making
'DATA_2 = averaged MUX1 current values array during breaking (maximum length 1048576, so 4 arrays can be handled in parallel)
'DATA_3 = averaged MUX1 current values array during making (maximum length 1048576, so 4 arrays can be handled in parallel)
'PAR_4 = process status : 0 =  stopped;  1 =  running ; 2 = stopped ; 3 = crashed during breaking ; 4 = crashed during making
'PAR_62 = measurement status. 0: start for the first time, 1: running correctly, 2: finished, 3: Measurements crashed when breaking, 4: Measurements crashed when making
'PAR_63 = current piezo voltage in bins

#INCLUDE ADwinGoldII.inc

DIM measureflag, error as long
DIM DATA_2[10000000] as float     ' conductance breaking
DIM DATA_3[10000000] as float     ' conductance making
DIM DATA_4[10000000] as float     ' displacement breaking
DIM DATA_5[10000000] as float     ' displacement making
DIM DATA_11[16] as long
DIM currentV as long
DIM avgcounter,waitcounter,piezocounter,postbreakingcounter,breakingcounter,makingcounter as long
DIM output_min, output_max, bin_size as float
DIM IV_gain1, Combi_gain1 as float
DIM ADC_gain1 as long
DIM bin1 as long
DIM totalcurrent1 as float
DIM Gain_bin1, Gain_bin2, Gain_bin3 as long 

INIT:
  measureflag = 1 
  breakingcounter = 1
  makingcounter = 1
  error = 1
  currentV = PAR_61
    
  avgcounter = 0
  waitcounter = 0
  totalcurrent1 = 0
  piezocounter = 0
  postbreakingcounter = 0

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
      
  ' start first conversion
  START_CONV(11b)
  WAIT_EOC(11b)
  
  Conf_DIO(0000b)
  
EVENT:

  PAR_2 = breakingcounter
  PAR_3 = makingcounter
  PAR_60 = measureflag
  PAR_63 = currentV
      
  Gain_bin1 = Digin(0)
  Gain_bin2 = Digin(1)
  Gain_bin3 = Digin(2)
  bin1 = READ_ADC24(1)/64
  START_CONV(00011b)
  '      WAIT_EOC(00011b)

  IF (((Gain_bin1 = 1) AND (Gain_bin2 = 1)) AND (Gain_bin3 = 1)) THEN
    IV_gain1 = 1e-5 / 2^ADC_gain1
  ENDIF
  IF (((Gain_bin1 = 0) AND (Gain_bin2 = 1)) AND (Gain_bin3 = 1)) THEN
    IV_gain1 = 1e-6 / 2^ADC_gain1
  ENDIF
  IF (((Gain_bin1 = 1) AND (Gain_bin2 = 0)) AND (Gain_bin3 = 1)) THEN
    IV_gain1 = 1e-7 / 2^ADC_gain1
  ENDIF
  IF (((Gain_bin1 = 0) AND (Gain_bin2 = 0)) AND (Gain_bin3 = 1)) THEN
    IV_gain1 = 1e-8 / 2^ADC_gain1
  ENDIF
  IF (((Gain_bin1 = 1) AND (Gain_bin2 = 1)) AND (Gain_bin3 = 0)) THEN
    IV_gain1 = 1e-9 / 2^ADC_gain1
  ENDIF
      
  totalcurrent1 = totalcurrent1 + bin1
  avgcounter = avgcounter + 1
          
  ' get average
  IF(avgcounter = PAR_54) THEN
    FPAR_1 = ((output_min + (totalcurrent1 / PAR_54 * bin_size)) * IV_gain1)
    avgcounter = 0
    totalcurrent1 = 0
    
    ' save data
    IF (measureflag = 4 ) THEN
      DATA_3[makingcounter] = FPAR_1
      DATA_5[makingcounter] = currentV
          
      makingcounter = makingcounter + 1
    ELSE
      DATA_2[breakingcounter]= FPAR_1
      DATA_4[breakingcounter]= currentV
          
      breakingcounter =  breakingcounter + 1
    ENDIF
        
    ' define condition to change from breaking 1 -> breaking 2
    IF ((FPAR_1 <= FPAR_51) AND (measureflag = 1)) THEN 
      measureflag = 2 
    ENDIF
        
    ' define condition to change from breaking 2 -> postbreaking
    IF ((FPAR_1 <= FPAR_52) AND (measureflag = 2)) THEN 
      measureflag = 3 
      postbreakingcounter = 0
    ENDIF
        
    ' define condition to change from post breaking -> making
    IF (measureflag = 3) THEN
      IF (postbreakingcounter >= PAR_58) THEN
        measureflag = 4
        'end
      ELSE
        postbreakingcounter = postbreakingcounter + 1
        PAR_70 = postbreakingcounter
      ENDIF 
    ENDIF
      
    'define condition to change from making -> breaking 1
    IF ((FPAR_1 >= FPAR_50) AND (measureflag = 4)) THEN 
      error = 2
      end
    ENDIF
 
  ENDIF
          
        
  SELECTCASE measureflag ' set electrode speed
      'measurement: 1 = breaking ramp 1
      'measurement: 2 = breaking ramp 2
      'measurement: 3 = post breaking 
      'measurement: 4 = making ramp 1
      
    CASE 1 'breaking 1
     
      IF(piezocounter >= PAR_55) THEN   
        inc(currentV)
        
        IF (currentV > 65536) THEN 'check if outside piezo range
          error = 3
          currentV = 65536
          end
        ENDIF
        
        DAC(PAR_50,currentV)
        piezocounter = 0
      ELSE
        piezocounter = piezocounter + 1
      ENDIF

    CASE 2,3 'breaking 2 & postbreaking
      IF(piezocounter >= PAR_56) THEN   
        inc(currentV)
        IF (currentV > 65536) THEN 'check if outside piezo range
          error = 3
          currentV = 65536
          end
        ENDIF
        
        DAC(PAR_50,currentV)
        piezocounter = 0
        
      ELSE
        piezocounter = piezocounter + 1
      ENDIF
      
    CASE 4 'making
        
      IF(piezocounter >= PAR_57) THEN   
        dec(currentV)
                    
        IF (currentV <= 32768) THEN 'check if outside piezo range
          error = 4
          currentV = 32768
          end
        ENDIF
                    
        DAC(PAR_50,currentV)
        piezocounter = 0           
      ELSE
        piezocounter = piezocounter + 1
      ENDIF 
        
  ENDSELECT
  
FINISH:
  PAR_62 = error
  PAR_61 = currentV
  
