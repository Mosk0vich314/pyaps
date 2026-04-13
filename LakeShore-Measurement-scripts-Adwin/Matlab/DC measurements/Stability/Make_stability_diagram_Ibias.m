%% clear
clear
close all hidden
clc
tic
%E:\Samples\TEP_Dev4_Ch2_kinked_5AGNRs   E:\Samples\Superpads21\RT\Pre_transfer\VI'

%% Settings
Settings.save_dir = 'I:\HelioxVL\Zhang\20220810_Zhang_TBG_QD1_D1\255mK\stability_VI_DC';           %E:\Samples\20220713_Zhang_TBG_Dou1\RT\Gatesweep_Ibias
Settings.sample = {'Top-Device_C1-C3_BG-sweep_Ibias-10nA'};
Settings.auto = ''; % FEMTO
Settings.ADC_gain = [0 0 0 0]; % 2^N
Settings.get_sample_T = 'Oxford_ITC'; % {'', 'Lakeshore336', 'Lakeshore325', 'Oxford_ITC'}
Settings.type = 'Stability Ibias';
%Settings.comment = '1_Film_2_Device'
Settings.ADwin = 'GoldII'; % GoldII or ProII

VI.VIgain = 1e-7;          % A/V gain
VI.startI = 0.0;            % A
VI.maxI = 100e-9;             % A
VI.points = 101;           %
VI.minI = -VI.maxI;         % V
VI.sweep_dir = 'up';
VI.Vgain = 1000;

VI.points_av = 9000;        % points
VI.settling_time = 0;      % ms
VI.settling_time_autoranging = 200;      % ms
VI.scanrate = 450000;       % Hz
VI.V_per_V = 1;

VI.output = 1;              % AO channel
VI.process_number = 1;

VI.clim_lin = [];%[-3e-7 3e-7 0 5e-7]; %[-1e-11 1e-11 0 5e-11];
VI.clim_log = [];%[-13 -6 -10 -5]; % [-13 -11 -12 -9];

Gate.initV = 0.0;          % V
Gate.minV = -17;            % V
Gate.maxV = 17;            % V
Gate.endV = 0.0;            % V
Gate.dV = 0.2;
Gate.ramp_rate = 1;       % V/s
Gate.waiting_time = 2;     % s after setting Gate.setV  %%can this be implemented via Gate.settling_time?
Gate.V_per_V = 10;          % V/V0
Gate.sweep_dir = 'down';

Gate.output = 2;
Gate.process_number = 3;
Gate.process = 'Fixed_AO';

Gate_fixed.fixed_voltage = 'ADwin';
Gate_fixed.waiting_time = 0;     % s after setting Gate.setV  %%can this be implemented via Gate.settling_time?
Gate_fixed.output = [1 2 3 4 5 6 7 8];
Gate_fixed.targetV = [0 0 0 0 0 0 0 0];
Gate_fixed.initV = [0 0 0 0 0 0 0 0];
Gate_fixed.endV = [0 0 0 0 0 0 0 0];
Gate_fixed.V_per_V = [5 5 5 5 5 5 5 5];          % V/V0
Gate_fixed.ramp_rate = 0.4*ones(8,1);       % V/s
Gate_fixed.process_number = 3;

Save = 1;

%% define current vector
VI.dI = VI.maxI / VI.points *2;    % V
ramp_up = VI.startI:VI.dI:VI.maxI;
ramp_down = ramp_up(end):-VI.dI:VI.minI;
ramp_up2 = ramp_down(end):VI.dI:VI.startI;

VI.current_bias = [ramp_up ramp_down ramp_up2]';
VI.bias = VI.current_bias / VI.VIgain;
VI.NumBias = length(VI.bias);

VI.maxV = VI.maxI / VI.VIgain;
VI.startV = VI.startI / VI.VIgain;
VI.minV = VI.minI / VI.VIgain;
VI.dV = VI.bias(2) - VI.bias(1);

%% Initialize 
Settings = Init(Settings);

%% Initialize ADwin
Settings.ADC = {VI.Vgain, 'off', 'off', 'off', 'off', 'off', 'off', 'off'};    
[Settings, VI] = get_sweep_process(Settings, VI);
Settings = Init_ADwin(Settings, VI, Gate);

%% define gate voltage
Gate.startV = Gate.initV;          % V
Gate = Generate_voltage_array(Settings, Gate);

VI.repeat = length(Gate.voltage);


%% ramp up fixed gates
fprintf('%s - Setting fixed gates... ', datetime('now') )
Gate_fixed.startV = Gate_fixed.initV;
Gate_fixed.setV = Gate_fixed.targetV;

Gate_fixed = Apply_fixed_voltage(Settings, Gate_fixed);
fprintf('done\n')

fprintf('%s - Waiting fixed gates settling time... ', datetime('now') )
pause(Gate_fixed.waiting_time)
fprintf('done\n')


%% run measurement
for i = 1:VI.repeat
        
    %% set gate voltage
    Gate.setV = Gate.voltage(i);
    Gate = Apply_fixed_voltage(Settings, Gate);
    
    % wait after gate set
    fprintf('Gate Settling\n')
    pause(Gate.waiting_time)
    if i == 1
        pause(3 * Gate.waiting_time)
    end
    
    %% run VI
    fprintf('Running V(I) - %1.0f/%1.0f...', i, VI.repeat)
    VI.index = i;
    VI = Run_sweep(Settings, VI);
    
    %% get current and show plot
    VI.x_axis = Gate.voltage;
    VI = Realtime_sweep3D(Settings, VI, 'Stability diagram current bias');
    fprintf('done\n')
    
    Gate.startV = Gate.setV;
    
end

%% save data
if Save == 1
    Samplename = Settings.sample{1}; for i = 2:Settings.N_ADC; Samplename = [Samplename '-' Settings.sample{i}]; end
    filename = sprintf('%s/%s_%s_%s.mat', Settings.save_dir, Settings.filename, Samplename, Settings.type);
    Save_data(Settings, VI, Gate, filename);
    %     Save_data_dat(Settings, IV, Gate, filename, 'current');
end

%% plot surface plot
VI = split_data_sweep(Settings, VI);
close all hidden;
Surf_stability(Settings, VI, Gate, 'Stability diagram current bias')
fig = findobj('Name','Stability diagram current bias');
for i = 1:Settings.N_ADC
    saveas(figure(i), sprintf('%s/%s_%s_%s_%s.png', Settings.save_dir, Settings.filename, Settings.sample{i}, Settings.type, Gate.sweep_dir))
    saveas(figure(i), sprintf('%s/%s_%s_%s_%s.fig', Settings.save_dir, Settings.filename, Settings.sample{i}, Settings.type, Gate.sweep_dir))
end

%% set gate voltage back to start voltage
Gate.startV = Gate.setV;
Gate.setV = Gate.endV;
Gate = Apply_fixed_voltage(Settings, Gate);

%% ramp down fixed gates
fprintf('%s - Setting fixed gates... ', datetime('now') )
Gate_fixed.startV = Gate_fixed.targetV;
Gate_fixed.setV = Gate_fixed.endV;

Gate_fixed = Apply_fixed_voltage(Settings, Gate_fixed);
fprintf('done\n')
