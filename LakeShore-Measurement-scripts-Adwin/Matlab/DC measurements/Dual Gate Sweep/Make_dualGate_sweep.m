%% clear
clear
close all hidden
clc
tic

%% Settings
Settings.save_dir = 'C:\Samples\20240409_Zhang_DG_solutionGNR01\260mK\dualgate'; 
Settings.sample = {'Box13_E2_1mV'};%
Settings.ADC = {1e10, 'off', 'off', 'off', 'off', 'off', 'off', 'off'};    
Settings.auto = ''; % FEMTO
Settings.ADC_gain = [0 0 0 0]; % 2^N
Settings.get_sample_T = ''; % {'', 'Lakeshore336', 'Lakeshore325', 'Oxford_ITC'}
Settings.type = 'DualGatesweep';
Settings.IVcutoff = 150; % Hz
Settings.ADwin = 'GoldII'; % GoldII or ProII
Settings.res4p = 0;     % 4 point measurement
Settings.T = 0.01;   %;

Gate.V_per_V = 1;          % V/V0
Gate.startV = 0.0;            % V
Gate.maxV = 2;              % V
Gate.minV = -2;         % V
Gate.points = 401;
Gate.dV = Gate.maxV / Gate.points *2;    % V
Gate.sweep_dir = 'up';
Gate.sweepBF = 0;

Gate.points_av = 3*9000;        % points
Gate.settling_time = 0;      % ms
Gate.settling_time_autoranging = 200;      % ms
Gate.scanrate = 450000;       % Hz

Gate.output = 2;              % AO channel to sweep
Gate.process_number = 1;

Gate.clim_lin = [];%[-3e-7 3e-7 0 5e-7]; %[-1e-11 1e-11 0 5e-11];
Gate.clim_log = [];%[-13 -6 -10 -5]; % [-13 -11 -12 -9];

Bias.initV = 0.0;          % V
Bias.targetV = 0.001;            % V
Bias.endV = 0.0;            % V
Bias.ramp_rate = 0.0002;       % V/s
Bias.V_per_V = 0.01;           % V/V0

Bias.output = 1;
Bias.process_number = 3;
Bias.process = 'Fixed_AO';

Gate2 = Bias;
Gate2.initV = 0;      % V
Gate2.endV = 0;      % V
Gate2.minV = -2;      % V
Gate2.maxV = 2;      % V
Gate2.dV = 0.01;      % V
Gate2.sweep_dir = 'down';

Gate2.output = 3;      % fixed AO SG1
Gate2.V_per_V = 1;     % gain
Gate2.ramp_rate = 0.2;       % V/s

Gate_fixed.fixed_voltage = 'ADwin';
Gate_fixed.waiting_time = 0;     % s after setting Gate.setV  %%can this be implemented via Gate.settling_time?
Gate_fixed.output = [4 5 6 7 8];
Gate_fixed.targetV = [0 0 0 0 0];
Gate_fixed.initV = [0 0 0 0 0];
Gate_fixed.endV = [0 0 0 0 0];
Gate_fixed.V_per_V = [1 1 1 1 1];          % V/V0
Gate_fixed.ramp_rate = 0.4*ones(5,1);       % V/s
Gate_fixed.process_number = 3;

Save = 1;

%% Initialize 
Settings = Init(Settings);

%% Initialize ADwin
[Settings, Gate] = get_sweep_process(Settings, Gate);
Settings = Init_ADwin(Settings, Gate, Gate2);

%% generate Gate 2 vector
Gate2.startV = Gate2.initV;          % V
Gate2 = Generate_voltage_array(Settings, Gate2);

Gate.repeat = length(Gate2.voltage);

%% ramp up fixed gates
fprintf('%s - Setting fixed gates... ', datetime('now') )
Gate_fixed.startV = Gate_fixed.initV;
Gate_fixed.setV = Gate_fixed.targetV;

Gate_fixed = Apply_fixed_voltage(Settings, Gate_fixed);
fprintf('done\n')

fprintf('%s - Waiting fixed gates settling time... ', datetime('now') )
pause(Gate_fixed.waiting_time)
fprintf('done\n')

%% set Bias 
Bias.startV = Bias.initV;
Bias.setV = Bias.targetV;
Bias = Apply_fixed_voltage(Settings, Bias);


%% run measurement
for i = 1:Gate.repeat

    %% set gate 2 voltage
    Gate2.setV = Gate2.voltage(i);
    Gate2 = Apply_fixed_voltage(Settings, Gate2);
    Gate2.startV = Gate2.setV;          % V
    
    %% run gate sweep 
    fprintf('Running Gate sweep - %1.0f/%1.0f...', i, Gate.repeat)
    Gate.index = i;
    Gate = Run_sweep(Settings, Gate);
    
    %% get current and show plot
    Gate.x_axis = Gate2.voltage;
    Gate = Realtime_sweep3D(Settings, Gate, 'Stability');

    fprintf('done\n')
    
end

%% save data
if Save == 1
    Samplename = Settings.sample{1}; for i = 2:Settings.N_ADC; Samplename = [Samplename '-' Settings.sample{i}]; end
    filename = sprintf('%s/%s_%s_%s.mat', Settings.save_dir, Settings.filename, Samplename, Settings.type);
    save(filename)
end

%% set gate voltage back to start voltage
Bias.start = Bias.targetV;
Bias.setV = Bias.endV;
Bias = Apply_fixed_voltage(Settings, Bias);

%% set gate 2 back to start voltage
Gate2.startV = Gate2.setV;
Gate2.setV = Gate2.endV;
Apply_fixed_voltage(Settings, Gate2);


%% ramp down fixed gates
fprintf('%s - Setting fixed gates... ', datetime('now') )
Gate_fixed.startV = Gate_fixed.targetV;
Gate_fixed.setV = Gate_fixed.endV;

Gate_fixed = Apply_fixed_voltage(Settings, Gate_fixed);
fprintf('done\n')

%% plot surface plot
Gate = split_data_sweep(Settings, Gate);
close all hidden;
Surf_stability(Settings, Gate, Gate2, 'Dual gatesweep')
fig = findobj('Name','Dual gatesweep');
for i=1:Settings.N_ADC
    saveas(figure(i), sprintf('%s/%s_%s_%s_%s.png', Settings.save_dir, Settings.filename, Settings.sample{i}, Settings.type, Gate2.sweep_dir))
    saveas(figure(i), sprintf('%s/%s_%s_%s_%s.fig', Settings.save_dir, Settings.filename, Settings.sample{i}, Settings.type, Gate2.sweep_dir))
end
toc
% load train, sound(y, Fs)
