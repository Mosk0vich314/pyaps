%Boot  initializes the ADwin system and loads the file of the operating system.
%
%  Syntax:  Boot (Filename, MemSize)
%
%  Parameters:
%    Filename        Path and filename of the operating system file (see below).
%    MemSize         For processors up from T9: 0 (zero).
%                    For T2, T4, T5, T8: Memory size to be used; the following
%                    values are permitted:
%                       10000:     64 KiB
%                      100000:     1 MiB
%                      200000:     2 MiB
%                      400000:     4 MiB
%                      800000:     8 MiB
%                     1000000:    16 MiB
%                     2000000:    32 MiB
%    Return value    Status:
%                    <1000: Error during boot process
%                     8000: Boot process o.k.; up from processor T9.
%                    >8000: Boot process o.k.; for T2...T8 only. The value is
%                    the size of physically installed memory.
%
%  Notes:
%    The initialization deletes all processes on the system and sets all global
%    variables to 0.
%    The operating system file to be loaded depends on the processor type of the
%    system you want to communicate with. The following table shows the file
%    names for the different processors. The files are located in the directory
%    <C:\ADwin\>.
%    ADwin-Type         Processor         Operating System File
%    ADwin-2            T225              ADwin2.btl
%    ADwin-4            T400              ADwin4.btl
%    ADwin-5            T450              ADwin5.btl
%    ADwin-8            T805              ADwin8.btl
%    ADwin-9            T9                ADwin9.btl
%                                         ADwin9s.btl Optimized operating system
%                                         with smaller memory needs.
%    ADwin-10           T10               ADwin10.btl
%    ADwin-11           T11               ADwin11.btl
%    ADwin-12           T12               ADwin12.btl
%    The computer will only be able to communicate with the ADwin system after
%    the operating system has been loaded. Load the operating system again after
%    each power up of the ADwin system.
%    For ADsim users: As Filename you enter the Simulink model being compiled
%    via ADsimDesk, which also contains the operating system for the processor.
%    The model file is stored in the model folder in the sub-folder
%    <model>_ert_rtw/ADwin/ with the name <model>11c.btl.
%    <model> stands for the name of the Simulink model. The notation 11c refers
%    to the processor type T11 of the ADwin hardware; other processor types are
%    not supported.
%    Loading the operating system with Boot takes about one second. As an
%    alternative you can also load the operating system via ADbasic or ADsimDesk
%    development environment.
%    Please note that ADbasic processes and a compiled Simulink model cannot be
%    processed on the ADwin hardware at the same time.
%
%  Example:
%    % Load the operating system for the T10 processor
%    ret_val = Boot ('C:\ADwin\ADwin10.btl', 0);
%    
%    % Load a Simulink model being compiled with ADsim
%    path = 'C:\ADwin\ADsim\Developer\Examples\';
%    subpath = 'ADsim32_DLL_Example_ert_rtw\ADwin\';
%    Boot([path,subpath,'ADsim32_DLL_Example11c.btl'], 0);
%
%  See also START_PROCESS, STOP_PROCESS, LOAD_PROCESS, SET_DEVICENO, GET_DEVICENO, FREE_MEM, WORKLOAD.
%
%  Support address:  <a href="matlab:web('mailto:support@ADwin.de')">support@ADwin.de</a>
%  Homepage:         <a href="matlab:web('http://www.ADwin.de', '-browser')">www.ADwin.de</a>

%  Copyright (c) 1995-2016 by Jaeger Computergesteuerte Messtechnik GmbH
%  $Revision: 4.09.00 $  $Date: 2016-02-01  09:30:19 $
