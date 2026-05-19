##### GENERAL #######
    
def ADwin_record_IV(Voltage, process_delay, loops_waiting, points_av, log, lin_gain, log_conversion):
    # record I(V) using ADwin 
    
    ## INITIALIZE ##
    V_bin, Voltage = convert_V_to_bin(Voltage,output_range,resolution_output)
    NumBias = len(V_bin)
    #ADwin_set_data_long(1,convert_to_list(zeros((10000))+32768))                 # send array of empty voltages    
    ADwin_set_data_long(1,convert_to_list(V_bin))                 # send arrays of the voltages
    ADwin_set_data_float(10,log_conversion)                 # send arrays of the voltages
    ADwin_set_processdelay(1,int(process_delay)) # set process delay
    ADwin_set_Par(55,int(points_av))             # set points to average
    ADwin_set_Par(56,int(loops_waiting))         # set settling time
    ADwin_set_Par(57,int(len(Voltage)))          # array length
    ADwin_set_Par(59,int(1))                    # process is still running
    
    ## RUN PROCESS ##
    ADwin_start_process(1)             
    check = True
    while check:
        if (ADwin_get_Par(59) == 1):
            sleep(1 / refresh_rate)
            pause(0.001)
            
        else:
            ADwin_stop_process(1)
            check = False  
    
    ## GET DATA ##
    Current1 = ADwin_get_data_float(4,NumBias)     # get averaged MUX1 current values
    #Current2 = ADwin_get_data_float(5,NumBias)     # get averaged MUX2 current values
    #bin1 = ADwin_get_data_float(2,NumBias)     # get averaged MUX1 bin values
    bin2 = ADwin_get_data_float(3,NumBias)     # get averaged MUX2 bin values
    
    #if log == False:
    #Current1 = convert_bin_to_V(bin1, input_range, resolution_input) / lin_gain
    Current2 = convert_bin_to_V(bin2, input_range, resolution_input) / lin_gain   
        
                
    #return array(bin1), array(bin2)    
    return array(Current1), array(Current2)         
    
       
def ADwin_record_Gt(start_V, set_V, end_V, Gt_time, process_delay, points_av, loops_waiting, time_per_point, log, lin_gain, log_conversion, V_per_V):
    # record G(t) using ADwin 

    ## Intialize
    start_V_bin, start_V = convert_V_to_bin(start_V / V_per_V,output_range,resolution_output)
    set_V_bin, set_V = convert_V_to_bin(set_V / V_per_V,output_range,resolution_output)
    end_V_bin, end_V = convert_V_to_bin(end_V / V_per_V,output_range,resolution_output)
    
    total_points =  int( Gt_time / time_per_point)              # get Gt total number of points  
      
    ADwin_set_processdelay(2,int(process_delay))     # set process delay
    ADwin_set_data_float(10,log_conversion) # set log conversion table
    ADwin_set_Par(7,int(start_V_bin))                # set start voltage
    ADwin_set_Par(8,int(set_V_bin))                  # set set voltage
    ADwin_set_Par(9,int(end_V_bin))                  # set end voltage
    ADwin_set_Par(10,int(total_points))              # set total run time
    ADwin_set_Par(55,int(points_av))                 # set points to average
    ADwin_set_Par(56,int(loops_waiting))             # set settling time
    ADwin_set_Par(59,1)                              # 1 =  process is running; 2 = process is finished

    ## RUN PROCESS ##
    ADwin_start_process(2)   
    #ms_start = time.time()
    sleep(0.01)
                 
    check = True
    while check:
        if (ADwin_get_Par(59) == 1):
            sleep(1 / refresh_rate)
            t = int(ADwin_get_Par(11))
            Current1 = ADwin_get_FPar(14)
            bin1 = int(ADwin_get_Par(12))
            
            #print "Time = %2.2f s %1.2e" % (t * time_per_point , Current1/set_V)
        else:
            ADwin_stop_process(2)
            #ms_end = time.time()
            check = False  

    #print "Elapsed Time  = %2.5fs" % (ms_end-ms_start)

    ## GET DATA ##
    t = int(ADwin_get_Par(11))-1
    Current1 = ADwin_get_data_float(4,t)     # get averaged MUX1 current values
    Current2 = ADwin_get_data_float(5,t)     # get averaged MUX1 current values
    
    
    if log == False:
        bin1 = ADwin_get_data_long(2,t)     # get averaged MUX1 bin values
        bin2 = ADwin_get_data_long(3,t)     # get averaged MUX1 bin values
        Current1 = convert_bin_to_V(bin1, input_range, resolution_input) / lin_gain  
        Current2 = convert_bin_to_V(bin2, input_range, resolution_input) / lin_gain  
    
    Time = range(0,t)
           
    return Time, Current1 / (set_V * V_per_V), Current2 / (set_V * V_per_V)
    
    
