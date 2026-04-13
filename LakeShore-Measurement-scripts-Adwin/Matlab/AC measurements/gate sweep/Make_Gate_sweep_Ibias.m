% This script runs a gatesweep with current bias for different bias voltages, frequencies, and temperatures.

%% clear
clear
close all hidden
clc

%% Settings
Settings.save_dir = 'E:\Samples\tatp\GrTEP_W2\300K\RVgs\';
Settings.sample = 'I1+_hi_V2+_lo_NL1_Vhi_BR2_Vlo'; %A2-GatetoGate G0b Test_100MOhm_50ohm_termination V2+_hi_V1+_lo_BR2_Vhi_NL1_Vlo
Settings.auto = ''; %FEMTO
Settings.ADC_gain = [0 0 0 0 0 0 0 0]; % 2^N
Settings.get_sample_T = 'Lakeshore325'; % {'', 'Lakeshore336', 'Lakeshore325', 'Oxford_ITC'}
Settings.type = 'Gate_sweep_Timetraces';
Settings.ADwin = 'GoldII'; % GoldII or ProII

Settings.Temperatures = [300]; %[105:-15:105];

Bias.initV = 0;
Bias.V_per_V = 1;
Bias.current = [0];              % A
Bias.ramp_rate_current = 100e-6;      % A/s
Bias.fixed_voltage = 'ADwin';
Bias.waiting_time = 0;          %sec

% Lockin 1 --> apply across device, measure current, DC current measured on AUX1
Lockin.dev1.sensitivity = 10;           % sensitivity (V). Use 10 for MFLI with no sensitivity set
Lockin.dev1.frequency = 80;           % Hz, use integers!
Lockin.dev1.harmonic = 1;           %
Lockin.dev1.timeconstant = 0.3;           % seconds
Lockin.dev1.amplitude_Ibias = 1e-7;           % amplitude current (A)
Lockin.dev1.ramp_rate = 1e-7;           % A / s
Lockin.dev1.VI_gain = 1e-6;               %  current source gain
Lockin.dev1.V_per_V = 1;               %  current source gain
Lockin.dev1.V_gain = 1;                  % voltage measurement gain
Lockin.dev1.model = 'ZI_MFLI';
Lockin.dev1.input_diff = 'A';
Lockin.dev1.input_range = 0.01;
Lockin.dev1.filter_order = 4;
Lockin.dev1.channels = {'x','y'};
Lockin.dev1.autoranging = 0; % 0 off; 1 on
Lockin.dev1.resync = 0;
Lockin.dev1.datarate = 3e3; % do not exceed 30e3!
Lockin.dev1.input_AC = 1;

Timetrace.wait_time = Get_lockin_waiting_period(Lockin.dev1.filter_order, 90) * Lockin.dev1.timeconstant;      % s

% ADwin
Timetrace.scanrate = 450000;       % Hz
Timetrace.points_av = 1 * Timetrace.scanrate / 50;        % points
Timetrace.settling_time = 0;      % ms
Timetrace.settling_time_autoranging = 0;      % ms
Timetrace.process_number = 2;
Timetrace.clim = [];

% ZI MFLI
Timetrace.N_channels = numel(Lockin.dev1.channels);
Timetrace.channels = Lockin.dev1.channels;
Timetrace.clockbase = 60e6;
Timetrace.clim = [];
Timetrace.model = Lockin.dev1.model;
Timetrace.datarate = Lockin.dev1.datarate;
Timetrace.lowpass = 0;              % optional low pass filter (0.01Hz) for ADWin signal
Timetrace.high_speed = 1;

Gate.initV = 0;
Gate.minV = -10;            % V
Gate.maxV = 20;            % V
Gate.points = 201;
Gate.ramp_rate = 0.5;       % V/s
Gate.waiting_time = 5;     % s after setting Gate.setV
Gate.V_per_V = 10;          % V/V0
Gate.sweep_dir = 'up';
Gate.fixed_voltage = 'ADwin';

Gate.output = 2;
Gate.process_number = 3;
Gate.process = 'Fixed_AO';

Bias.output = 1;
Bias.process_number = 3;
Bias.process = 'Fixed_AO';

