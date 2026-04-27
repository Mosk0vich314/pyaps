###################################
## Driver written by M.L. Perrin ##
## contact: m.l.perrin@tudelft.nl #
###################################

from math import log10
from numpy import *
from time import *
import smtplib
from email.MIMEMultipart import MIMEMultipart
from email.MIMEText import MIMEText
from email.MIMEImage import MIMEImage

import platform

           
##### clear all variables ####
def clearall():
    """clear all global and local variables"""
    for uniquevar in [var for var in globals().copy() if var[0] != "_" and var != 'clearall']:
        del globals()[uniquevar]
    for uniquevar in [var for var in locals().copy() if var[0] != "_" and var != 'clearall']:
        del locals()[uniquevar]
        
##### close all figures ####
def closefigs():
    for i in range(0,1000):
        close(i)
        
##### read data file to list ######
def read_data_file(*arg):
    # reads matrix from data file. As optional input a column can be specified
    l=len(arg)
    data=[]
    file =open(arg[0])
    for line in file:
        line_list = [float(x) for x in line.split()]
        data.append(line_list) 
    
    if l == 1:
        data2 = data
    elif l == 2:
        data2=[]
        for i in range(0,len(data)):
            temp = data[i]
            temp = temp[arg[1]]   
            data2.append(temp)
    return data2
     

def convert_to_list(data):
    # convert to list
    data2=[]
    for i in range(0,len(data)):
        data2.append(int(data[i])) 
    return data2
    
def convert_to_list_float(data):
    # convert to list
    data2=[]
    for i in range(0,len(data)):
        data2.append(data[i])
    return data2
    
##### convert bins and voltage #####    
def convert_bin_to_V(N_bin, V_range, resolution):
    # converts ADC/DAC bins to voltage, given the voltage range and the resolution (in bits)
    step = 2 * V_range / (2**resolution-1)
    voltage = arange(-V_range, V_range+step, step)
    try: 
        N_bin = int(N_bin)
        data = voltage[N_bin]
    except: 
        data=zeros(len(N_bin))
        for i in range(0,len(N_bin)): 
           data[i]=voltage[N_bin[i]]
              
    return data

def convert_V_to_bin(V, V_range, resolution):
    # converts ADC/DAC voltage to bin number, given the voltage range and the resolution (in bits)
    step=2*V_range/(2**resolution-1)
    voltage=arange(-V_range, V_range+step, step)
    try: 
        l = len(V)
        N_bin = zeros(l)
        for i in range(0,len(V)):
            diff = abs(voltage-V[i])
            N_bin[i] = diff.argmin()
    except:
        diff = abs(voltage - V)
        N_bin = diff.argmin()
   
    return N_bin, convert_bin_to_V(N_bin, V_range,resolution)
    
def convert_bin_to_log_current(N_bin, LOG):
    # converts the bin of the ADC to a current value for a logarithmic amplifier, given the conversion table as list
    data = zeros(len(N_bin))
    for i in range(0,len(N_bin)): 
        data[i] = (LOG[N_bin[i-1]])
    return data    

def remove_double_bins(N_bin):
    # removes succeeding double bins
    index = []
    for i in range(1,len(N_bin)):
        
        if N_bin[i] == N_bin[i-1]:
            index.append(i)
    
    N_bin = delete(N_bin, index)
    
    return N_bin
    
##### get delays #####   
def get_delays(scanrate, integration_time, settling_time, clockfrequency): # Hz, ms, ms, Hz
    # converts scanrate (Hz), integrsation time (ms), settling_time (ms), and ADwin clockfrequency (Hz) to ADwin clock cycles
    loops_av = int(integration_time / 1000. * scanrate)   
    process_delay = int(clockfrequency / scanrate)
    loops_waiting = int(( settling_time / 1000. ) * scanrate)
    return loops_av, process_delay, loops_waiting
    
##### GENERATE FILENAME ##### 
def make_filename(str):
    # generates new filename based on date with format %y%m%d
     try:
        open('filename.dat','r')
     except:
        file = open('filename.dat','w')
        file.close()
    
     if str == 'get':
         file = open('filename.dat','r')
         name = file.read()
         file.close()
         name = name.split()
         if name:
             date = name[0]
             run = name[1]
         else:
             date = ''
             run = ''
             
     if str == 'set':
         file = open('filename.dat','r')
         name = file.read()
         name = name.split()
         date = strftime("%y%m%d")
         file.close() 

         if name == []:
             run = '0'
         else:             
             if name[0] == strftime("%y%m%d"):
                  run = '%1.0f' % (int(name[1]) + 1)
             else:
                  run = '0'

     file = open('filename.dat','w')
     file.write(date + " %s" % run)
     file.close() 
         
     return date, run
    
##### clear all variables ####
def stop():
    """stop ADwin and motor"""
    ADwin_stop_all_process()
    if motor:
        Faulhaber_command('v 0')
        
##### clear all variables ####
def top():
    stop()      
        
        
def update_status(status,file_name):
    fromaddr = 'MCBJ.delft@gmail.com'
    toaddrs  = 'mickael.l.perrin@gmail.com'
    
    msg = MIMEMultipart()
    msg['From'] = fromaddr
    msg['To'] = toaddrs
    
    subject = ''
    if status == 2:
        subject = 'Measurement on ' + platform.node() + ' done'  
    if status == 3 :
        subject = 'Measurement on ' + platform.node() + ' crashed during making'
    if status == 4:
        subject = 'Measurement on ' + platform.node() + ' crashed during breaking'        
    if status == 5 :
        subject = 'Measurement on ' + platform.node() + ' crashed during plotting'    
    msg['Subject'] = subject
    
    fp = open(file_name, 'rb')
    attachment = MIMEImage(fp.read(),_subtype="png")
    fp.close()
    
    msg.attach(attachment)
            
    # Credentials (if needed)
    username = 'MCBJ.delft@gmail.com'
    password = 'Breakit!'
    
    # The actual mail send
    server = smtplib.SMTP('smtp.gmail.com:587')
    server.starttls()
    server.login(username,password)
    server.sendmail(fromaddr, toaddrs, msg.as_string())
    server.quit()
    
def apply_butterworth(data, order, cut_off):
    filtered = zeros(len(data)) + data[0]
    b, a = butter(order, cut_off, 'low')
    a = delete(a,0)
    a = a[::-1]
    b = b[::-1]
    filt = zeros(order + 1) +  mean(data[0:5])
    raw = zeros(order + 1)  +  mean(data[0:5])
    
    for i in range(0,len(data)):
        raw = delete(raw, 0)
        raw = append(raw, data[i])  
        filt = delete(filt, 0)
        filt_new = dot(b, raw) - dot(a, filt) 
        filt = append(filt,filt_new)
        filtered[i] = filt_new
        
    return filtered