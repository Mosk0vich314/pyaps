'<ADbasic Header, Headerversion 001.001>
' Process_Number                 = 6
' Initial_Processdelay           = 3000
' Eventsource                    = Timer
' Control_long_Delays_for_Stop   = No
' Priority                       = High
' Version                        = 1
' ADbasic_Version                = 6.2.0
' Optimize                       = Yes
' Optimize_Level                 = 1
' Stacksize                      = 1000
' Info_Last_Save                 = DDM05868  EMPA\scol
'<Header End>
' SquareSignal.bas: Generates increasing Square Signal, recording AI 1-4

'Inputs general:
'PAR_1 = Gain DAC 1
'PAR_2 = Gain DAC 2
'PAR_3 = Gain DAC 3
'PAR_4 = Gain DAC 4
'PAR_5 = Address AIN F4/18
'PAR_6 = Address AOUT 4/16
'PAR_7 = Address DIO-32
'PAR_8 = V output channel
'PAR_9 = output channel
'PAR_10 = ADC resolution
'PAR_26 = IV convert 1 autoranging 0 no, 1 lin, 2 log
'PAR_27 = IV convert 2 autoranging 0 no, 1 lin, 2 log
'PAR_28 = IV convert 3 autoranging 0 no, 1 lin, 2 log
'PAR_29 = IV convert 4 autoranging 0 no, 1 lin, 2 log

'Measurement parameters:
'FPAR_1 = actual AI2 value in bin
'FPAR_2 = actual AI3 value in bin
'FPAR_3 = actual AI4 value in bin
'FPAR_4 = actual AI5 value in bin

'Inputs:
'PAR_60 = current voltage
'PAR_61 = initial voltage point 
'PAR_62 = set voltage point 
'PAR_63 = initial high voltage point
'PAR_64 = set high voltage point
'PAR_65 = final voltage point
'PAR_66 = no of loops to wait before measurement
'PAR_67 = no of points to average over
'PAR_68 = timecounter
'PAR_69 = cyclecounter
'PAR_70 = voltage steps


'Outputs:
'DATA_2 = averaged AI1 bin array 
'DATA_3 = averaged AI2 bin array 
'DATA_4 = averaged AI3 bin array 
'DATA_5 = averaged AI4 bin array 
'DATA_6 = read ADC values

#INCLUDE ADwinGoldII.inc

DIM DATA_2[2000000] as float
DIM DATA_3[2000000] as float
DIM actual_V as long
DIM measureflag as long
DIM timecounter,cyclecounter,globalcounter,avgcounter as long
DIM bin1,bin2 as long
DIM output_min, output_max, bin_size as float
DIM totalvoltage1, totalvoltage2 as float
DIM totalcurrent1, totalcurrent2 as float
DIM IV_gain1,IV_gain2 as float


INIT:
   
  timecounter = 0
  cyclecounter = 0
  globalcounter = 1
  avgcounter = 0
  measureflag = 0
  totalvoltage1 = 0
  totalvoltage2 = 0
  totalcurrent1 = 0
  totalcurrent2 = 0
   
  actual_V = PAR_61
  
  PAR_60 = actual_V
  
  'convert bin to V
  output_min = -10
  output_max = 9.99969
  bin_size = (output_max-output_min) / (2^PAR_10)
  
  'ADC gains
  Set_Mux1(00000b) 'set MUX1
  Set_Mux2(00000b) 'set MUX2
  
  'set DAC to first value
  DAC(PAR_8, actual_V)
  
  
  START_CONV(11b)
  Wait_EOC(11b)
  
  IV_gain1 = 10^(-1*PAR_27)
  IV_gain2 = 10^(-1*PAR_28)

EVENT:
     
  selectcase measureflag 
            
    CASE 0 'output desired voltage on DAC LCL
      IF (actual_V = PAR_61) THEN
        DAC(PAR_8, actual_V)
        timecounter = timecounter + 1
        measureflag = 0
      ENDIF
      IF (timecounter = PAR_68) THEN
        actual_V = PAR_63
        timecounter = 0
        measureflag = 1
      ENDIF
            
    CASE 1 'output desired voltage on DAC LCH
      IF (actual_V = PAR_63) THEN
        DAC(PAR_8, actual_V)
        timecounter = timecounter + 1
        measureflag = 1
      ENDIF
      IF (timecounter = PAR_68) THEN
        actual_V = PAR_61
        Cyclecounter = Cyclecounter + 1
        timecounter = 0
        measureflag = 0
      ENDIF
      IF (Cyclecounter = PAR_69) THEN
        actual_V = PAR_62
        Cyclecounter = 0
        measureflag = 2
      ENDIF
      
    CASE 2 'output desired voltage on DAC HCL
      IF (actual_V = PAR_62) THEN
        DAC(PAR_8, actual_V)
        timecounter = timecounter + 1
        measureflag = 2
      ENDIF
      IF (timecounter = PAR_68) THEN
        timecounter = 0
        actual_V = PAR_64
        measureflag = 3
      ENDIF
    
    CASE 3 'output desired voltage on DAC HCH
      IF (actual_V = PAR_64) THEN
        DAC(PAR_8, actual_V)
        timecounter = timecounter + 1
        measureflag = 3
      ENDIF
      IF (timecounter = PAR_68) THEN
        actual_V = PAR_62
        Cyclecounter = Cyclecounter + 1
        timecounter = 0
        measureflag = 2
      ENDIF
      IF (Cyclecounter = PAR_69) THEN
        actual_V = PAR_61
        PAR_64 = PAR_64 + PAR_70
        Cyclecounter = 0
        measureflag = 0
      ENDIF
      IF (actual_V >= PAR_65) THEN 
        end
      ENDIF
  
  ENDSELECT
  
  
  WAIT_EOC(11b)
  bin1 = READ_ADC24(1)/64
  bin2 = READ_ADC24(2)/64
  START_CONV(11b)
        
  totalvoltage1 = (output_min + (bin1 * bin_size / 2^PAR_1))
  totalvoltage2 = (output_min + (bin2 * bin_size / 2^PAR_2))
  totalcurrent1 = (output_min + (bin1 * bin_size / 2^PAR_1)*IV_gain1)
  totalcurrent2 = (output_min + (bin2 * bin_size / 2^PAR_2)*IV_gain2)
  FPAR_1 = totalvoltage1
  FPAR_2 = totalvoltage2
  FPAR_3 = totalcurrent1
  FPAR_4 = totalcurrent2
  FPAR_5 = totalvoltage1/totalcurrent1
  DATA_2[globalcounter] = totalvoltage1
  DATA_3[globalcounter] = totalvoltage2
  DATA_4[globalcounter] = totalcurrent1
  DATA_5[globalcounter] = totalcurrent2
  PAR_71 = globalcounter       
  globalcounter = globalcounter + 1
  
  IF (

  
      
  
      
  
FINISH:
  DAC(PAR_8, PAR_62) 
