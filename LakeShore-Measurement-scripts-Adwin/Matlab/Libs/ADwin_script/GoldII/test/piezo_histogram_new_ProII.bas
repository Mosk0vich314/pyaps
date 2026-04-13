'<ADbasic Header, Headerversion 001.001>
' Process_Number                 = 1
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
'piezo_histogram_18b.bas: measure single piezo-driven conductance trace. 

'Inputs general:
'PAR_1 = Gain DAC 1
'PAR_2 = Gain DAC 2
'PAR_3 = Gain DAC 3
'PAR_4 = Gain DAC 4
'PAR_5 = Address AIN F4/18
'PAR_6 = Address AOUT 4/16
'PAR_7 = Address DIO-32
'PAR_8 = IV output channel
'PAR_9 = fixed voltage output channel

'Inputs Gt:
'PAR_11 = initial voltage point
'PAR_12 = set voltage point
'PAR_13 = final voltage point
'PAR_15 = no of points to average over
'PAR_16 = no of loops to wait before measure

'PAR_26 = IV convert 1 autoranging 0 no, 1 lin, 2 log
'PAR_27 = IV convert 2 autoranging 0 no, 1 lin, 2 log
'PAR_28 = IV convert 3 autoranging 0 no, 1 lin, 2 log
'PAR_29 = IV convert 3 autoranging 0 no, 1 lin, 2 log

'Inputs:
'PAR_30 = case indicator      
'PAR_31 = array length breaking    
'PAR_32 = array length making      
'PAR_33 = wait cycles piezo breaking 1  
'PAR_34 = wait cycles piezo breaking 2  
'PAR_35 = wait cycles piezo making    
'PAR_36 = post breaking points to record 

'FPAR_30 = Target I change breaking speed 
'FPAR_31 = Target lower I      
'FPAR_32 = Target upper I       

'Outputs:
'DATA_2:5 = averaged current values array during breaking 
'DATA_7:10 = averaged current values array during making 

#INCLUDE ADwinPro_all.Inc
#INCLUDE C:\Users\lab405\Desktop\ARS_cryo-ADwin_ProII\Matlab\ADwin_script\Additional_functions.Inc

DIM DATA_2[100000] as float ' ADC1 breaking
DIM DATA_3[100000] as float ' ADC2 breaking
DIM DATA_4[100000] as float ' ADC3 breaking
DIM DATA_5[100000] as float ' ADC4 breaking
DIM DATA_6[4] as long
DIM DATA_7[100000] as float ' ADC1 making
DIM DATA_8[100000] as float ' ADC2 making
DIM DATA_9[100000] as float ' ADC3 making
DIM DATA_10[100000] as float ' ADC4 making

DIM waitflag as long
DIM actual_V as long
DIM breaking as long
DIM avgcounter, waitcounter, piezocounter, postbreakingcounter as long
DIM totalcurrent1, totalcurrent2, totalcurrent3, totalcurrent4 as float
DIM bin1, bin2, bin3, bin4 as long
DIM bit, IV1_bit0, IV1_bit1, IV1_bit2, IV2_bit0, IV2_bit1, IV2_bit2, IV3_bit0, IV3_bit1, IV3_bit2, IV4_bit0, IV4_bit1, IV4_bit2 as long

INIT:
  PAR_31 = 1                ' breaking time index
  PAR_32 = 1                ' making time index
  PAR_30 = 0               ' progress indicator
  
  avgcounter = 0
  waitcounter = 0
  waitflag = 0 
  breaking = 1
  
  totalcurrent1 = 0
  totalcurrent2 = 0
  totalcurrent3 = 0
  totalcurrent4 = 0
  
  piezocounter = 0
  postbreakingcounter = 0
  
  'ADC gains
  P2_Set_Gain(PAR_5, 1, PAR_1)
  P2_Set_Gain(PAR_5, 2, PAR_2)
  P2_Set_Gain(PAR_5, 3, PAR_3)
  P2_Set_Gain(PAR_5, 4, PAR_4)
  
  'set DAC to first value
  actual_V = PAR_11        
  P2_Write_DAC(PAR_6, PAR_8, actual_V)
  P2_Start_DAC(PAR_6)
  
  'set DIO input and outputs. 0-15 as inputs, 16-31 as outputs; 0=input, 1=output
  P2_DigProg(PAR_7, 1100b)
  