def ADwin_apply_gate(start_Vg, set_Vg, process_delay_gate, loops_waiting_gate):
    # apply gate voltage on AO2 of ADwin 

    ## Intialize
    start_Vg_bin, start_Vg = convert_V_to_bin(start_Vg,output_range,resolution_output)
    set_Vg_bin, set_Vg = convert_V_to_bin(set_Vg,output_range,resolution_output)
   
    ADwin_set_processdelay(5,int(process_delay_gate))  # set process delay
    ADwin_set_Par(31,int(start_Vg_bin))                # set gate start voltage
    ADwin_set_Par(32,int(set_Vg_bin))                  # set gate voltage
    ADwin_set_Par(34,int(loops_waiting_gate))          # set gate settling time
    ADwin_set_Par(39,1)                                # 1 =  process is running; 2 = process is finished
    ADwin_set_Par(77,int(AO_gate))                     # set gate AO                           
   
    ## RUN PROCESS ##
    ADwin_start_process(5)
    
    while ADwin_get_Par(39) == 1:
        sleep(1 / refresh_rate)
        pause(0.001)        
        
    ADwin_stop_process(5)
    
    return            
    
def ADwin_apply_switch(start_Vs, set_Vs, process_delay_switch):
    # apply gate voltage on AO2 of ADwin 

    ## Intialize
    start_Vs_bin, start_Vs = convert_V_to_bin(start_Vs,output_range,resolution_output)
    set_Vs_bin, set_Vs = convert_V_to_bin(set_Vs,output_range,resolution_output)

    ADwin_set_processdelay(6,int(process_delay_switch))  # set process delay
    ADwin_set_Par(41,int(start_Vs_bin))                # set gate start voltage
    ADwin_set_Par(42,int(set_Vs_bin))                  # set gate voltage
    ADwin_set_Par(48,int(0))                           # set total run time
    ADwin_set_Par(49,1)                                # 1 =  process is running; 2 = process is finished
    ADwin_set_Par(79,int(AO_switch))                     # set switch AO                               
    
    ## RUN PROCESS ##
    ## RUN PROCESS ##
    ADwin_start_process(6)
    
    while ADwin_get_Par(49) == 1:
        sleep(0.001)        
    
    ADwin_stop_process(6)

    
    return         

def ADwin_apply_switch_M1b(gain):
    if gain == 1.0e6:
        bit1 = 0        
        bit2 = 0        
    if gain == 1.0e7:
        bit1 = 1        
        bit2 = 0        
    if gain == 1.0e8:
        bit1 = 0        
        bit2 = 1        
    if gain == 1.0e9:
        bit1 = 1        
        bit2 = 1        
        
    # set bits 
    ADwin_set_Par(60,int(bit1))                # set gate start voltage
    ADwin_set_Par(61,int(bit2))                # set gate start voltage
    ADwin_set_Par(62,1)                                # 1 =  process is running; 2 = process is finished

    ## RUN PROCESS ##
    ADwin_start_process(10)
    
    while ADwin_get_Par(62) == 1:
        sleep(0.001)        
    
    ADwin_stop_process(10)
    print "linear gain set to %1.0e"%gain
    
    return               
    
def ADwin_ramp_piezo(set_Vs, process_delay_switch):
    # apply gate voltage on AO2 of ADwin 

    ## Intialize
    set_Vs = set_Vs / 100
    set_Vs_bin, set_Vs = convert_V_to_bin(set_Vs,output_range,resolution_output)

    ADwin_set_processdelay(7,int(process_delay_switch))  # set process delay
    ADwin_set_Par(59,1)                                # 1 =  process is running; 2 = process is finished
    ADwin_set_Par(78,int(AO_piezo))                     # set switch AO                               
    ADwin_set_Par(10,int(set_Vs_bin))                     # set piezo bin                         

    ## RUN PROCESS ##
    ADwin_start_process(7)
    
    while ADwin_get_Par(59) == 1:
        sleep(0.01)        
    
    ADwin_stop_process(7)

    
    return    


