#### CLEAR ALL #####
import os
os.chdir('D:/Mickael/Final16-18')
os.system( 'cls')

##### INITIALIZE MEASUREMENTS #####
motor = False
execfile('Libs/Boot.py')
save_dir = 'D:/pperrin/Data/DPEdT-2F_gate7/1-5-7-9/'
closefigs()

##### MEASUREMENT SETTINGS #####
V_per_V = 1.0          # V/V
save = False
log = True

lin_gain = 1.0e9   

Gt_time_init = 6000.0              # s

#####  IV SETTINGS #####
points_av_IV = 2000.0          # 
settling_time_IV = 10.0      # ms 
scanrate_IV = 100000.0      # Hz 
integration_time= 0.0   # ms

maxV_tunnel = 0.3                               # V                                       # 1 = log scale ; 0 = linear scale
bins_to_skip = 10.0                                  # volage resolution linear votlage range 0.3mV per bin
transition_G = 0.01                                 # G0
V_fit = 0.02                                        # V

##### G(t) SETTTINGS #####
points_av_Gt = 2000.0          # 
settling_time_Gt = 20.0      # ms (norm 20, fine 50)
scanrate_Gt = 100000.0      # Hz 

start_V = 0.0 ;         # V
set_V = 0.1;           # V
end_V = 0.0 ;           # V
Gt_time= 0.3              # s


##### GATE SETTINGS ######
Vg_min = -1.0                          # V
Vg_max = 1.0                          # V
Vg_N = 1                          # V
gate_V = linspace(Vg_min,Vg_max,Vg_N)             # V
settling_time_gate = 5.0        # ms
scanrate_gate = 10000.0             # Hz 
start_Vg = 0.0   
Vg_per_V = 4.0

##### initialize
loops_av_IV, process_delay_IV, loops_waiting_IV = get_delays(scanrate_IV,integration_time,settling_time_IV,clockfrequency)  # get_delays 
loops_av_Gt, process_delay_Gt, loops_waiting_Gt = get_delays(scanrate_Gt,integration_time,settling_time_Gt,clockfrequency)  # get_delays 
loops_av_gate, process_delay_gate, loops_waiting_gate = get_delays(scanrate_IV, integration_time, settling_time_gate, clockfrequency)  # get_delays gate


Voltage = make_lin_V(maxV_tunnel, bins_to_skip*V_per_V,resolution_output)

NumBias = len(Voltage)

IV_counter = 0
cycles_counter = 0
gate_counter = 1
        
## intialize figure
rcParams['figure.figsize'] = [18, 10]
font = {'weight' : 'normal',
    'size'   : 22}

fig=figure()
ax1 = plt.subplot2grid((1,2), (0, 0))
ax2 = plt.subplot2grid((1,2), (0, 1))

fig.set_facecolor('white')
matplotlib.rc(font)

#########################
##### RUN IV SERIES #####
#########################


if log:
    ADwin_apply_switch(0.0, 0.0, 1000)    
else:    
    ADwin_apply_switch(5.0, 5.0, 1000)    
    
    
######### MAKE STABILITY DIAGRAM #########

print
print 'Making stability diagram'

Matrix1 = zeros((NumBias,Vg_N))       
Matrix2 = zeros((NumBias,Vg_N))       
Matrix_der1 = zeros((NumBias-3,Vg_N))       
Matrix_der2 = zeros((NumBias-3,Vg_N))   
Vg_counter = 0
for Vg in gate_V:
    sleep(2)
    timestr = str(datetime.datetime.now()).split('.')[0]
    print "<"+ timestr + "> Vg = %1.2f" %(Vg)
    
    ADwin_apply_gate(start_Vg / Vg_per_V, Vg / Vg_per_V, process_delay_gate, loops_waiting_gate)  
    start_Vg = Vg
    
    Current1, Current2 = ADwin_record_IV(Voltage / V_per_V, process_delay_IV, loops_waiting_IV, points_av_IV, log, lin_gain, log_conversion)
    Matrix1[:,Vg_counter] = Current1
    Matrix2[:,Vg_counter] = Current2
    
    der1 = divide(diff(Current1[1:-1]),abs(diff(Voltage[1:-1])))
    der2 = divide(diff(Current2[1:-1]),abs(diff(Voltage[1:-1])))
    Matrix_der1[:,Vg_counter] = der1
    Matrix_der2[:,Vg_counter] = der2  
    Vg_counter = Vg_counter + 1   
    
    if log:
        Current = Current1    
        der = der1
    else:    
        Current = Current2    
        der = der2
        
    # IV #
    ax1.clear() 
    plt_current =  ax1.plot(Voltage[1:-1],Current[1:-1],linewidth=2)          
    ax1.set_xlim(-max(Voltage), max(Voltage))
    ax1.set_ylim(min(Current), max(Current))
    ax1.set_xlabel('Bias voltage (V)')
    ax1.set_ylabel('Current (A)')
    ax1.set_yscale("linear")    
    ax1.ticklabel_format(style='sci', axis='y', scilimits=(-2,2))
    
#    # dI/dV #
    ax2.clear() 
    plt_der =  ax2.plot(Voltage[2:-1],der,linewidth=2)          
    ax2.set_xlim(-max(Voltage), max(Voltage))
    ax2.set_xlabel('Bias voltage (V)')
    ax2.set_ylabel('dI/dV (S)')
    ax2.ticklabel_format(style='sci', axis='y', scilimits=(-2,2))
    
    pause(0.01)


# reset gate voltage
ADwin_apply_gate(start_Vg / Vg_per_V, 0.0, process_delay_gate, loops_waiting_gate)  
    

if save:
   filename = save_dir + 'IV' + date + '_' + runnumber + '_' + "%1.0f_gate.dat" %(IV_counter+1)
   file = open(filename, "w")
   make_general_header(file)
   make_IV_series_header(file)
   make_gate_header_IV(file)
   save_data_matrix(file, Voltage, Matrix1)
   save_data_matrix(file, Voltage, Matrix2)
   file.close()
