'<ADbasic Header, Headerversion 001.001>
' Process_Number                 = 2
' Initial_Processdelay           = 3000
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
Import Math.lic

'#INCLUDE C:\Users\lab405\Desktop\Lakeshore-ADwin-GoldII\Matlab\ADwin_script\Additional_functions.Inc

DIM DATA_1[50000] as long     'voltage input  
DIM DATA_10[8] as long       'ADC values  
DIM DATA_11[8] as long       'ADC gains
DIM DATA_2[50000] as float    'AI1
DIM DATA_3[50000] as float    'AI2
DIM DATA_4[50000] as float    'AI3
DIM DATA_5[50000] as float    'AI4
DIM DATA_6[50000] as float    'AI5
DIM DATA_7[50000] as float    'AI6
DIM DATA_8[50000] as float    'AI7
DIM DATA_9[50000] as float    'AI8

DIM totalcurrent1,totalcurrent2,totalcurrent3,totalcurrent4,totalcurrent5,totalcurrent6,totalcurrent7,totalcurrent8 as float
DIM avgcounter,timecounter as long
DIM modulo_index as long
DIM bin1,bin2,bin3,bin4,bin5,bin6,bin7,bin8 as long
DIM output_min, output_max, bin_size as float
DIM IV_gain1,IV_gain2,IV_gain3,IV_gain4,IV_gain5,IV_gain6,IV_gain7,IV_gain8 as float
DIM ADC_gain1,ADC_gain2,ADC_gain3,ADC_gain4,ADC_gain5,ADC_gain6,ADC_gain7,ADC_gain8 as long
DIM Combi_gain1,Combi_gain2,Combi_gain3,Combi_gain4,Combi_gain5,Combi_gain6,Combi_gain7,Combi_gain8 as float

INIT:
  avgcounter = 0
  timecounter = 1
  
  'convert bin to V
  output_min = -10
  output_max = 9.99969
  bin_size = (output_max-output_min) / (2^PAR_10)
      
  'set ADC gain
  P2_Set_gain(PAR_5, 1, DATA_11[1])
  P2_Set_gain(PAR_5, 2, DATA_11[2])
  P2_Set_gain(PAR_5, 3, DATA_11[3])
  P2_Set_gain(PAR_5, 4, DATA_11[4])
  P2_Set_gain(PAR_5, 5, DATA_11[5])
  P2_Set_gain(PAR_5, 6, DATA_11[6])
  P2_Set_gain(PAR_5, 7, DATA_11[7])
  P2_Set_gain(PAR_5, 8, DATA_11[8])
  
  ADC_gain1 = 2^DATA_11[1]
  ADC_gain2 = 2^DATA_11[2]
  ADC_gain3 = 2^DATA_11[3]
  ADC_gain4 = 2^DATA_11[4]
  ADC_gain5 = 2^DATA_11[5]
  ADC_gain6 = 2^DATA_11[6]
  ADC_gain7 = 2^DATA_11[7]
  ADC_gain8 = 2^DATA_11[8]
  
  'set IV gain 
  IV_gain1 = 10^(-1*FPAR_27)
  IV_gain2 = 10^(-1*FPAR_28)
  IV_gain3 = 10^(-1*FPAR_29)
  IV_gain4 = 10^(-1*FPAR_30)
  IV_gain5 = 10^(-1*FPAR_31)
  IV_gain6 = 10^(-1*FPAR_32)
  IV_gain7 = 10^(-1*FPAR_33)
  IV_gain8 = 10^(-1*FPAR_34)  
 
  ' get combined gain
  Combi_gain1 = IV_gain1 / ADC_gain1
  Combi_gain2 = IV_gain2 / ADC_gain2
  Combi_gain3 = IV_gain3 / ADC_gain3
  Combi_gain4 = IV_gain4 / ADC_gain4
  Combi_gain5 = IV_gain5 / ADC_gain5
  Combi_gain6 = IV_gain6 / ADC_gain6
  Combi_gain7 = IV_gain7 / ADC_gain7
  Combi_gain8 = IV_gain8 / ADC_gain8
  
EVENT:

  'P2_Wait_EOC(PAR_5)
  P2_Read_ADCF8_24B(PAR_5, DATA_10, 1)
  P2_Start_ConvF(PAR_5, 0000000011111111b) ' 0Fh = 000...0001111     
       
  bin1 = DATA_10[1] / 64
  bin2 = DATA_10[2] / 64
  bin3 = DATA_10[3] / 64
  bin4 = DATA_10[4] / 64
  bin5 = DATA_10[5] / 64
  bin6 = DATA_10[6] / 64
  bin7 = DATA_10[7] / 64
  bin8 = DATA_10[8] / 64
  
  FPAR_11 = Combi_gain1
  PAR_12 = bin1
  FPAR_13 = IV_gain1
  FPAR_14 = ADC_gain1
  FPAR_15 = IV_gain2
  FPAR_16 = ADC_gain2
  
  
  totalcurrent1 = totalcurrent1 + ((output_min + (bin1 * bin_size)) * Combi_gain1)
  totalcurrent2 = totalcurrent2 + ((output_min + (bin2 * bin_size)) * Combi_gain2)
  totalcurrent3 = totalcurrent3 + ((output_min + (bin3 * bin_size)) * Combi_gain3)
  totalcurrent4 = totalcurrent4 + ((output_min + (bin4 * bin_size)) * Combi_gain4)
  totalcurrent5 = totalcurrent5 + ((output_min + (bin5 * bin_size)) * Combi_gain5)
  totalcurrent6 = totalcurrent6 + ((output_min + (bin6 * bin_size)) * Combi_gain6)
  totalcurrent7 = totalcurrent7 + ((output_min + (bin7 * bin_size)) * Combi_gain7)
  totalcurrent8 = totalcurrent8 + ((output_min + (bin8 * bin_size)) * Combi_gain8)
      
  avgcounter = avgcounter + 1
          
  ' get averaging
  IF(avgcounter = PAR_21) THEN
    FPAR_1 = totalcurrent1 / PAR_21
    FPAR_2 = totalcurrent2 / PAR_21
    FPAR_3 = totalcurrent3 / PAR_21
    FPAR_4 = totalcurrent4 / PAR_21
    FPAR_5 = totalcurrent5 / PAR_21
    FPAR_6 = totalcurrent6 / PAR_21
    FPAR_7 = totalcurrent7 / PAR_21
    FPAR_8 = totalcurrent8 / PAR_21
                
    modulo_index = Mod(timecounter,PAR_26)
    IF (modulo_index = 0) THEN
      modulo_index = PAR_26
    ENDIF
        
    DATA_2[modulo_index]= FPAR_1
    DATA_3[modulo_index]= FPAR_2
    DATA_4[modulo_index]= FPAR_3
    DATA_5[modulo_index]= FPAR_4
    DATA_6[modulo_index]= FPAR_5
    DATA_7[modulo_index]= FPAR_6
    DATA_8[modulo_index]= FPAR_7
    DATA_9[modulo_index]= FPAR_8   
    
    PAR_19 = timecounter
    timecounter = timecounter + 1
        
    avgcounter = 0
    totalcurrent1 = 0
    totalcurrent2 = 0
    totalcurrent3 = 0
    totalcurrent4 = 0
    totalcurrent5 = 0
    totalcurrent6 = 0
    totalcurrent7 = 0
    totalcurrent8 = 0
  ENDIF

    
FINISH:

