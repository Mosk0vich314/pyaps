%Set_Processdelay  sets the parameter Processdelay for a process
%
%  Syntax:  Set_Processdelay (ProcessNo, Processdelay)
%
%  Parameters:
%    ProcessNo       Process number (1...10).
%    Processdelay    Value (1...231-1) to be set for the parameter Processdelay
%                    of the process (see table below).
%    Return value    <>255: OK
%                    255: Error
%
%  Notes:
%    The parameter Processdelay controls the cycle time, the time interval
%    between two events of a time-controlled process (see manual ADbasic or
%    online help).
%    For each process there is a minimum cycle time: If you fall below the
%    minimum value you will get an overload of the ADwin processor and
%    communication will fail.
%    The cycle time is specified in cycles of the ADwin processor. The cycle
%    time depends on processor type and process priority:
%    Processor type          Process priority
%                            high                     low
%    T2, T4, T5, T8          1000 ns                  64 탎
%    T9                      25 ns                    100 탎
%    T10                     25 ns                    50 탎
%    T11                     3.3 ns                   0.003 탎 = 3.3 ns
%    T12                     1 ns                     1 ns
%
%  Example:
%    % Set Processdelay 2000 of process 1
%    ret_val = Set_Processdelay(1,2000);
%    %If process 1 is time-controlled, has high priority and runs on a T9
%    %processor, process cycles are called every 50 탎 (=2000 * 25 ns).
%
%  See also PROCESS_STATUS, GET_PROCESSDELAY.
%
%  Support address:  <a href="matlab:web('mailto:support@ADwin.de')">support@ADwin.de</a>
%  Homepage:         <a href="matlab:web('http://www.ADwin.de', '-browser')">www.ADwin.de</a>

%  Copyright (c) 1995-2016 by Jaeger Computergesteuerte Messtechnik GmbH
%  $Revision: 4.09.00 $  $Date: 2016-02-01  09:30:19 $