Lockin.dev1.address = 'DEV6676'; % current

Gate_fixed.fixed_voltage = 'ADwin';
Gate_fixed.waiting_time = 0;     % s after setting Gate.setV
Gate_fixed.output = [3 4 5 6 7 8];
Gate_fixed.targetV = [0 0 0 0 0 0];
Gate_fixed.initV = [0 0 0 0 0 0];
Gate_fixed.endV = [0 0 0 0 0 0];
Gate_fixed.V_per_V = [1 1 1 1 1 1];          % V/V0
Gate_fixed.ramp_rate = 0.4*ones(6,1);       % V/s 0.4*ones(6,1)

%% get ADC gains for ADwin
Settings.ADC = {Lockin.dev1.V_gain};

%% Initialize
Settings = Init(Settings);

%% Initialize ADwin
[Settings, Timetrace] = get_readAI_process(Settings, Timetrace);
Settings = Init_ADwin(Settings, Timetrace, Gate);

%% Initialize Lockin
clear ziDAQ
ziDAQ('connect', 'localhost', 8004, 6);

Timetrace.N_devices = 1;

Lockin.device_names = fieldnames(Lockin);
for i = 1:Timetrace.N_devices
    Lockin.(Lockin.device_names{i}) = Init_lockin(Lockin.(Lockin.device_names{i}));
end

%% initialize DAQ
Timetrace = Init_lockin_ZI_DAQ(Timetrace, Lockin);

%% convert bias current to voltage
Bias.voltage = Bias.current / Lockin.dev1.VI_gain / Bias.V_per_V;
Bias.ramp_rate = Bias.ramp_rate_current / Lockin.dev1.VI_gain / Bias.V_per_V;

%% convert bias lockin current to voltage
Lockin.dev1.amplitude_rescaled = Lockin.dev1.amplitude_Ibias / Lockin.dev1.VI_gain / Lockin.dev1.V_per_V;
Lockin.dev1.ramp_rate_rescaled = Lockin.dev1.ramp_rate / Lockin.dev1.VI_gain / Lockin.dev1.V_per_V;

%% define bias and gate vector
Gate.startV = Gate.initV;          % V
Gate = Generate_voltage_array(Settings, Gate);

Bias.startV = Bias.initV;          % V

%% plot settings
Labels.titles.dV = 'DC voltage (V)';

Labels.titles.conductance = 'Conductance (A/V)' ;
Labels.component.conductance = 'X';

Labels.titles.resistance = 'Resistance (\Omega)' ;
Labels.component.resistance = 'X';

Labels.x_axis_label = 'Gate voltage V';
Labels.x_axis = Gate.voltage;

