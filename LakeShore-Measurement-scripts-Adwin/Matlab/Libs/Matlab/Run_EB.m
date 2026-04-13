function Structure = Run_EB(Settings, Structure)

%% create bias vector
Structure.bias = [Structure.startV_high:Structure.dV:Structure.endV]';
Structure.NumBias = length(Structure.bias) * Structure.cyclecounter * Structure.timecounter / Structure.points_av;

%% set parameters
[ Structure.process_delay, Structure.loops_waiting] = get_delays(Structure.scanrate, Structure.settling_time, Settings.clockfrequency);  % get_delays
% [~, ~, Structure.loops_waiting_autoranging] = get_delays(Structure.scanrate, Structure.integration_time, Structure.settling_time_autoranging, Settings.clockfrequency);  % get_delays
Structure.time_per_point = (Structure.points_av / Structure.scanrate) + (Structure.settling_time / 1000); % 1/sampling rate
Structure.sampling_rate = 1 / Structure.time_per_point;

% set ADCs
Set_Par(1,Settings.ADC_gain(1));
Set_Par(2,Settings.ADC_gain(2));
Set_Par(3,Settings.ADC_gain(3));
Set_Par(4,Settings.ADC_gain(4));


% set addresses
Set_Par(5,Settings.AI_address);
Set_Par(6,Settings.AO_address);
Set_Par(7,Settings.DIO_address);

% set output channel
Set_Par(8,Structure.output);

% set output channel
Set_Par(10,Settings.input_resolution);
Set_Par(66,Settings.output_resolution);

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


% bias
bias = [Structure.startV_low Structure.startV_high Structure.setV_low Structure.setV_high Structure.endV Structure.baseV Structure.dV];
[Structure.bias_bin, Structure.bias_new] = convert_V_to_bin(bias / Structure.V_per_V, Settings.output_min, Settings.output_max, Settings.output_resolution);
Structure.bias_new = Structure.bias_new * Structure.V_per_V;
Structure.bias_bin = Structure.bias_bin - 1;

Structure.bias_steps_bin = Structure.bias_bin(7)-Structure.bias_bin(6);

Set_Par(61, Structure.bias_bin(1));  
Set_Par(62, Structure.bias_bin(3));  
Set_Par(63, Structure.bias_bin(2));  
Set_Par(64, Structure.bias_bin(4)); 
Set_Par(65, Structure.bias_bin(5));
Set_Par(67, Structure.points_av);
Set_Par(68, Structure.timecounter);
Set_Par(69, Structure.cyclecounter);
Set_Par(70, Structure.bias_steps_bin);
Set_Par(72, Structure.threshhold_low);
Set_Par(73, Structure.threshhold_high);
Set_Par(75, Structure.Output_Amplification);
Set_Par(76, Structure.NumBias);


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
if regexp(Settings.type,'EB')
    Structure.type = 'EB';
end

    
% create data structure for EB
Structure.repeat = 1;
Structure.index = 1;
if Structure.index == 1
    for i = 1:Settings.N_ADC
        Structure.data{i} = zeros(Structure.NumBias, Structure.repeat);
    end
end



%% run measurement
Set_Processdelay(Structure.process_number, Structure.process_delay);
Start_Process(Structure.process_number);

