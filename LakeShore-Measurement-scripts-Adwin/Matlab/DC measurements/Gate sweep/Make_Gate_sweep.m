%% clear
clear
close all hidden
clc
tic

%% Settings
Settings.save_dir = 'C:\Samples\Fred\TEP_DEV4_CHIP1/';          %Lujun\XAT13\RT\IV
Settings.sample = 'G0t'; %A2-GatetoGate G0b
Settings.ADC = {1e9, 1, 'off', 'off', 'off'};    % 1e6 fixed gain % auto = linear with auto ranging; off = disabled; log = logarithmic (not yet implemented)
Settings.auto = 'FEMTO'; % FEMTO
Settings.ADC_gain = [0 0 0 0 0 0 0 0]; % 2^N
Settings.get_sample_T = 'Lakeshore336'; % {'Lakeshore336', 'Oxford_ITC'}
Settings.type = 'Gatesweep';
Settings.ADwin = 'GoldII'; % GoldII or ProII
Settings.res4p = 1;     % 4 point measurement
Settings.T = 300;   %;

Gate.V_per_V = 1;          % V/V0
Gate.startV = 0.0;            % V
Gate.maxV = 5;              % V
Gate.minV = -5;         % V
Gate.dV = 0.01;              % V

Gate.scanrate = 400000;       % Hz
Gate.points_av = 1 * Gate.scanrate / 50;        % points
Gate.settling_time = 0;      % ms
Gate.settling_time_autoranging = 300;      % ms
Gate.sweep_dir = 'up';

Gate.output = 2;              % AO channel
Gate.process_number = 1;

Bias.initV = 0;          % V
Bias.minV = 0.01;            % V
Bias.maxV = 0.01;            % V
Bias.dV = 0.01;            % V
Bias.endV = 0.0;            % V
Bias.ramp_rate = 0.1;       % V/s
Bias.V_per_V = 0.1;          % V/V0

Bias.output = 1;
Bias.process_number = 3;
Bias.process = 'Fixed_AO';

Gate_fixed.fixed_voltage = 'ADwin';
Gate_fixed.waiting_time = 0;     % s after setting Gate.setV  %%can this be implemented via Gate.settling_time?
Gate_fixed.output = [3 4 5 6 7 8];
Gate_fixed.targetV = [0 0 0 0 0 0];
Gate_fixed.initV = [0 0 0 0 0 0];
Gate_fixed.endV = [0 0 0 0 0 0];
Gate_fixed.V_per_V = [1 1 1 1 1 1];          % V/V0
Gate_fixed.ramp_rate = 0.4*ones(6,1);       % V/s
Gate_fixed.process_number = 3;

%% Initialize
Settings = Init(Settings);

%% Initialize ADwin and piezo
[Settings, Gate] = get_sweep_process(Settings, Gate);
Settings = Init_ADwin(Settings, Gate, Bias);

%% generate bias vector
Bias.voltage = Bias.minV:Bias.dV:Bias.maxV;
Bias.N_voltage = length(Bias.voltage);

Bias.startV = Bias.initV;          % V
Gate.repeat = Bias.N_voltage;

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

    for i = 1:Gate.repeat

        %% set bias voltage
        Bias.setV = Bias.voltage(i);
        fprintf('%s - Ramping bias...', datetime('now'))
        Bias = Apply_fixed_voltage(Settings, Bias);
        fprintf('done\n')
        Bias.startV = Bias.setV;          % V
        pause(2)

        %% run IV % actually run gate-sweep
        fprintf('%s - Running gate sweep - %1.0f/%1.0f...', datetime('now'), i, Gate.repeat)
        Gate.index = i;
        Gate = Run_sweep(Settings, Gate);

        %% get current and show plot
        Gate = Realtime_sweep(Settings, Gate, Settings.type);

        fprintf('done\n')

    end

    %% save figure
    fig = findobj('Name', Settings.type);
    filename = sprintf('%s/%s_%s_%s', Settings.save_dir, Settings.filename, Settings.sample, Settings.type);
    saveas(fig, [filename '.png'])
    saveas(fig, [filename '.fig'])

    %% save data
    Save_data(Settings, Gate, Bias, [filename '.mat']);

end

%% set gate voltage back to start voltage
Bias.setV = Bias.endV;
Bias = Apply_fixed_voltage(Settings, Bias);

%% ramp down fixed gates
fprintf('%s - Setting fixed gates... ', datetime('now') )
Gate_fixed.startV = Gate_fixed.targetV;
Gate_fixed.setV = Gate_fixed.endV;

Gate_fixed = Apply_fixed_voltage(Settings, Gate_fixed);
fprintf('done\n')

%% plot surface plot
if Gate.repeat > 1
    Gate = split_data_sweep(Settings, Gate);
    Surf_sweep(Settings, Gate, 'Surface plot')
end

%% plot resistance plot
if Gate.repeat > 1
    Gate = split_data_sweep(Settings, Gate);
    Surf_sweep(Settings, Gate, 'Surface plot')
end
