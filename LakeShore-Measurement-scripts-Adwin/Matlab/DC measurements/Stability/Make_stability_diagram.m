%% clear
clear
close all hidden
clc
tic

%% Settings
Settings.save_dir = 'C:\Samples\Fred\CNTPEMfab23\C66\bottomLeft\secondCooldown\base\DC\stabilities';         
Settings.sample = {'SD'};
Settings.ADC = {1e7, 'off', 'off', 'off', 'off', 'off', 'off', 'off'};    % 1e6 fixed gain % auto = linear with auto ranging; off = disabled; log = logarithmic (not yet implemented)
Settings.auto = ''; % FEMTO
Settings.ADC_gain = [0 0 0 0]; % 2^N
Settings.get_sample_T = ''; % {'', 'Lakeshore336', 'Lakeshore325', 'Oxford_ITC'}
Settings.type = 'Stability';
Settings.ADwin = 'GoldII'; % GoldII or ProII
Settings.res4p = 0;     % 4 point measurement
Settings.T = 0.1;   %;

IV.V_per_V = 0.01;          % V/V0
IV.startV = 0.0;            % V
IV.maxV = 0.02;              % V
IV.points = 301;
IV.minV = -IV.maxV;         % V
IV.dV = IV.maxV / IV.points *2;    % V
IV.maxI = 0;

IV.scanrate = 450000;       % Hz
IV.points_av = 1 * IV.scanrate / 50;        % points
IV.settling_time = 0;      % ms
IV.settling_time_autoranging = 200;      % ms

IV.output = 1;              % AO channel
IV.process_number = 1;
IV.sweep_dir = 'up';

IV.clim_lin = [];%[-3e-7 3e-7 0 5e-7]; %[-1e-11 1e-11 0 5e-11];
IV.clim_log = [];%[-13 -6 -10 -5]; % [-13 -11 -12 -9];

Gate.initV = 0.0;          % V
Gate.minV = -4;            % V
Gate.maxV = 0;           % V
Gate.endV = 0.0;            % V
Gate.points = 1000;
Gate.ramp_rate = 0.1;       % V/s
Gate.waiting_time = 1;     % s after setting Gate.setV  %%can this be implemented via Gate.settling_time?
Gate.V_per_V = 1;        %V/V0
Gate.sweep_dir = 'up';

Gate.output = 2;
Gate.process = 'Fixed_AO';
Gate.process_number = 3;

Gate_fixed.fixed_voltage = 'ADwin';
Gate_fixed.waiting_time = 0;     % s after setting Gate.setV  %%can this be implemented via Gate.settling_time?
Gate_fixed.output = [3 4 5 6 7 8];
Gate_fixed.targetV = [0 0 0 0 0 0];
Gate_fixed.initV = [0 0 0 0 0 0];
Gate_fixed.endV = [0 0 0 0 0 0];
Gate_fixed.V_per_V = [1 1 1 1 1 1];          % V/V0
Gate_fixed.ramp_rate = 0.4*ones(6,1);       % V/s

%% Initialize
Settings = Init(Settings);

%% Initialize ADwin
[Settings, IV] = get_sweep_process(Settings, IV);
Settings = Init_ADwin(Settings, IV, Gate);

%% make gate vector
Gate.startV = Gate.initV;          % V
Gate = Generate_voltage_array(Settings, Gate);

IV.repeat = length(Gate.voltage);

%% ramp up fixed gates
fprintf('%s - Setting fixed gates... ', datetime('now') )
Gate_fixed.startV = Gate_fixed.initV;
Gate_fixed.setV = Gate_fixed.targetV;

Gate_fixed = Apply_fixed_voltage(Settings, Gate_fixed);
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

    for i = 1:IV.repeat

        %% set gate voltage
        Gate.setV = Gate.voltage(i);
        Gate = Apply_fixed_voltage(Settings, Gate);

        % wait after gate set
        fprintf('Gate Settling\n')
        pause(Gate.waiting_time)
        if i == 1
            pause(2 * Gate.waiting_time)
        end

        %% run IV
        fprintf('Running I(V)  No. : %01d /%01d\n Vg = %1.2f', i, IV.repeat, Gate.voltage(i) )
        IV.index = i;
        IV = Run_sweep(Settings, IV);

        % get current and show plot
        IV.x_axis = Gate.voltage;
        IV = Realtime_sweep3D(Settings, IV, Settings.type);
        fprintf('done\n')

        %% prepare for next round
        Gate.startV = Gate.setV;

    end

    %% save figure
    for i = 1:numel(Settings.sample)
        fig = IV.handles(i).fig;
        filename = sprintf('%s/%s_%s_%s_%1.0fK', Settings.save_dir, Settings.filename, Settings.sample{i}, Settings.type, Settings.T(l));

        saveas(fig, [filename '.png'])
        saveas(fig, [filename '.fig'])
    end
    
    %% save data
    Samplename = Settings.sample{1}; for i = 2:numel(Settings.sample); Samplename = [Samplename '-' Settings.sample{i}]; end
    filename = sprintf('%s/%s_%s_%s_%1.0fK.mat', Settings.save_dir, Settings.filename, Samplename, Settings.type, Settings.T(l));
    
    IV = rmfield(IV,'handles');

    Settings = Save_data(Settings, IV, Gate, filename);

    %% set gate voltage back to start voltage
    Gate.startV = Gate.setV;
    Gate.setV = Gate.endV;
    Gate = Apply_fixed_voltage(Settings, Gate);
end

%% ramp down fixed gates
fprintf('%s - Setting fixed gates... ', datetime('now') )
Gate_fixed.startV = Gate_fixed.targetV;
Gate_fixed.setV = Gate_fixed.endV;

Gate_fixed = Apply_fixed_voltage(Settings, Gate_fixed);
fprintf('done\n')

%% plot surface plot
% IV = split_data_sweep(Settings, IV);
% close all hidden;
% Surf_stability(Settings, IV, Gate, Settings.type)
% fig = findobj('Name', Settings.type);
% for i = 1:numel(Settings.sample)
%     saveas(figure(i), sprintf('%s/%s_%s_%s_%s.png', Settings.save_dir, Settings.filename, Settings.sample{i}, Settings.type, Gate.sweep_dir))
%     saveas(figure(i), sprintf('%s/%s_%s_%s_%s.fig', Settings.save_dir, Settings.filename, Settings.sample{i}, Settings.type, Gate.sweep_dir))
% end

% toc
% load train, sound(y,Fs)
%% reset gate if needed via reset_gate(Settings,Gate)