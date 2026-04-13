function [process_delay, loops_waiting]  =  get_delays(scanrate, settling_time, clockfrequency)
% converts scanrate (Hz), integration time (ms), settling_time (ms), and ADwin clockfrequency (Hz) to ADwin clock cycles

process_delay = round(clockfrequency / scanrate);
loops_waiting = round( settling_time / 1000  * scanrate);

return