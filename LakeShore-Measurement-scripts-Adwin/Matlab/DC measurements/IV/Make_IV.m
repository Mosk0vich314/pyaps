%% clear
clear
close all hidden
clc
tic

%% Settings
Settings.save_dir = 'C:\Samples\test';
Settings.sample = '1Gohm'; %A2-GatetoGate G0b
Settings.ADC = {1e7, 'off', 'off','off', 'off', 'off', 'off', 'off'};
Settings.auto = ''; % FEMTO
Settings.ADC_gain = [0 0 0 0 0 0 0 0]; % 2^N
Settings.get_sample_T = ''; % {'', 'Lakeshore336', 'Lakeshore325', 'Oxford_ITC'}
Settings.type = 'IV';
Settings.ADwin = 'GoldII'; % GoldII or ProII
Settings.res4p = 0;     % 4 point measurement
Settings.T = [10];   %;

IV.V_per_V = 1;          % V/V0
IV.startV = 0;            % V
IV.maxV = 0.5;
IV.minV = -IV.maxV;        % V
IV.points = 501;           % what happens for >   4000 points?? IV.minV = -IV.maxV;         % V
IV.dV = IV.maxV / IV.points *2;    % V
IV.sweep_dir = 'up';
IV.maxI =0;            % A

IV.repeat = 1;
IV.scanrate = 50000;       % Hz
IV.points_av = 1* IV.scanrate / 50;        % points
IV.settling_time = 0;      % ms
IV.settling_time_autoranging = 200;      % ms

IV.output = 1;              % AO channel
IV.process_number = 1;

Gate.initV = 0;          % V
Gate.targetV = 0;            % V
Gate.endV = 0;            % V
Gate.ramp_rate = 1;       % V/s
Gate.waiting_time = 0;     % s after setting Gate.setV  %%can this be implemented via Gate.settling_time?
Gate.V_per_V = 1;          % V/V0
Gate.output = 2;            % AO channel
Gate.process_number = 3;
Gate.process = 'Fixed_AO';

Gate_fixed.fixed_voltage = 'ADwin';
Gate_fixed.waiting_time = 0;     % s after setting Gate.setV  %%can this be implemented via Gate.settling_time?
Gate_fixed.output = [3 4 5 6 7 8];
Gate_fixed.targetV = [0 0 0 0 0 0];
Gate_fixed.initV = [ 0 0 0 0 0 0];
Gate_fixed.endV = [0 0 0 0 0 0];
Gate_fixed.V_per_V = [1 1 1 1 1 1];          % V/V0
Gate_fixed.ramp_rate = 0.4*ones(6,1);       % V/s
Gate_fixed.process_number = 3;

%% Initialize
Settings = Init(Settings);

%% Initialize ADwin
[Settings, IV] = get_sweep_process(Settings, IV);
Settings = Init_ADwin(Settings, IV, Gate);

%% ramp up fixed gates
Gate_fixed.startV = Gate_fixed.initV;
Gate_fixed.setV = Gate_fixed.targetV;

fprintf('%s - Setting fixed gates... ', datetime('now') )
Gate_fixed = Apply_fixed_voltage(Settings, Gate_fixed);
fprintf('done\n')

fprintf('%s - Waiting fixed gates settling time... ', datetime('now') )
pause(Gate_fixed.waiting_time)
fprintf('done\n')

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

%% run measurement
Settings.nT = length(Settings.T);

for l = 1:Settings.nT

    % set T
    if ~isempty(Settings.get_sample_T)
        fprintf('%s - Setting T - %01dK...', datetime('now'), Settings.T(l))
        Settings.T_controller.set_T_setpoint(1, Settings.T(l));
        fprintf('done\n')

        if l ~= 1
            fprintf('%s - Waiting T - %01dK...', datetime('now'), Settings.T(l))
            pause(10)
            fprintf('done\n')
        end

        Settings.T_sample = Settings.T_controller.get_temp(1);
    end

    %% run measurement
    for i = 1:IV.repeat

        %% run IV
        fprintf('%s - Running I(V) - %1.0f/%1.0f...', datetime('now'), i, IV.repeat)
        IV.index = i;
        IV = Run_sweep(Settings, IV);

        %% get current and show plot
        IV = Realtime_sweep(Settings, IV, Settings.type);

        fprintf('done\n')

    end

    %% save figure
    fig = findobj('Name', Settings.type);
    filename = sprintf('%s/%s_%s_%s_%1.0fK', Settings.save_dir, Settings.filename, Settings.sample, Settings.type, Settings.T(l));
    saveas(fig, [filename '.png'])
    saveas(fig, [filename '.fig'])

    %% save data
    Save_data(Settings, IV, Gate, [filename '.mat']);

end

%% set gate voltage back to end voltage
Gate.startV = Gate.targetV;          % V
Gate.setV = Gate.endV;            % V

fprintf('%s - Ramping Gate to %1.2fV...', datetime('now'), Gate.setV)
Gate = Apply_fixed_voltage(Settings, Gate);
fprintf('done\n')

%% ramp down fixed gates
Gate_fixed.startV = Gate_fixed.targetV;
Gate_fixed.setV = Gate_fixed.endV;

fprintf('%s - Setting fixed gates... ', datetime('now') )
Gate_fixed = Apply_fixed_voltage(Settings, Gate_fixed);
fprintf('done\n')

%% plot surface plot
if IV.repeat > 1
    IV = split_data_sweep(Settings, IV);
    Surf_sweep(Settings, IV, 'Surface plot')
    filename = sprintf('%s/%s_%s_%s.png', Settings.save_dir, Settings.filename, Settings.sample, Settings.type);
    fig = findobj('Type', 'Figure', 'Name', 'Surface plot');
    saveas(fig, filename);
end

%% plot density plot
if IV.repeat > 1
    Density_sweep(Settings, IV, 'Density plot')
    filename = sprintf('%s/%s_%s_density_%s.png', Settings.save_dir, Settings.filename, Settings.sample, Settings.type);
    fig = findobj('Type', 'Figure', 'Name', 'Density plot');
    saveas(fig, filename);
end
toc
pause(1)

% close all
% load train, sound(y,Fs)