%% T dependence
for index = 1:length(Settings.Temperatures)

    %% define T controller
    if index ~= 1
        Settings = Init_T_controller(Settings);
        Settings.T_controller.set_T_setpoint(1, Temperatures(index));
        fprintf('%s - Setting temperature to %1.2f K...', datetime('now'), Temperatures(index))
        pause(20*60)
        fprintf('done\n')
    end

    %% set lockin bias
    fprintf('Ramping up AC voltage bias...')
    ramp_lockin(Lockin.dev1, 0, Lockin.dev1.amplitude_rescaled, Lockin.dev1.ramp_rate_rescaled);
    fprintf('done\n')

    %% ramp up fixed gates
    fprintf('%s - Setting fixed gates... ', datetime('now') )
    Gate_fixed.startV = Gate_fixed.initV;
    Gate_fixed.setV = Gate_fixed.targetV;

    Gate_fixed = Apply_fixed_voltage(Settings, Gate_fixed);
    fprintf('done\n')

    %%  frequency dependence
    for index2 = 1:length(Lockin.dev1.frequency)

        %% set dI/dV frequency
        Timetrace.runtime = Get_integer_multiple_periods(Lockin.dev1.frequency(index2), 50);
        Lockin.dev1.dev.set_frequency(Lockin.dev1.frequency(index2));
        fprintf('%s - Frequency to %1.2f Hz\n', datetime('now'), Lockin.dev1.frequency(index2))

        %% Init ADwin timetrace
        Timetrace = Init_timetrace_ADwin(Settings, Timetrace);

        %% Run measurement
        Timetrace.repeat = length(Bias.voltage);
        Timetrace.repeat2 = length(Gate.voltage);
        Timetrace = Define_arrays_stability_Ibias(Settings, Timetrace);

        %% resynchronize MFLI lockins
        if Lockin.dev1.resync
            Run_sync_ZI_lockins(Timetrace.mds, Timetrace.devices_string);
        end

        %% update figure name
        figure_name = sprintf('Gatesweep I bias AC - %01dK-%1.3fHz', Settings.Temperatures(index), Lockin.dev1.frequency(index2));

        %% Run for different bias voltage
        for i = 1:Timetrace.repeat

            %% set bias voltage
            fprintf('%s - Setting Vb = %1.2f...', datetime('now'), Bias.voltage(i) )
            Bias.setV = Bias.voltage(i);
            Bias = Apply_fixed_voltage(Settings, Bias);
            fprintf('done\n')

            fprintf('%s - Bias Settling time %1.2f sec...', datetime('now'), Bias.waiting_time)
            pause(Bias.waiting_time)
            fprintf('done\n')

            %% Make Gate sweep
            for j = 1:Timetrace.repeat2

                %% set gate voltage
                Gate.setV = Gate.voltage(j);
                Gate = Apply_fixed_voltage(Settings, Gate);

                %% autorange input
                if Lockin.dev1.autoranging == 1
                    for k = 1:Timetrace.N_devices
                        Lockin.(Lockin.device_names{k}).dev.autorange;
                    end
                end

                %% wait for lockin
                pause(Timetrace.wait_time);

                %% run Timetrace
                Timetrace.index = i;
                Timetrace.index2 = j;

                fprintf('%s - Running Timetrace : %01d /%01d...', datetime('now'), (i-1)*Timetrace.repeat2 + j , Timetrace.repeat * Timetrace.repeat2)
                Timetrace = Acquire_data_timetrace_ADwin_MFLI(Settings, Timetrace, Lockin);
                fprintf('done \n');

                %% Process data
                Timetrace = Process_data_stability_Ibias(Settings, Timetrace, Lockin);

                %% show plot
                Timetrace = Realtime_timetrace_1D(Settings, Timetrace, Labels, figure_name);

                %% prepare new cycle
                Gate.startV = Gate.setV;
            end

            %% prepare new cycle
            Bias.startV = Bias.setV;

        end

        %% clean up workspace
        Timetrace = rmfield(Timetrace,'data');
        Timetrace = rmfield(Timetrace,'time');
        Timetrace = rmfield(Timetrace,'handles');

        %% save data
        filename = sprintf('%s/%s_%s_%s-%01dK-%1.3fHz', Settings.save_dir, Settings.filename, Settings.sample, Settings.type, Settings.Temperatures(index), Lockin.dev1.frequency(index2));

        Save_data(Settings, Timetrace, Bias, Gate, Lockin, [filename '.mat']);

        %% save figure
        fig = findobj('Type', 'Figure', 'Name', figure_name);
        saveas(fig, [filename '.png'])
        saveas(fig, [filename '.fig'])

        %% set gate voltage back to zero
        Gate.startV = Gate.setV;
        Gate.setV = 0;
        Gate = Apply_fixed_voltage(Settings, Gate);

        %% set bias voltage back to zero
        Bias.startV = Bias.setV;
        Bias.setV = 0;
        Bias = Apply_fixed_voltage(Settings, Bias);

        %% ramp down lockin bias
        fprintf('%s - Ramping down AC current bias...', datetime('now'))
        ramp_lockin(Lockin.dev1, Lockin.dev1.amplitude_rescaled, 0, Lockin.dev1.ramp_rate_rescaled);
        fprintf('done\n')

    end
end

%% ramp down fixed gates
fprintf('%s - Setting fixed gates... ', datetime('now') )
Gate_fixed.startV = Gate_fixed.targetV;
Gate_fixed.setV = Gate_fixed.endV;

Gate_fixed = Apply_fixed_voltage(Settings, Gate_fixed);
fprintf('done\n')

%load train, sound(y,Fs)
%% reset gate if needed via reset_gate(Settings,Gate)