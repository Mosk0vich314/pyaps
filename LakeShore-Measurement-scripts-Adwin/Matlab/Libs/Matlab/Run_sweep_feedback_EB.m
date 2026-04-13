function Structure = Run_sweep_feedback_EB(Settings, Structure)
%% wait until previous process is finished
run = Process_Status(Structure.process_number);
while run 
    pause(0.1);
    run = Process_Status(Structure.process_number);
end


%% set parameters
Structure.points_av = 9000 * Structure.V_per_V / Structure.sweep_rate;
Structure.points_av_down = 135 * Structure.V_per_V / Structure.sweep_rate_back;

[Structure.process_delay, Structure.loops_waiting] = get_delays(Structure.scanrate, Structure.settling_time, Settings.clockfrequency);  % get_delays
[~, Structure.loops_waiting_autoranging] = get_delays(Structure.scanrate,  Structure.settling_time_autoranging, Settings.clockfrequency);  % get_delays
Structure.time_per_point = (Structure.points_av / Structure.scanrate) + (Structure.settling_time / 1000); % 1/sampling rate
Structure.sampling_rate = 1 / Structure.time_per_point;

% set ADCs
Set_Par(1,Settings.ADC_gain(1));
Set_Par(2,Settings.ADC_gain(2));
Set_Par(3,Settings.ADC_gain(3));
Set_Par(4,Settings.ADC_gain(4));
Set_Par(10, Settings.input_resolution);
Set_Par(66,Settings.output_resolution);

% set addresses
Set_Par(5,Settings.AI_address);
Set_Par(6,Settings.AO_address);
Set_Par(7,Settings.DIO_address);

% set output channel
Set_Par(8,Structure.output);

SetData_Double(3,zeros(1000),1);

% set current amplifier settings
for i = 1:Settings.N_ADC
    if isnumeric(Settings.ADC{i})
        Set_Par(26+i, round(abs(log10(Settings.ADC{i}))));
    end
    if strcmp(Settings.ADC{i},'auto')
        Set_Par(26+i, -2);
    end
    if strcmp(Settings.ADC{i},'off')
        Set_Par(26+i, -1);
    end
end

% Inputs IV
Set_Par(21, Structure.points_av);
Set_FPar(3, Structure.points_av_down);
Set_Par(22, Structure.loops_waiting);  % loops waiting after each point
Set_Par(26, Structure.loops_waiting_autoranging);                        % loops waiting after each autoranging switch 

% bias
% [Structure.bias_bins, Structure.bias_new] = convert_V_to_bin(Settings.output_min, Settings.output_max, Settings.output_resolution);
% Structure.bias_end = Structure.maxV / Structure.V_per_V;
Structure.bin_end =  convert_V_to_bin(Structure.maxV / Structure.V_per_V, Settings.output_min, Settings.output_max, Settings.output_resolution);
Structure.bin_zero_point =  convert_V_to_bin(0, Settings.output_min, Settings.output_max, Settings.output_resolution) - 1;
Set_Par(28, Structure.bin_end);
% Structure.bias_bins = Structure.bias_bins - 1;
% SetData_Double(1, Structure.bias_bins, 1);
Set_Par(25, 0);             % reset sweep counter
Set_Par(26, Structure.mov_win);
Set_FPar(2, Structure.current_threshhold);
Set_Par(30, Structure.bin_zero_point);

if regexp(Settings.type,'IV')
    Structure.type = 'IV';
end
if regexp(Settings.type,'Stability')
    Structure.type = 'IV';
end
if regexp(Settings.type,'Gatesweep')
    Structure.type = 'Gate';
end
if regexp(Settings.type,'Gt')
    Structure.type = 'Gt';
end

%% create data structure for first IV
if Structure.index == 1
    for i = 1:Settings.N_ADC
        Structure.current{i} = cell(Structure.repeat);
    end
end

%% run measurement
Set_Processdelay(Structure.process_number, Structure.process_delay);
Start_Process(Structure.process_number);

