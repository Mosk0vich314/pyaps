%% clear
clear
close all hidden
clc
instrreset
tic

%% Settings
Settings.save_dir = 'I:\HelioxVL\Zhang\20220810_Zhang_TBG_QD1_D1\255mK\gatesweep_DC';           %E:\Samples\20220713_Zhang_TBG_Dou1\255mK\Gatesweep_Ibias_DC
Settings.sample = 'Top-Device_C1-C3_BG-sweep_Ibias-5nA'; %A2-GatetoGate G0b
Settings.ADC = {1000, 'off', 'off', 'off', 'off', 'off', 'off', 'off'};
Settings.auto = ''; % FEMTO
Settings.ADC_gain = [0 0 0 0]; % 2^N
Settings.get_sample_T = 'Oxford_ITC'; % {'', 'Lakeshore336', 'Lakeshore325', 'Oxford_ITC'}
Settings.type = 'Gatesweep I bias';
Settings.ADwin = 'GoldII'; % GoldII or ProII
Settings.T = 300;   %;

Gate.V_per_V = 10;          % V/V0
Gate.startV = 0.0;            % V
Gate.maxV = 17;              % V
Gate.minV = -17;         % V
Gate.dV = 0.01;              % V

Gate.points_av = 2*9000;        % points
Gate.settling_time = 0;      % ms
Gate.settling_time_autoranging = 200;      % ms
Gate.scanrate = 450000;       % Hz
Gate.sweep_dir = 'up';

Gate.output = 2;              % AO channel
Gate.process_number = 1;

Current.initI = 0;          % V
Current.minI = 5e-9;            % V
Current.maxI = 5e-9;            % V
Current.dI = 5e-6;            % V
Current.endI = 0.0;            % V
Current.ramp_rate_current = 1e-9;       % A/s
Current.VIgain = 1e-7;          % A/V 10Mou
Current.V_per_V = 1;          % V/V0

Current.output = 1;
Current.process_number = 3;
Current.process = 'Fixed_AO';

Gate_fixed.fixed_voltage = 'OptoDAC';
Gate_fixed.waiting_time = 0;     % s after setting Gate.setV  %%can this be implemented via Gate.settling_time?
Gate_fixed.output = [1 2 3 4 5 6 7 8];
Gate_fixed.targetV = [0 0 0 0 0 0 0 0];
Gate_fixed.initV = [0 0 0 0 0 0 0 0];
Gate_fixed.endV = [0 0 0 0 0 0 0 0];
Gate_fixed.V_per_V = [5 5 5 5 5 5 5 5];          % V/V0
Gate_fixed.ramp_rate = 0.2*ones(8,1);       % V/s
Gate_fixed.type = 'Gate_fixed';

%% Initialize
Settings = Init(Settings);

%% Initialize ADwin
[Settings, Gate] = get_sweep_process(Settings, Gate);
Settings = Init_ADwin(Settings, Gate, Current);

%% generate bias vector
Current.current = Current.minI:Current.dI:Current.maxI;
Current.voltage = Current.current / Current.VIgain;
Current.ramp_rate = Current.ramp_rate_current / Current.VIgain;

Current.startV = Current.initI / Current.VIgain;          % V
Gate.repeat = length(Current.current);

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

        %% set current bias
        Current.setV = Current.voltage(i);

        fprintf('%s - Ramping current to %1.2fA...', datetime('now'), Current.current(i))
        Current = Apply_fixed_voltage(Settings, Current);
        fprintf('done\n')

        Current.startV = Current.setV;          % V
        Gate.current_bias = Current.current(i);
        pause(2)

        %% run gate-sweep
        fprintf('%s - Running Gate sweep - %1.0f/%1.0f...', datetime('now'), i, Gate.repeat)
        Gate.index = i;
        Gate = Run_sweep(Settings, Gate);

        %% get resistance and show plot
        Gate = Realtime_sweep(Settings, Gate, Settings.type);
        Gate.voltage = Gate.current;
        Gate = rmfield(Gate, 'current');
        fprintf('done\n')

    end

    %% save figure
    fig = findobj('Name', Settings.type);
    filename = sprintf('%s/%s_%s_%s', Settings.save_dir, Settings.filename, Settings.sample, Settings.type);
    saveas(fig, [filename '.png'])
    saveas(fig, [filename '.fig'])

    %% save data
    Save_data(Settings, Gate, Current, [filename '.mat']);

end

%% set gate voltage back to start voltage
Current.setV = Current.endI / Current.VIgain;
Current = Apply_fixed_voltage(Settings, Current);

%% ramp down fixed gates
Gate_fixed.startV = Gate_fixed.targetV;
Gate_fixed.setV = Gate_fixed.endV;

fprintf('%s - Setting fixed gates... ', datetime('now') )
Gate_fixed = Apply_fixed_voltage(Settings, Gate_fixed);
fprintf('done\n')