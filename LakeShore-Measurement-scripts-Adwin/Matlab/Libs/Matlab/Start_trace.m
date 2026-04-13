function Histo = Start_trace(Settings, Histo)

%% set parameters
[Histo.process_delay, Histo.loops_waiting] = get_delays(Histo.scanrate, Histo.settling_time, Settings.clockfrequency);  % get_delays

Histo.time_per_point = (Histo.points_av / Histo.scanrate) + (Histo.settling_time / 1000); % 1/sampling rate
Histo.sampling_rate = 1 / Histo.time_per_point;
Histo.runtime_counts = ceil(Histo.sampling_rate * Histo.runtime);
Histo.runtime_new = Histo.runtime_counts / Histo.sampling_rate;

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
Set_Par(8, Histo.output);

% set current amplifier settings
for i = 1:Settings.N_ADC
    if isnumeric(Settings.ADC{i})
        Set_Par(25+i, round(log10(Settings.ADC{i})));
    end
    if strcmp(Settings.ADC{i},'auto')
        Set_Par(25+i, 1);
    end
    if strcmp(Settings.ADC{i},'log')
        Set_Par(25+i, 2);
    end
    if strcmp(Settings.ADC{i},'off')
        Set_Par(25+i, 0);
    end
end

% Voltage settings Histogram
[Histo.startV_bin, Histo.startV_new] = convert_V_to_bin(Histo.startV / Histo.V_per_V, Settings.output_min, Settings.output_max, Settings.output_resolution);
Histo.startV_new = Histo.startV_new * Histo.V_per_V;
Histo.startV_bin = Histo.startV_bin - 1;
Set_Par(11, Histo.startV_bin);

[Histo.setV_bin, Histo.setV_new] = convert_V_to_bin(Histo.setV / Histo.V_per_V, Settings.output_min, Settings.output_max, Settings.output_resolution);
Histo.setV_new = Histo.setV_new * Histo.V_per_V;
Histo.setV_bin = Histo.setV_bin - 1;
Set_Par(12, Histo.setV_bin);

[Histo.endV_bin, Histo.endV_new] = convert_V_to_bin(Histo.endV / Histo.V_per_V, Settings.output_min, Settings.output_max, Settings.output_resolution);
Histo.endV_new = Histo.endV_new * Histo.V_per_V;
Histo.endV_bin = Histo.endV_bin - 1;
Set_Par(13, Histo.endV_bin);

% data acquisition
Set_Par(14, Histo.runtime_counts);
Set_Par(15, Histo.points_av);
Set_Par(16, Histo.loops_waiting);

% piezo speed (to fix)
Set_Par(33, Histo.breaking_speed1);
Set_Par(34, Histo.breaking_speed2);
Set_Par(35, Histo.making_speed);
Set_Par(36, 1000000);

% motion reversal, current threshold
Set_FPar(30, Histo.inter_G * Settings.G0 * Histo.setV);
Set_FPar(31, Histo.lower_G * Settings.G0 * Histo.setV);
Set_FPar(32, Histo.upper_G * Settings.G0 * Histo.setV);

%% set measurement type
Histo.type = 'Histo';

%% run measurement
Set_Processdelay(Histo.process_number, Histo.process_delay);
Start_Process(Histo.process_number);
