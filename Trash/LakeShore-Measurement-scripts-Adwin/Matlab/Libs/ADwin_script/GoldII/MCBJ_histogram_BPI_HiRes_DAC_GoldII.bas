'<ADbasic Header, Headerversion 001.001>
' Process_Number                 = 7
' Initial_Processdelay           = 3000
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

#Define current_av FPAR_1
#Define voltage_av FPAR_2
#Define IV_gain1 FPAR_3

#Define breakingcounter PAR_2 
#Define makingcounter PAR_3
#Define output_channel PAR_50
#Define N_avg PAR_54
#Define measureflag PAR_60
#Define mean_V PAR_61
#Define status PAR_62
#Define currentV PAR_63
#Define N_signal_length PAR_64
#Define postbreakingcounter PAR_70
#Define high_G_current PAR_50
#Define inter_G_current PAR_51
#Define low_G_current PAR_52


#Define wait_cycles_breaking1 PAR_55
#Define wait_cycles_breaking2 PAR_56
#Define wait_cycles_making PAR_57
#Define N_postbreaking PAR_58

#INCLUDE ADwinGoldII.inc


DIM DATA_2[1000000] as float     ' conductance breaking
DIM DATA_3[1000000] as float     ' conductance making
DIM DATA_4[1000000] as float     ' displacement breaking
DIM DATA_5[1000000] as float     ' displacement making

DIM DATA_6[100] as float     ' AO output pattern

DIM DATA_11[16] as long
DIM avgcounter,waitcounter,piezocounter,signalcounter,speedcounter, index_av as long
DIM output_min, output_max, bin_size, output_res as float
DIM Combi_gain1 as float
DIM ADC_gain1 as long
DIM bin1 as long
DIM totalcurrent1, average_displacement as float
DIM Gain_bin1, Gain_bin2, Gain_bin3 as long 

INIT:
  measureflag = 1 
  breakingcounter = 1
  makingcounter = 1
  status = 1
    
  avgcounter = 0
  waitcounter = 0
  totalcurrent1 = 0
  piezocounter = 0
  postbreakingcounter = 0
  signalcounter = 0
  speedcounter = 0
    
  'convert bin to V
  output_min = -10
  output_max = 9.99969
  output_res = PAR_10
  bin_size = (output_max-output_min) / (2^output_res)
     
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
          
             
''''''''''''''''''''''''''''''''''''
''''' acquire data '''''
''''''''''''''''''''''''''''''''''

  ' acquire data and set gain
  Gain_bin1 = Digin(0)
  Gain_bin2 = Digin(1)
  Gain_bin3 = Digin(2)
  bin1 = READ_ADC24(1)/64
  START_CONV(00011b)
 
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
          
  ' sum over bins for averaging
  totalcurrent1 = totalcurrent1 + bin1
  avgcounter = avgcounter + 1
              
  ' get average
  IF(avgcounter = N_avg) THEN
    current_av = (output_min + ((totalcurrent1 / N_avg) * bin_size)) * IV_gain1
    avgcounter = 0
    totalcurrent1 = 0
        
    ' get position, average over pattern
    average_displacement = 0
    For index_av = 1 To N_signal_length
      average_displacement = average_displacement + DATA_6[index_av]              'instruction block
    Next index_av 
    voltage_av = average_displacement / N_signal_length
    
    ' save data
    SELECTCASE measureflag ' set electrode speed
        'measurement: 1 = breaking ramp 1
        'measurement: 2 = breaking ramp 2
        'measurement: 3 = post breaking 
        'measurement: 4 = making ramp 1
              
      CASE 1,2,3 'breaking 
        DATA_2[breakingcounter]= current_av
        DATA_4[breakingcounter]= voltage_av 
              
        breakingcounter =  breakingcounter + 1   
              
      CASE 4 'making
        DATA_3[makingcounter] = current_av
        DATA_5[makingcounter] = voltage_av '''''''''''''''''''''''''''''''''''
                                      
        makingcounter = makingcounter + 1
    
    ENDSELECT
           
