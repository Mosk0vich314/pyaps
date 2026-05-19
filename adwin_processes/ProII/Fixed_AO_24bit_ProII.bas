'<ADbasic Header, Headerversion 001.001>
' Process_Number                 = 4
' Initial_Processdelay           = 10000
' Eventsource                    = Timer
' Control_long_Delays_for_Stop   = No
' Priority                       = High
' Version                        = 1
' ADbasic_Version                = 6.3.1
' Optimize                       = Yes
' Optimize_Level                 = 1
' Stacksize                      = 1000
' Info_Last_Save                 = DDM07439  EMPA\lab405
'<Header End>
#INCLUDE ADwinPro_all.Inc

DIM Signal_length as long
DIM SignalIDX as long
DIM arrayNo as long
DIM measurementStage as long 
DIM actual_V as long
DIM DATA_5[100000] as long
DIM DATA_6[100000] as long

INIT:
  SignalIDX = 1
  Signal_length = PAR_31
  PAR_32 = 0
  PAR_33 = 0
  actual_V = PAR_41
  P2_Write_DAC(PAR_6, PAR_9, actual_V)
  P2_Start_DAC(PAR_9)
   
EVENT:
  
  SELECTCASE PAR_33 
      

    case 0
 
      IF(PAR_42 > actual_V) THEN INC(actual_V)      
      IF(PAR_42 < actual_V) THEN DEC(actual_V) 
      P2_Write_DAC(PAR_6, PAR_9, actual_V)
      P2_Start_DAC(PAR_6)
      PAR_40 = actual_V
      IF  (actual_V = PAR_42) THEN
        PAR_33 = 1
      ENDIF

    case 1
   
      IF (PAR_32 = 0) THEN
        P2_Write_DAC(PAR_6, PAR_9, DATA_5[SignalIDX])
        P2_Start_DAC(PAR_6)
        PAR_34 = 1
      ENDIF
      IF (PAR_32 = 1) THEN
        P2_Write_DAC(PAR_6, PAR_9, DATA_6[SignalIDX])
        P2_Start_DAC(PAR_6)
      ENDIF
      SignalIDX = SignalIDX + 1
      IF (SignalIDX = Signal_length) THEN
        SignalIDX = 1
      ENDIF 
           
  EndSelect
 
FINISH:
