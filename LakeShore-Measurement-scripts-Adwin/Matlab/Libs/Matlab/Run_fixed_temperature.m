function Gt = Run_fixed_temperature(Settings, Gt)

%% set parameters
[Gt.process_delay, Gt.loops_waiting] = get_delays(Gt.scanrate, Gt.settling_time, Settings.clockfrequency);  % get_delays
[~, Gt.loops_waiting_autoranging] = get_delays(Gt.scanrate, Gt.settling_time_autoranging, Settings.clockfrequency);  % get_delays

Gt.time_per_point = (Gt.points_av / Gt.scanrate) + (Gt.settling_time / 1000); % 1/sampling rate
Gt.sampling_rate = 1 / Gt.time_per_point;
Gt.runtime_counts = ceil(Gt.sampling_rate * Gt.runtime);

% set ADCs
Set_Par(1, Settings.ADC_gain(1));
Set_Par(2, Settings.ADC_gain(2));
Set_Par(3, Settings.ADC_gain(3));
Set_Par(4, Settings.ADC_gain(4));
Set_Par(10, Settings.input_resolution);

% set addresses
Set_Par(5, Settings.AI_address);
Set_Par(6, Settings.AO_address);
Set_Par(7, Settings.DIO_address);

% set bias channel
Set_Par(8, Gt.output);

% set number of ADC pairs 
Set_Par(20, Settings.N_ADC_pairs);

% set current amplifier settings
ADC_par = 27:34;
for i = 1:Settings.N_ADC
    if isnumeric(Settings.ADC{i})
        Set_FPar(ADC_par(i), log10(abs(Settings.ADC{i})));
    end
end

% Inputs Gt
[Gt.startV_bin, Gt.startV_new] = convert_V_to_bin(Gt.startV / Gt.V_per_V, Settings.output_min, Settings.output_max, Settings.output_resolution);
Gt.startV_new = Gt.startV_new * Gt.V_per_V;
Gt.startV_bin = Gt.startV_bin - 1;
Set_Par(11, Gt.startV_bin);

[Gt.setV_bin, Gt.setV_new] = convert_V_to_bin(Gt.setV / Gt.V_per_V, Settings.output_min, Settings.output_max, Settings.output_resolution);
Gt.setV_new = Gt.setV_new * Gt.V_per_V;
Gt.setV_bin = Gt.setV_bin - 1;
Set_Par(12, Gt.setV_bin);

[Gt.endV_bin, Gt.endV_new] = convert_V_to_bin(Gt.endV / Gt.V_per_V, Settings.output_min, Settings.output_max, Settings.output_resolution);
Gt.endV_new = Gt.endV_new * Gt.V_per_V;
Gt.endV_bin = Gt.endV_bin - 1;
Set_Par(13, Gt.endV_bin);

Set_Par(14, Gt.runtime_counts);
Set_Par(15, Gt.points_av);
Set_Par(16, Gt.loops_waiting);

Gt.max_frequency =  Gt.ramp_rate / ((Settings.output_max - Settings.output_min) / (2^Settings.output_resolution)) / Gt.V_per_V;
Gt.ramp_rate_cycles = round(Gt.scanrate / Gt.max_frequency);

Set_Par(17, Gt.ramp_rate_cycles);
Set_Par(18, Gt.loops_waiting_autoranging);     % autoranging waiting counter
Set_Par(19, 0);     % reset time counter

Gt.type = 'Gt';

%% create data structure for first G(t)
if Gt.index == 1
    for i = 1:Settings.N_ADC
        Gt.voltage{i} = zeros(Gt.runtime_counts, Gt.repeat);
    end
    
    for k = 1:4
    Gt.temperature{k} = zeros(Gt.runtime_counts, Gt.repeat);
    end
end

%% run measurement
Set_Processdelay(Gt.process_number, Gt.process_delay);
Start_Process(Gt.process_number);
