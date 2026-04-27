###################################
## Driver written by M.L. Perrin ##
## contact: m.l.perrin@tudelft.nl #
###################################
import ADwin

if resolution_input==16:
    address=0x150
if resolution_input==18:
    address=1
          
adw=ADwin.ADwin(address,1)

##### GENERAL #######
def ADwin_boot(resolution):
    if resolution==16:
        boot_script='C:\ADwin\ADwin9.btl'

    if resolution==18:
        boot_script='C:\ADwin\ADwin11.btl'
        
        
    adw.Boot(boot_script)
    #print 'ADwin booted using %s' % boot_script
    return None
   
def ADwin_get_version():
   name = adw.Test_Version()
   print 'Version %s ' % name
   return None

def ADwin_get_processor_type():
   name = adw.Processor_Type()
   print 'Processor type: %s ' % name
   return None
   
##### PROCESSES #######      
def ADwin_load_process(process_name):
   adw.Load_Process(process_name)
   #print 'Process %s has been loaded' % process_name
   return None
    
def ADwin_start_process(process_number):
   adw.Start_Process(process_number)
   #print 'Process %1.0f has been started' % process_number
   return None  
   
def ADwin_process_status(process_number,output):
   status=adw.Process_Status(process_number)
   if output == 'string':
       if status == 0: 
          print 'Process %1.0f is not running' % process_number
       if status == 1: 
          print 'Process %1.0f is running' % process_number
       if status < 0:
          print 'Process %1.0f is stopped' % process_number      
       return None  
   elif output == 'int':
       return status    
   
def ADwin_stop_process(process_number):
   adw.Stop_Process(process_number)
   #print 'Process %1.0f has been stopped' % process_number
   return None   
   
def ADwin_stop_all_process():
   for i in range(1,11):
        adw.Stop_Process(i)
        #print 'Process %1.0f has been stopped' % i
   return None       
 
def ADwin_clear_process(process_number):
   adw.Clear_Process(process_number)
   print 'Process %1.0f has been removed' % process_number
   return None   
   
def ADwin_clear_all_process():
   for i in range(1,11):
        adw.Clear_Process(i)
        print 'Process %1.0f has been cleared' % i
   return None  
 
def ADwin_get_processdelay(process_number):
    delay = adw.Get_Processdelay(process_number)
    return delay 
    
def ADwin_set_processdelay(process_number,process_delay):
    adw.Set_Processdelay(process_number, process_delay)
    return None
   
##### PARAMETERS FLOAT #####    
def ADwin_set_FPar(par, value):
    adw.Set_FPar(par,value)
    
def ADwin_get_FPar(par):
    value=adw.Get_FPar(par) 
    #print 'FPar %1.0f is %1.2f' % (par, value)
    return value
    
def ADwin_get_all_FPar():
    for i in range(1,81):
        print ADwin_get_FPar(i)
        
##### PARAMETERS LONG #####    
        
def ADwin_set_Par(par, value):
    adw.Set_Par(par,value)
    
def ADwin_get_Par(par):
    value=adw.Get_Par(par) 
    #print 'Par %1.0f is %1.2f' % (par, value)
    return value

def ADwin_get_all_Par():
    for i in range(1,81):
        print ADwin_get_Par(i)    
        
##### DATA LONG #####    
def ADwin_get_data_length(par):
    length=adw.Data_Length(par)
    return length
    
def ADwin_set_data_long(par, array):
    adw.SetData_Long(array, par, 1, len(array))
    
def ADwin_get_data_long(par,counts):
    data=adw.GetData_Long(par,1,counts)
    data=convert_to_list(data)
    return data
      
##### DATA FLOAT #####        
def ADwin_set_data_float(par, array):
    adw.SetData_Float(array ,par ,1, len(array))
    
def ADwin_get_data_float(par,counts):
    data=adw.GetData_Float(par,1,counts)
    data=convert_to_list_float(data)
    return data
    
#print 'ADwin drivers loaded'