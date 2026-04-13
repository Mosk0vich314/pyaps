'<ADbasic Header, Headerversion 001.001>
' Process_Number                 = 6
' Initial_Processdelay           = 1000
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
' SquareSignal.bas: Generates increasing Square Signal 

'Inputs general:
'PAR_5 = Address AIN F4/18
'PAR_6 = Address AOUT 4/16
'PAR_7 = Address DIO-32
'PAR_8 = output channel

'Inputs:
'PAR_60 = current voltage
'PAR_61 = initial voltage point 
'PAR_62 = set voltage point 
'PAR_63 = initial high voltage point
'PAR_64 = set high voltage point
'PAR_65 = final voltage point
'PAR_68 = timecounter
'PAR_69 = cyclecounter

#INCLUDE ADwinGoldII.inc

DIM actual_V as long
DIM measureflag as long
DIM timecounter, cyclecounter, waitcounter as long

INIT:
   
  timecounter = 0
  cyclecounter = 0
  waitcounter = 0
  measureflag = 0
  actual_V = PAR_61
  PAR_60 = actual_V
  'set DAC to first value
  DAC(PAR_8, actual_V)

   
EVENT:
  selectcase measureflag 
    
    CASE 0 'Goto desired output voltage on DAC LCL
      IF(PAR_61 > actual_V) THEN INC(actual_V)      
      IF(PAR_61 < actual_V) THEN DEC(actual_V) 
      measureflag = 1
      
    CASE 1 'output desired voltage on DAC LCL
      IF (actual_V = PAR_61) THEN
        DAC(PAR_8, actual_V)
        timecounter = timecounter + 1
        measureflag = 1
      ELSE
        measureflag = 0
      ENDIF
      IF (timecounter = PAR_68) THEN
        timecounter = 0
        measureflag = 2
      ENDIF
      
    CASE 2 'Goto desired output voltage on DAC LCH
      IF(PAR_63 > actual_V) THEN INC(actual_V)      
      IF(PAR_63 < actual_V) THEN DEC(actual_V) 
      measureflag = 3
      
    CASE 3 'output desired voltage on DAC LCH
      IF (actual_V = PAR_63) THEN
        DAC(PAR_8, actual_V)
        timecounter = timecounter + 1
        measureflag = 3
      ELSE
        measureflag = 2
      ENDIF
      IF (timecounter = PAR_68) THEN
        Cyclecounter = Cyclecounter + 1
        timecounter = 0
        measureflag = 0
      ENDIF
      IF (Cyclecounter = PAR_69) THEN
        Cyclecounter = 0
        measureflag = 4
      ENDIF
      
    CASE 4 'Goto desired output voltage on DAC HCL
      IF(PAR_62 > actual_V) THEN INC(actual_V)      
      IF(PAR_62 < actual_V) THEN DEC(actual_V) 
      measureflag = 5
      
    CASE 5 'output desired voltage on DAC HCL
      IF (actual_V = PAR_62) THEN
        DAC(PAR_8, actual_V)
        timecounter = timecounter + 1
        measureflag = 5
      ELSE
        measureflag = 4
      ENDIF
      IF (timecounter = PAR_68) THEN
        timecounter = 0
        measureflag = 6
      ENDIF
      
    CASE 6 'Goto desired output voltage on DAC HCH
      IF(PAR_64 > actual_V) THEN INC(actual_V)      
      IF(PAR_64 < actual_V) THEN DEC(actual_V) 
      measureflag = 7
      
    CASE 7 'output desired voltage on DAC HCH
      IF (actual_V = PAR_64) THEN
        DAC(PAR_8, actual_V)
        timecounter = timecounter + 1
        measureflag = 7
      ELSE
        measureflag = 6
      ENDIF
      IF (timecounter = PAR_68) THEN
        Cyclecounter = Cyclecounter + 1
        timecounter = 0
        measureflag = 4
      ENDIF
      IF (Cyclecounter = PAR_69) THEN
        PAR_64 = PAR_64 + 1
        Cyclecounter = 0
        measureflag = 0
      ENDIF
      IF (actual_V = PAR_65) THEN 
        end
      ENDIF
  
  ENDSELECT
  
      
  
      
  
FINISH:
  DAC(PAR_8, PAR_62) 
