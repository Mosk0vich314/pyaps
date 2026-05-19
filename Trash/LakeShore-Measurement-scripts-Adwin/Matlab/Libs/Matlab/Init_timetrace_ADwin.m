function Timetrace = Init_timetrace_ADwin(Settings, Timetrace)

%% set parameters
[Timetrace.process_delay, Timetrace.loops_waiting] = get_delays(Timetrace.scanrate, Timetrace.settling_time, Settings.clockfrequency);  % get_delays
[~, Timetrace.loops_waiting_autoranging] = get_delays(Timetrace.scanrate, Timetrace.settling_time_autoranging, Settings.clockfrequency);  % get_delays
Timetrace.time_per_point = (Timetrace.points_av / Timetrace.scanrate) + (Timetrace.settling_time / 1000); % 1/sampling rate
Timetrace.sampling_rate = 1 / Timetrace.time_per_point;
Timetrace.runtime_counts = ceil(Timetrace.sampling_rate * Timetrace.runtime);

% create time vector
Timetrace.time.ADwin = (0:Timetrace.time_per_point:(Timetrace.runtime_counts-1)*Timetrace.time_per_point)';

% set ADCs
Set_Par(10, Settings.input_resolution);

% set addresses
Set_Par(5,Settings.AI_address);
Set_Par(6,Settings.AO_address);
Set_Par(7,Settings.DIO_address);

% set number of ADC pairs
Set_Par(20, Settings.N_ADC_pairs);

% set amplifier settings
PARS = 27:34;
for i = 1:Settings.N_ADC
    if isnumeric(Settings.ADC{i})
        Set_FPar(PARS(i), log10(Settings.ADC{i}));
    end
end

% Inputs timetrace
Set_Par(14, Timetrace.runtime_counts);
Set_Par(21, Timetrace.points_av);
Set_Par(22, Timetrace.loops_waiting);  % loops waiting after each point
Set_Par(26, Timetrace.loops_waiting_autoranging);                        % loops waiting after each autoranging switch

%% set ADC gains
SetData_Double(11, Settings.ADC_gain, 1);

%% run measurement
Set_Processdelay(2, Timetrace.process_delay);
