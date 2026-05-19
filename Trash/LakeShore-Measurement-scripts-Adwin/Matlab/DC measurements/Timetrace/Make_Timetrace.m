%% clear
clear
close all hidden
clc

%% Settings
Settings.save_dir =  'C:\Samples\Mickael\testing\';     
Settings.sample = 'ADwin_femto_powered_100MOhm';
Settings.ADC = {1e8,'off','off', 'off', 'off', 'off', 'off', 'off','off'};    %{1, 1, 1, 1, 1, 1, 1, 1};% 1e6 fixed gain % auto = linear with auto ranging; off = disabled; log = logarithmic (not yet implemented)
Settings.ADC_gain = [0 0 0 0 0 0 0 0]; % 2^N
Settings.get_sample_T = ''; % {'', 'Lakeshore336', 'Lakeshore325', 'Oxford_ITC'}
Settings.type = 'Timetrace';
Settings.ADwin = 'GoldII'; % GoldII or ProII

Bias.initV = 0;
Bias.V_per_V = 1;          % V/V0
Bias.targetV = 0.1;              % V
Bias.endV = 0;              % V
Bias.ramp_rate = 0.1;
Bias.fixed_voltage = 'ADwin';
Bias.waiting_time = 0;          %sec

Timetrace.repeat = 1;
Timetrace.runtime = 5;      % s
Timetrace.scanrate = 200000;       % Hz
Timetrace.points_av = 1;        % points
Timetrace.settling_time = 0;      % ms
Timetrace.settling_time_autoranging = 0;      % ms
Timetrace.process_number = 2;
Timetrace.clim = [];
Timetrace.model ='ADwin';

Gate.initV = 0;          % V
Gate.targetV = 0;            % V
Gate.endV = 0;            % V
Gate.ramp_rate = 1;       % V/s
Gate.waiting_time = 0;     % s after setting Gate.setV  %%can this be implemented via Gate.settling_time?
Gate.V_per_V = 1;          % V/V0
Gate.output = 2;            % AO channel
Gate.process_number = 3;
Gate.process = 'Fixed_AO';

Gate.output = 2;
Gate.process_number = 3;
Gate.process = 'Fixed_AO';

Bias.output = 1;
Bias.process_number = 3;
Bias.process = 'Fixed_AO';

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
Bias.startV = Bias.initV;          % V
Bias.setV = Bias.targetV;            % V

fprintf('%s - Ramping Bias to %1.2fV...', datetime('now'), Bias.setV)
Bias = Apply_fixed_voltage(Settings, Bias);
fprintf('done\n')

%% start measurement
for i = 1:Timetrace.repeat
    
    %% run Timetrace
    fprintf('Running Timetrace - %1.0f/%1.0f...', i, Timetrace.repeat)
    Timetrace.index = i;
    Timetrace = Run_timetrace(Settings, Timetrace);
    
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
Save_data(Settings, Timetrace, Bias, Gate, [filename '.mat']);

%% ramp gate to zero
Gate.startV = Gate.targetV;
Gate.setV = Gate.endV;

fprintf('%s - Ramping Gate to %1.2fV...', datetime('now'), Gate.setV)
Gate = Apply_fixed_voltage(Settings, Gate);
fprintf('done\n')

%% ramp bias voltage to setpoint
Bias.startV = Bias.targetV;
Bias.setV = Bias.endV;

fprintf('%s - Ramping Bias to %1.2fV...', datetime('now'), Bias.setV)
Bias = Apply_fixed_voltage(Settings, Bias);
fprintf('done\n')

%% reset gate 
% reset_gate(Settings, Gate)

%% do FFT
fig_fft = figure;
set(gcf,'color','white')

Y = fft(Timetrace.voltage{1});
P2 = abs(Y/Timetrace.runtime_counts);
P1 = P2(1:Timetrace.runtime_counts/2+1);
P1(2:end-1) = 2*P1(2:end-1);

f = Timetrace.sampling_rate/Timetrace.runtime_counts*(0:(Timetrace.runtime_counts/2));

plot(f,P1,"LineWidth",3) 
title("Single-Sided Amplitude Spectrum of X(t)")
xlabel("f (Hz)")
ylabel("|P1(f)|")
set(gca,'XScale','log')
set(gca,'Box','on','LineWidth',2,'FontSize',20)

saveas(fig_fft, [filename '_FFT.png'])
saveas(fig_fft, [filename '_FFT.fig'])