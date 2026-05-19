%% clear
clear
close all hidden
clc
tic

%% Settings
Settings.save_dir = 'E:\Samples\20210927_Zhang_SWNT-9AGNR_LG_Heliox\255mK\Triplegate_sweep';
Settings.sample = {'E14-30mV'};
Settings.ADC = {1e9, 'off', 'off', 'off', 'off', 'off', 'off', 'off'};
Settings.auto = 'FEMTO'; % FEMTO
Settings.ADC_gain = [0 0 0 0]; % 2^N
Settings.get_sample_T = 'Oxford_ITC'; % {'', 'Lakeshore336', 'Lakeshore325', 'Oxford_ITC'}
Settings.type = 'DualGatesweep';
Settings.IVcutoff = 150; % Hz
Settings.ADwin = 'GoldII'; % GoldII or ProII
Settings.res4p = 0;     % 4 point measurement
Settings.T = 5;   %;

Gate.V_per_V = 1;          % V/V0
Gate.startV = 0.0;            % V
Gate.maxV = 5;              % V
Gate.minV = -5;         % V
Gate.points = 500;
Gate.dV = Gate.maxV / Gate.points *2;    % V
Gate.sweep_dir = 'up';

Gate.points_av = 9000;        % points
Gate.settling_time = 0;      % ms
Gate.settling_time_autoranging = 200;      % ms
Gate.scanrate = 450000;       % Hz

Gate.output = 4;              % AO channel to sweep
Gate.process_number = 1;

Gate.clim_lin = [];%[-3e-7 3e-7 0 5e-7]; %[-1e-11 1e-11 0 5e-11];
Gate.clim_log = [];%[-13 -6 -10 -5]; % [-13 -11 -12 -9];

Bias.initV = 0.0;          % V
Bias.targetV = 0.03;            % V
Bias.endV = 0.0;            % V
Bias.ramp_rate = 0.01;       % V/s
Bias.V_per_V = 0.1;          % V/V0

Bias.output = 1;
Bias.process_number = 3;
Bias.process = 'Fixed_AO';

Gate2 = Bias;
Gate3 = Bias;

Gate2.initV = 0;      % V
Gate2.endV = 0;      % V
Gate2.minV = -5;      % V
Gate2.maxV = 5;      % V
Gate2.dV = 0.1;      % V
Gate2.ramp_rate = 1;

Gate3.initV = 0;      % V
Gate3.endV = 0;      % V
Gate3.minV = -5;      % V
Gate3.maxV = 5;      % V
Gate3.dV = 0.1;      % V
Gate3.ramp_rate = 1;

Gate2.output = 2;      % fixed AO SG1
Gate3.output = 3;      % fixed AO SG2

Gate2.V_per_V = 1;     % gain
Gate3.V_per_V = 1;      % gain

Gate2.ramp_rate = 0.5;       % V/s
Gate3.ramp_rate = 0.5;       % V/s


Gate_fixed.fixed_voltage = 'ADwin';
Gate_fixed.waiting_time = 0;     % s after setting Gate.setV  %%can this be implemented via Gate.settling_time?
Gate_fixed.output = [3 4 5 6 7 8];
Gate_fixed.targetV = [0 0 0 0 0 0];
Gate_fixed.initV = [0 0 0 0 0 0];
Gate_fixed.endV = [0 0 0 0 0 0];
Gate_fixed.V_per_V = [1 1 1 1 1 1];          % V/V0
Gate_fixed.ramp_rate = 0.4*ones(6,1);       % V/s
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

%% generate Gate 3 vector
Gate3.startV = Gate3.initV;          % V
Gate3 = Generate_voltage_array(Settings, Gate3);
Gate.repeat2 = length(Gate3.voltage);

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
counter = 1;
for i = 1:Gate.repeat2
    for j = 1:Gate.repeat
        
        %% set gate 2 voltage
        Gate2.setV = Gate2.voltage(j);
        Gate2 = Apply_fixed_voltage(Settings, Gate2);
        Gate2.startV = Gate2.setV;          % V
        
        %% set gate 3 voltage
        Gate3.setV = Gate3.voltage(i);
        Gate3 = Apply_fixed_voltage(Settings, Gate3);
        Gate3.startV = Gate3.setV;          % V
        
        %% run gate sweep
        fprintf('Running Gate sweep - %1.0f/%1.0f...', counter, Gate.repeat * Gate.repeat2)
        Gate.index = j;
        Gate.index2 = i;
        Gate = Run_sweep(Settings, Gate);
        
        %% get current and show plot
        Gate.x_axis = Gate2.voltage;
        Gate = Realtime_sweep_tripleGate(Settings, Gate, 'Stability');
        
        fprintf('done \n')

        %% increase counter
        counter = counter + 1;
    end
end

%% save data
if Save == 1
    Samplename = Settings.sample{1}; for i = 2:Settings.N_ADC; Samplename = [Samplename '-' Settings.sample{i}]; end
    filename = sprintf('%s/%s_%s_%s.mat', Settings.save_dir, Settings.filename, Samplename, Settings.type);
    save(filename)
 end

%% set bias voltage back to start voltage
Bias.initV = Bias.targetV;
Bias.setV = Bias.endV;
Bias = Apply_fixed_voltage(Settings, Bias);

%% set gate 2 back to start voltage
Gate2.startV = Gate2.setV;
Gate2.setV = Gate2.endV;
Apply_fixed_voltage(Settings, Gate2);

%% set gate 3 back to start voltage
Gate3.startV = Gate3.setV;
Gate3.setV = Gate3.endV;
Apply_fixed_voltage(Settings, Gate3);

toc
%load train, sound(y,Fs)


%% ramp down fixed gates
fprintf('%s - Setting fixed gates... ', datetime('now') )
Gate_fixed.startV = Gate_fixed.targetV;
Gate_fixed.setV = Gate_fixed.endV;

Gate_fixed = Apply_fixed_voltage(Settings, Gate_fixed);
fprintf('done\n')

