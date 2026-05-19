%% clear
clear
close all hidden
clc
tic
%E:\Samples\TEP_Dev4_Ch2_kinked_5AGNRs   E:\Samples\Superpads21\RT\Pre_transfer\VI'

%% Settings
Settings.save_dir = 'E:\Samples\HWH\WD2\test';           %E:\Samples\Zhang_SWNT06_17AGNRs\RT\Gatesweep'
Settings.sample = 'test'; %A2-GatetoGate G0b Test_100MOhm_50ohm_termination
Settings.ADC = {10000, 'off', 'off', 'off', 'off', 'off', 'off', 'off'};
Settings.auto = ''; %
Settings.ADC_gain = [0 0 0 0]; % 2^N
Settings.get_sample_T = 'Lakeshore325'; % {'', 'Lakeshore336', 'Lakeshore325', 'Oxford_ITC'}
Settings.type = 'VI';
Settings.T = 300;   %;

VI.VIgain = 1e-6;          % A/V gain
VI.startI = 0.0;            % A
VI.maxI = 1e-7;             % A
VI.points = 600;           %
VI.minI = -VI.maxI;         % V
VI.sweep_dir = 'up';
VI.repeat = 1;

VI.points_av = 9000;        % points
VI.settling_time = 1;      % ms
VI.settling_time_autoranging = 200;      % ms
VI.scanrate = 450000;       % Hz
VI.V_per_V = 1;

VI.output = 1;              % AO channel
VI.process_number = 1;

Gate.initV = 0;          % V
Gate.targetV = 0;            % V
Gate.endV = 0;            % V
Gate.ramp_rate = 1;       % V/s
Gate.waiting_time = 0;     % s after setting Gate.setV  %%can this be implemented via Gate.settling_time?
Gate.V_per_V = 10;          % V/V0
Gate.output = 2;            % AO channel

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
Gate_fixed.type = 'Gate_fixed';
Gate_fixed.process_number = 3;

%% define current vector
VI.dI = VI.maxI / VI.points *2;    % V
ramp_up = VI.startI:VI.dI:VI.maxI;
ramp_down = ramp_up(end):-VI.dI:VI.minI;
ramp_up2 = ramp_down(end):VI.dI:VI.startI;

VI.current_bias = [ramp_up ramp_down ramp_up2]';
VI.bias = VI.current_bias / VI.VIgain;
VI.NumBias = length(VI.bias);

%% Initialize
Settings = Init(Settings);

%% Initialize ADwin
[Settings, VI] = get_sweep_process(Settings, VI);
xzSettings = Init_ADwin(Settings, VI, Gate);

%% set gate voltage
Gate.startV = Gate.initV;
Gate.setV = Gate.targetV;

fprintf('%s - Ramping Gate to %1.2fV...', datetime('now'), Gate.setV)
Gate = Apply_fixed_voltage(Settings, Gate);
fprintf('done\n')

% wait after gate set
fprintf('Gate Settling...')
pause(Gate.waiting_time)
fprintf('done\n')

%% ramp up fixed gates
Gate_fixed.startV = Gate_fixed.initV;
Gate_fixed.setV = Gate_fixed.targetV;

fprintf('%s - Setting fixed gates... ', datetime('now') )
Gate_fixed = Apply_fixed_voltage(Settings, Gate_fixed);
fprintf('done\n')

fprintf('%s - Waiting fixed gates settling time... ', datetime('now') )
pause(Gate_fixed.waiting_time)
fprintf('done\n')

%% run measurement
Settings.nT = length(Settings.T);

for l = 1:Settings.nT

    % set T
    if ~isempty(regexp(Settings.get_sample_T, '','once'))
        fprintf('%s - Setting T - %01dK...', datetime('now'), Settings.T(l))
        Settings.T_controller.set_T_setpoint(1, Settings.T(l));
        fprintf('done\n')

        if l ~= 1
            fprintf('%s - Waiting T - %01dK...', datetime('now'), Settings.T(l))
            pause(900)
            fprintf('done\n')
        end

        Settings.T_sample = Settings.T_controller.get_temp(1);
    end

    for i = 1:VI.repeat

        %% run VI
        fprintf('Running V(I) - %1.0f/%1.0f...', i, VI.repeat)
        VI.index = i;
        VI = Run_sweep(Settings, VI);

        %% get current and show plot
        VI = Realtime_sweep(Settings, VI, Settings.type);
        fprintf('done\n')

    end

    %% save figure
    fig = findobj('Name', Settings.type);
    filename = sprintf('%s/%s_%s_%s', Settings.save_dir, Settings.filename, Settings.sample, Settings.type);
    saveas(fig, [filename '.png'])
    saveas(fig, [filename '.fig'])

    %% save data
    VI.voltage = VI.current;
    VI = rmfield(VI, 'current');
    Save_data(Settings, VI, Gate, [filename '.mat']);

end

%% set gate voltage back to start voltage
Gate.startV = Gate.targetV;
Gate.setV = Gate.endV;

fprintf('%s - Ramping Gate to %1.2fV...', datetime('now'), Gate.setV)
Gate = Apply_fixed_voltage(Settings, Gate);
fprintf('done\n')

%% ramp down fixed gates
Gate_fixed.startV = Gate_fixed.targetV;
Gate_fixed.setV = Gate_fixed.endV;

fprintf('%s - Setting fixed gates... ', datetime('now') )
Gate_fixed = Apply_fixed_voltage(Settings, Gate_fixed);