def ADwin_record_IVg(start_V, set_V, end_V, Vg, process_delay, loops_waiting, points_av, log, lin_gain, log_conversion):
    # record I(V) using ADwin 
    
    ## INITIALIZE ##
    start_V_bin, start_V = convert_V_to_bin(start_V / V_per_V,output_range,resolution_output)
    set_V_bin, set_V = convert_V_to_bin(set_V / V_per_V,output_range,resolution_output)
    end_V_bin, end_V = convert_V_to_bin(end_V / V_per_V,output_range,resolution_output)
    Vg_bin, Vg = convert_V_to_bin(Vg,output_range,resolution_output)

    NumG = len(Vg_bin)
    #ADwin_set_data_long(1,convert_to_list(zeros((10000))+32768))                 # send array of empty voltages    
    ADwin_set_data_long(1,convert_to_list(Vg_bin))                 # send arrays of the voltages
    ADwin_set_data_float(10,log_conversion)                 # send arrays of the voltages
    
    ADwin_set_processdelay(8,int(process_delay)) # set process delay
    
    ADwin_set_Par(7,int(start_V_bin))                # set start voltage
    ADwin_set_Par(8,int(set_V_bin))                  # set set voltage
    ADwin_set_Par(9,int(end_V_bin))                  # set end voltage
     
    ADwin_set_Par(45,int(points_av))             # set points to average
    ADwin_set_Par(46,int(loops_waiting))         # set settling time
    ADwin_set_Par(47,int(NumG))          # array length
    ADwin_set_Par(59,int(1))                    # process is still running
    

    ## RUN PROCESS ##
    ADwin_start_process(8)             
    check = True
    while check:
        if (ADwin_get_Par(59) == 1):
            sleep(1 / refresh_rate)
            pause(0.001)
            
        else:
            ADwin_stop_process(8)
            check = False  
    
    ## GET DATA ##
    Current1 = ADwin_get_data_float(8,NumG)     # get averaged MUX1 current values
    #Current2 = ADwin_get_data_float(5,NumG)     # get averaged MUX2 current values
    #bin1 = ADwin_get_data_float(2,NumG)     # get averaged MUX1 bin values
    bin2 = ADwin_get_data_float(7,NumG)     # get averaged MUX2 bin values
    
    #if log == False:
    #Current1 = convert_bin_to_V(bin1, input_range, resolution_input) / lin_gain
    Current2 = convert_bin_to_V(bin2, input_range, resolution_input) / lin_gain   
        
                
    #return array(bin1), array(bin2)    
    return array(Current1), array(Current2)      
    
    
def ADwin_record_CV(Vg, process_delay, loops_waiting, points_av, lin_gain_CV):
    # record I(V) using ADwin 
    
    ## INITIALIZE ##
    Vg_bin, Vg = convert_V_to_bin(Vg,output_range,resolution_output)

    NumG = len(Vg_bin)
    #ADwin_set_data_long(1,convert_to_list(zeros((10000))+32768))                 # send array of empty voltages    
    ADwin_set_data_long(1,convert_to_list(Vg_bin))                 # send arrays of the voltages
    
    ADwin_set_processdelay(3,int(process_delay)) # set process delay
      
    ADwin_set_Par(45,int(points_av))             # set points to average
    ADwin_set_Par(46,int(loops_waiting))         # set settling time
    ADwin_set_Par(47,int(NumG))          # array length
    ADwin_set_Par(59,int(1))                    # process is still running
    

    ## RUN PROCESS ##
    ADwin_start_process(3)             
    check = True
    while check:
        if (ADwin_get_Par(59) == 1):
            sleep(1 / refresh_rate)
            pause(0.001)
            
        else:
            ADwin_stop_process(3)
            check = False  
    
    ## GET DATA ##
    bin1 = ADwin_get_data_float(6,NumG)     # get averaged MUX1 bin values
    bin2 = ADwin_get_data_float(7,NumG)     # get averaged MUX2 bin values
      
    return array(bin1), array(bin2)      