EVENT:

  SELECTCASE PAR_30 'measurement: 0 = ramp voltage
      'case 0 ramp up bias voltage
      'case 1 measure breaking
      'case 2 ramp down bias voltage
      
    CASE 0 'output desired voltage on DAC1
      IF(PAR_12 > actual_V) THEN INC(actual_V)      
      IF(PAR_12 < actual_V) THEN DEC(actual_V) 
      P2_Write_DAC(PAR_6, PAR_8, actual_V)
      P2_Start_DAC(PAR_6)
      IF  (actual_V = PAR_12) THEN PAR_30 = 1 
      
    CASE 1 'record during breaking 1
      
      SELECTCASE waitflag '0=wait, 1=measure
        
        CASE 0 
          IF(waitcounter = PAR_16) THEN
            waitflag = 1
            waitcounter = 0
            avgcounter = 0
          ELSE
            waitcounter = waitcounter + 1
          ENDIF
        
        CASE 1
          'P2_Wait_EOCF(PAR_5, 0Fh)   ' 0Fh = 000...0001111
          P2_Read_ADCF4_24B(PAR_5, DATA_6, 1)
          P2_Start_ConvF(PAR_5, 0Fh) ' 0Fh = 000...0001111
      
          IF ( ((PAR_26 = 1) OR (PAR_27 = 1)) OR ((PAR_28 = 1) OR (PAR_29 = 1)) ) THEN
            bit = P2_Digin_Long(PAR_7)           ' get IV gains
            IV1_bit0 = get_bit(0, bit)
            IV1_bit1 = get_bit(1, bit)
            IV1_bit2 = get_bit(2, bit)
            IV2_bit0 = get_bit(3, bit)
            IV2_bit1 = get_bit(4, bit)
            IV2_bit2 = get_bit(5, bit)
            IV3_bit0 = get_bit(6, bit)
            IV3_bit1 = get_bit(7, bit)
            IV3_bit2 = get_bit(8, bit)
            IV4_bit0 = get_bit(9, bit)
            IV4_bit1 = get_bit(10, bit)
            IV4_bit2 = get_bit(11, bit)
          ELSE
            IV1_bit0 = 0
            IV1_bit1 = 0
            IV1_bit2 = 0
            IV2_bit0 = 0
            IV2_bit1 = 0
            IV2_bit2 = 0
            IV3_bit0 = 0
            IV3_bit1 = 0
            IV3_bit2 = 0
            IV4_bit0 = 0
            IV4_bit1 = 0
            IV4_bit2 = 0
          ENDIF
      
          bin1 = DATA_6[1]/64
          bin2 = DATA_6[2]/64
          bin3 = DATA_6[3]/64
          bin4 = DATA_6[4]/64
      
          totalcurrent1 = totalcurrent1 + convert_bin_to_current(bin1, PAR_26, IV1_bit2, IV1_bit1, IV1_bit0, PAR_1)
          totalcurrent2 = totalcurrent2 + convert_bin_to_current(bin2, PAR_27, IV2_bit2, IV2_bit1, IV2_bit0, PAR_2)
          totalcurrent3 = totalcurrent3 + convert_bin_to_current(bin3, PAR_28, IV3_bit2, IV3_bit1, IV3_bit0, PAR_3)
          totalcurrent4 = totalcurrent4 + convert_bin_to_current(bin4, PAR_29, IV4_bit2, IV4_bit1, IV4_bit0, PAR_4)
          
          avgcounter = avgcounter + 1
          
          IF(avgcounter = PAR_15) THEN
            avgcounter = 0
            waitflag = 0
            
            FPAR_1 = totalcurrent1 / PAR_15
            FPAR_2 = totalcurrent2 / PAR_15
            FPAR_3 = totalcurrent3 / PAR_15
            FPAR_4 = totalcurrent4 / PAR_15
            totalcurrent1 = 0
            totalcurrent2 = 0
            totalcurrent3 = 0
            totalcurrent4 = 0
            
            IF (breaking = 1) THEN
              DATA_2[PAR_31]= FPAR_1
              DATA_3[PAR_31]= FPAR_2  
              DATA_4[PAR_31]= FPAR_3
              DATA_5[PAR_31]= FPAR_4     
              PAR_31 = PAR_31 + 1
            ELSE
              DATA_7[PAR_32]= FPAR_1
              DATA_8[PAR_32]= FPAR_2  
              DATA_9[PAR_32]= FPAR_3
              DATA_10[PAR_32]= FPAR_4     
              PAR_32 = PAR_32 + 1
            ENDIF
            
            IF(FPAR_1 <= FPAR_30) THEN  breaking = 0
            IF(FPAR_1 <= FPAR_30) THEN  PAR_30 = 2 
            
            
          ENDIF
          
      ENDSELECT
          
      
    CASE 2 'ramp down voltage
      IF(PAR_13 > actual_V) THEN INC(actual_V)      
      IF(PAR_13 < actual_V) THEN DEC(actual_V) 
      P2_Write_DAC(PAR_6, PAR_8, actual_V)
      P2_Start_DAC(PAR_6)
      IF  (actual_V = PAR_13) THEN end
      
  ENDSELECT
  
FINISH:
  P2_Write_DAC(PAR_6, PAR_8, PAR_13)
  P2_Start_DAC(PAR_6)
