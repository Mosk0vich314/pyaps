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
'PAR_70 = voltage steps

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
  
      
  
      
  
FINISH:
  DAC(PAR_8, PAR_62) 