''''''''''''''''''''''''''''''''''''
''''' change actuator direction'''''
''''''''''''''''''''''''''''''''''
         
    ' define condition to change from breaking 1 -> breaking 2
    IF ((current_av <= inter_G_current) AND (measureflag = 1)) THEN 
      measureflag = 2 
    ENDIF
                
    ' define condition to change from breaking 2 -> postbreaking
    IF ((current_av <= low_G_current) AND (measureflag = 2)) THEN 
      measureflag = 3 
      postbreakingcounter = 0
    ENDIF
                
    ' define condition to change from post breaking -> making
    IF (measureflag = 3) THEN
      IF (postbreakingcounter >= N_postbreaking) THEN
        measureflag = 4
      ELSE
        postbreakingcounter = postbreakingcounter + 1
      ENDIF 
    ENDIF
              
    'define condition to change from making -> breaking 1
    IF ((current_av >= high_G_current) AND (measureflag = 4)) THEN 
      status = 2
      end
    ENDIF
     
  ENDIF
    
             
'''''''''''''''''''''''''''''''''''''''''''
''''' output actuator voltage pattern '''''
''''''''''''''''''''''''''''''''''''''''''

  ' output voltage repeating pattern on DAC        
  DAC(output_channel, DATA_6[signalcounter])

  signalcounter = signalcounter + 1
  IF (signalcounter = N_signal_length) THEN
    signalcounter = 1
  ENDIF
          
  ' adjust voltage pattern for matching speed
  SELECTCASE measureflag ' set electrode speed
      'measurement: 1 = breaking ramp 1
      'measurement: 2 = breaking ramp 2
      'measurement: 3 = post breaking 
      'measurement: 4 = making ramp 1
        
    CASE 1 'breaking 1
      
      piezocounter = piezocounter + 1
      
      IF(piezocounter >= wait_cycles_breaking1) THEN   ' counter for overal speed
        piezocounter = 0
        speedcounter = speedcounter + 1
        DATA_6[speedcounter] = DATA_6[speedcounter] + 1
        
        IF (speedcounter >= N_signal_length) THEN     ' counter for index in pattern to be adjusted
          speedcounter = 0
          mean_V = mean_V + 1
          
          IF (mean_V > 65536) THEN 'check if outside actuator range, cannot break
            status = 3
            end
          ENDIF
          
        ENDIF
        
      ENDIF
  
    CASE 2,3 'breaking 2 & postbreaking
      
      piezocounter = piezocounter + 1
      
      IF(piezocounter >= wait_cycles_breaking2) THEN   ' counter for overal speed
        piezocounter = 0
        speedcounter = speedcounter + 1
        DATA_6[speedcounter] = DATA_6[speedcounter] + 1
        
        IF (speedcounter >= N_signal_length) THEN     ' counter for index in pattern to be adjusted
          speedcounter = 0
          mean_V = mean_V + 1
          
          IF (mean_V > 65536) THEN 'check if outside actuator range, cannot break
            status = 3
            end
          ENDIF
        ENDIF
        
      ENDIF
              
    CASE 4 'making
                
      piezocounter = piezocounter + 1
            
      IF(piezocounter >= wait_cycles_making) THEN   ' counter for overal speed
        piezocounter = 0
        speedcounter = speedcounter + 1
        DATA_6[speedcounter] = DATA_6[speedcounter] - 1
              
        IF (speedcounter >= N_signal_length) THEN     ' counter for index in pattern to be adjusted
          speedcounter = 0
          mean_V = mean_V - 1
                
          IF (mean_V < 32768) THEN 'check if outside actuator range, cannot make
            status = 4
            end
          ENDIF
                
                
        ENDIF
              
      ENDIF
      

          
  ENDSELECT
  
FINISH:
  DAC(output_channel, mean_V)
