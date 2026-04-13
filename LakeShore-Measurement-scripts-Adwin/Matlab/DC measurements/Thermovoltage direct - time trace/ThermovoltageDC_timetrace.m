%% clear
clear
close all hidden
clc

%% Settings
Settings.save_dir =  'E:\Samples\FrevaPaal_graphene_TEP\ThermVoltageDCTimeMeasurements\';     

Settings.sample = 'ThermoVoltageDCADwinTEST4';
Settings.ADC = {10000,'off','off', 'off', 'off', 'off', 'off', 'off','off'};    %{1, 1, 1, 1, 1, 1, 1, 1};% 1e6 fixed gain % auto = linear with auto ranging; off = disabled; log = logarithmic (not yet implemented)
Settings.ADC_gain = [0 0 0 0 0 0 0 0]; % 2^N
Settings.get_sample_T = ''; % {'', 'Lakeshore336', 'Lakeshore325', 'Oxford_ITC'}
Settings.type = 'Timetrace';
Settings.ADwin = 'GoldII'; % GoldII or ProII

HeaterV.initV = 0;
HeaterV.V_per_V = 1;          % V/V0
HeaterV.targetV = 2;              % V
HeaterV.endV = 0;              % V
HeaterV.ramp_rate = 10000;
HeaterV.fixed_voltage = 'ADwin';
HeaterV.waiting_time = 0;          %sec

Timetrace.repeat = 1;
Timetrace.runtime = 15;      % s
Timetrace.scanrate = 250000;       % Hz
Timetrace.points_av = 50;        % points
Timetrace.settling_time = 0;      % ms
Timetrace.settling_time_autoranging = 0;      % ms
Timetrace.process_number = 2;
Timetrace.clim = [];
Timetrace.model ='ADwin';

Gate.initV = 0;          % V
Gate.targetV = -4;            % V
Gate.endV = 0;            % V
Gate.ramp_rate = 1;       % V/s
Gate.waiting_time = 0;     % s after setting Gate.setV  %%can this be implemented via Gate.settling_time?
Gate.V_per_V = 10;          % V/V0
Gate.output = 2;            % AO channel
Gate.process_number = 3;
Gate.process = 'Fixed_AO';

Gate.output = 2;
Gate.process_number = 3;
Gate.process = 'Fixed_AO';

HeaterV.output = 1;
HeaterV.process_number = 3;
HeaterV.process = 'Fixed_AO';

eSwitch.ramp_rate = 10000;
eSwitch.fixed_voltage = 'ADwin';
eSwitch.waiting_time = 0;          %sec

eSwitch.V_per_V = 1;          % V/V0
eSwitch.output = 5;
eSwitch.process_number = 3;
eSwitch.process = 'Fixed_AO';

%% Initialize 
Settings = Init(Settings);

%% Initialize ADwin
[Settings, Timetrace] = get_readAI_process(Settings, Timetrace);
Settings = Init_ADwin(Settings, Timetrace, Gate);
%% set gate voltage
Gate.startV = Gate.initV;          % V
Gate.setV = Gate.targetV;            % V

fprintf('%s - Ramping Gate to %1.2fV...', datetime('now'), Gate.setV)
Gate = Apply_fixed_voltage(Settings, Gate);
fprintf('done\n')

% wait after gate set
fprintf('%s - Gate Settling...', datetime('now'))
pause(Gate.waiting_time)
fprintf('done\n')

%% set bias voltage
HeaterV.startV = HeaterV.initV;          % V
HeaterV.setV = HeaterV.targetV;            % V
HeaterV = Apply_fixed_voltage(Settings, HeaterV);

%% start measurement
for i = 1:Timetrace.repeat
    
    %% run Timetrace
    fprintf('Running Timetrace - %1.0f/%1.0f...', i, Timetrace.repeat)
    Timetrace.index = i;
    Timetrace = Run_timetrace_AdwinThermoVoltage(Settings, Timetrace,  eSwitch);
    
    %% get current and show plot
    Timetrace = Realtime_timetrace(Settings, Timetrace, Settings.type);

    fprintf('done\n')
    
end

%% save figure
fig = findobj('Name', Settings.type);
filename = sprintf('%s/%s_%s_%s', Settings.save_dir, Settings.filename, Settings.sample, Settings.type);
saveas(fig, [filename '.png'])
saveas(fig, [filename '.fig'])

%% save data
Save_data(Settings, Timetrace, HeaterV, Gate, [filename '.mat']);

%% ramp gate to zero
Gate.startV = Gate.targetV;
Gate.setV = Gate.endV;

fprintf('%s - Ramping Gate to %1.2fV...', datetime('now'), Gate.setV)
Gate = Apply_fixed_voltage(Settings, Gate);
fprintf('done\n')

%% ramp bias voltage to setpoint
HeaterV.startV = HeaterV.targetV;
HeaterV.setV = HeaterV.endV;

fprintf('%s - Ramping Bias to %1.2fV...', datetime('now'), HeaterV.setV)
HeaterV = Apply_fixed_voltage(Settings, HeaterV);
fprintf('done\n')

eSwitch.startV = 5;          % V
eSwitch.setV = 0;            % V
eSwitch = Apply_fixed_voltage(Settings, eSwitch);

%% reset gate 
% reset_gate(Settings, Gate)