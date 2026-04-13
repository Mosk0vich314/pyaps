%% clear
clear
close all hidden
clc
tic

%% Settings
Settings.ADC = {1e9, 'off', 'off', 'off', 'off', 'off', 'off', 'off'};    % 1e6 fixed gain % auto = linear with auto ranging; off = disabled; log = logarithmic (not yet implemented)
Settings.auto = ''; % FEMTO
Settings.ADC_gain = [0 0 0 0 0 0 0 0]; % 2^N
Settings.ADwin = 'GoldII'; % GoldII or ProII
Settings.res4p = 0;     % 4 point measurement

Gate.V_per_V = 1;          % V/V0

%Gate Waveform
Gate.Amplitude = 10; %V
Gate.Frequency = 10; %Hz
Gate.points_per_cycle = 100;
Gate.output = 2;              % AO channel

Gate.process = 'Waveform_AO';

Timetrace.runtime = 5; %s
Timetrace.scanrate = 500000;       % Hz
Timetrace.points_av = 1 * Timetrace.scanrate / (Gate.Frequency * Gate.points_per_cycle) ;        % points
Timetrace.model = 'ADwin';
Timetrace.settling_time = 0;
Timetrace.settling_time_autoranging = 200;

%%
Settings.plot_position = [0.02 0.06 0.96 0.85];
Settings.Labels.Y_1D = 'Current (A)';
Settings.Labels.X_1D = 'Gate voltage (V)';
Settings.Labels.X_2D = 'Bias voltage (V)';
Settings.Labels.Y_2D = 'Gate voltage (V)';
Settings.fixed_voltage = 'Voltage';

idx = regexp(pwd,'(Matlab\\)');
tmp = pwd;
addpath(genpath([tmp(1:idx-1) 'Matlab\Libs\']));
Settings.path = [tmp(1:idx-1) 'Matlab\Libs\ADwin_script'];
addpath(genpath(Settings.path));

%% Initialize ADwin and piezo
[Settings, Timetrace] = get_readAI_process(Settings, Timetrace);
Settings = Init_ADwin(Settings, Timetrace, Gate);

%% generate gate vector
Gate.time = linspace(1 / (Gate.Frequency * Gate.points_per_cycle), Timetrace.runtime + 0.2, Gate.Frequency * Gate.points_per_cycle * (Timetrace.runtime + 0.2))';
Gate.bias = Gate.Amplitude * sin(2*pi*Gate.Frequency * Gate.time); %V
Gate.scanrate = Gate.Frequency*Gate.points_per_cycle;
Settings.type = 'Gatesweep';
Gate.type = 'Gatesweep';

%% start sine wave
Gate = Run_sweepAO(Settings, Gate);

%% run timetrace
Gate.index = 1;
Gate.repeat = 1;
Timetrace = Run_timetrace(Settings, Timetrace);

%% Init figure
% figure;
ax1 = gca;
lines = animatedline('Color','black','LineWidth',1.5,'Parent',ax1);

%% plot realtime
previous_counter = 0;
pause(0.2);
run = true;
while run && Get_Par(19) > 0

    run = Process_Status(2);
    actual_time = Get_Par(19) - 1;

    %% get current and update plot
    temp = zeros(1, actual_time - previous_counter);
    try
        temp = GetData_Double(2, previous_counter + 1, actual_time - previous_counter);
        addpoints(lines, Gate.time(previous_counter + 1 : actual_time), temp);
    end
    drawnow limitrate

    previous_counter = actual_time;

end
toc