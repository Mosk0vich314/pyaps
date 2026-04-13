% This script runs a TEP gatesweep for different resistor box values, heater frequencies, heater amplitudes and temperatures.
% Settings.thermo sets whether the thermovoltage is obtained from thermocurrent + dI/dV (2p or 4p) or a direct thermovoltage measurement

%% clear
clear
close all hidden
clc

%% Settings
Settings.save_dir = 'C:\Samples\Fred\CNTPEMfab23\C66\bottomLeft\secondCooldown\heat_engine_output';
Settings.sample = 'SD'; %A2-GatetoGate G0b Test_100MOhm_50ohm_termination
Settings.auto = ''; %FEMTO
Settings.ADC_gain = [0 0 0 0 ]; % 2^N
Settings.get_sample_T = 'Oxford_ITC'; % {'', 'Lakeshore336', 'Lakeshore325', 'Oxford_ITC'}
Settings.type = 'Gate_sweep_TEP_Timetraces';
Settings.ADwin = 'GoldII'; % GoldII or ProII
Settings.res4p = 0;
Settings.thermo = 'Current';

% Settings.Heaters = linspace(0, 0.1, 11);
Settings.Heaters = 0.03;
Settings.Temperatures = [4:2:10 15:5:20 30:10:80]; %[105:-15:105];

% Lockin 1 --> apply on heater
Lockin.dev1.sensitivity = 10;           % sensitivity (V). Use 10 for MFLI with no sensitivity set
Lockin.dev1.frequency = [40];           % Hz
Lockin.dev1.harmonic = [1 2 4 6];           %
Lockin.dev1.demod_oscillator = 1;           % select which oscillator input to use for each demodulator

Lockin.dev1.timeconstant = 0.03;           % seconds
Lockin.dev1.VI_gain = 1e-4;             % A / V of current source
Lockin.dev1.ramp_rate = 0.1;            % heater amplitude ramp rate mA/s
Lockin.dev1.IVgain = 1e7;               %  IV converter
Lockin.dev1.model = 'ZI_MFLI';
Lockin.dev1.input_diff = 'A';
Lockin.dev1.input_range = 1;
Lockin.dev1.filter_order = 4;
Lockin.dev1.channels = {'x','y'};
Lockin.dev1.autoranging = 0;
Lockin.dev1.resync = 0;
Lockin.dev1.datarate = 3e3; % do not exceed 30e3!
Lockin.dev1.input_AC = 0;
Lockin.dev1.accuracy = 90;

Timetrace.wait_time = Get_lockin_waiting_period(Lockin.dev1.filter_order, Lockin.dev1.accuracy) * Lockin.dev1.timeconstant;      % s

% ADwin
Timetrace.scanrate = 450000;       % Hz
Timetrace.points_av = 1000;        % points
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
Timetrace.runtime = 0.06;

Gate.initV = 0;
Gate.maxV = 4;              % V
Gate.minV = 1;         % V
Gate.points = 1501;
Gate.ramp_rate = 0.1;       % V/s
Gate.waiting_time = 0.0;     % s after setting Gate.setV
Gate.V_per_V = 1;          % V/V0
Gate.sweep_dir = 'up';
Gate.fixed_voltage = 'ADwin';

Gate.output = 2;
Gate.process_number = 3;
Gate.process = 'Fixed_AO';

Lockin.dev1.address = 'DEV7540'; % heater - thermocurrent

Switchbox.address = 'COM14';
% Switchbox.resistance_values = 10.^linspace(2,9,8);
Switchbox.resistance_values = [225, 1.22e3, 3.52e3, 4.51e3, 11.2e3, 14.5e3, 26.6e3, 36.5e3, 61.8e3, 83.9e3,...
                136e3, 183e3, 304e3, 404e3, 513e3, 733e3, 873e3, 1.20e6, 1.41e6, 1.88e6,  2.20e6, 2.88e6,...
                3.38e6, 4.38e6, 5.08e6, 6.58e6, 7.69e6, 9.89e6, 11.3e6, 14.6e6, 19.9e6, 24.6e6, 36.0e6,...
                46.1e6, 71.6e6, 93.2e6, 150e6, 197e6, 393e6, 497e6, 1.17e9, 1.47e9];

Switchbox.resistance_values = Switchbox.resistance_values(1:4:end);

%% get ADC gains for ADwin
Settings.ADC = {Lockin.dev1.IVgain};

%% Initialize
Settings = Init(Settings);

%% Initialize Lockin
clear ziDAQ
ziDAQ('connect', 'localhost', 8004, 6);

Timetrace.N_devices = 1;

Lockin.device_names = fieldnames(Lockin);
for i = 1:Timetrace.N_devices
    Lockin.(Lockin.device_names{i}) = Init_lockin(Lockin.(Lockin.device_names{i}));
end

%% Initialize ADwin
[Settings, Timetrace] = get_readAI_process(Settings, Timetrace);
Settings = Init_ADwin(Settings, Timetrace, Gate);

Settings.N_ADC = 1;

%% initialize DAQ
Timetrace = Init_lockin_ZI_DAQ(Timetrace, Lockin);

%% define bias and gate vector
Gate.startV = Gate.initV;          % V
Gate = Generate_voltage_array(Settings, Gate);

%% plot settings
Labels.titles.thermocurrent = 'Thermocurrent - Y (A)';
Labels.component.thermocurrent = 'Y';

Labels.x_axis_label = 'Gate voltage V';
Labels.x_axis = Gate.voltage;

%% Init switchbox
Switchbox.device = IVVI_USB_switch_box(Switchbox.address);
Switchbox.N_resistors = numel(Switchbox.resistance_values);
Switchbox.set_values = zeros(Switchbox.N_resistors, 1);

%% T dependence
for index = 1:length(Settings.Temperatures)

    %% define T controller
    if index ~= 1
        Settings = Init_T_controller(Settings);
        Settings.T_controller.set_T_setpoint(1, Settings.Temperatures(index));
        fprintf('%s - Setting temperature to %1.2f K...', datetime('now'), Settings.Temperatures(index))
        pause(5*60)
        fprintf('done\n')
    end

    %% get temperature sample
    Settings.T_sample(index) = Settings.T_controller.get_temp(1);

    %% heater dependence
    for index2 = 1:length(Settings.Heaters)

        fprintf('%s - Heater current %1.4f mA\n', datetime('now'), Settings.Heaters(index2))

        %% convert heater current to lockin voltage
        Lockin.dev1.amplitude_current = Settings.Heaters(index2);
        Lockin.dev1.amplitude_rescaled = Lockin.dev1.amplitude_current * 1e-3 / Lockin.dev1.VI_gain;
        Lockin.dev1.ramp_rate_rescaled = Lockin.dev1.ramp_rate * 1e-3 / Lockin.dev1.VI_gain;

        %%  frequency dependence
        for index3 = 1:length(Lockin.dev1.frequency)

            %% set heater frequency
            fprintf('Runtime is set to %1.3f ms\n', Timetrace.runtime* 1e3);
            Lockin.dev1.dev.set_frequency(Lockin.dev1.frequency(index3));

            fprintf('%s - Heater frequency to %1.2f Hz\n', datetime('now'), Lockin.dev1.frequency(index3))

            %% set lockin current
            fprintf('%s - Ramping up AC heater current...', datetime('now'))
            ramp_lockin(Lockin.dev1, 0, Lockin.dev1.amplitude_rescaled, Lockin.dev1.ramp_rate_rescaled);
            fprintf('done\n')

            %% Run measurement
            Timetrace.repeat = Switchbox.N_resistors;
            Timetrace.repeat2 = length(Gate.voltage);
            Timetrace = Define_arrays_TEP(Settings, Timetrace);

            %% Init ADwin timetrace (has to be done at every frequencies
            Timetrace = Init_timetrace_ADwin(Settings, Timetrace);

            %% update figure name
            figure_name = sprintf('TEP %s - %1.4fmA-%01dK-%1.3fHz', Settings.thermo, Settings.Heaters(index2), Settings.Temperatures(index), Lockin.dev1.frequency(index3));

            %% Run for different load resistors
            for i = 1:Timetrace.repeat

                %% set resistor box
                Switchbox.set_values(i) = set_IVVI_switchbox(Switchbox, i);
                % Switchbox.set_values(i) = Switchbox.device.set_resistance_Ohm(Switchbox.resistance_values(i));

                fprintf('%s - Resistor box set to %1.2e Ohm...', datetime('now'), Switchbox.set_values(i))
                pause(0.2)
                fprintf('done\n')

                %% Make Gate sweep
                for j = 1:Timetrace.repeat2

                    %% set gate voltage
                    Gate.setV = Gate.voltage(j);
                    Gate = Apply_fixed_voltage(Settings, Gate);

                    pause(Gate.waiting_time)

                    %% autorange input
                    if Lockin.dev1.autoranging
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
                    Timetrace = Process_data_TEP_heat_engine(Settings, Timetrace, Lockin);

                    %% show plot
                    Timetrace = Realtime_timetrace_1D(Settings, Timetrace, Labels, figure_name);

                    %% prepare new cycle
                    Gate.startV = Gate.setV;
                end
            end

            %% clean workspace
            Timetrace = rmfield(Timetrace,'data');
            Timetrace = rmfield(Timetrace,'time');
            Timetrace = rmfield(Timetrace,'handles');

            %% save data
            filename = sprintf('%s/%s_%s_%s_%s-%1.4fmA-%1.2fK-%1.3fHz', Settings.save_dir, Settings.filename, Settings.sample, Settings.type, Settings.thermo, Settings.Heaters(index2), Settings.Temperatures(index), Lockin.dev1.frequency(index3));

            Save_data(Settings, Timetrace, Switchbox, Gate, Lockin, [filename '.mat']);

            %% save figure
            fig = findobj('Type', 'Figure', 'Name', figure_name);
            saveas(fig, [filename '.png'])
            saveas(fig, [filename '.fig'])

            %% set gate voltage back to zero
            Gate.startV = Gate.setV;
            Gate.setV = 0;
            Gate = Apply_fixed_voltage(Settings, Gate);

            %% ramp down lockin current
            fprintf('%s - Ramping down AC heater current ...', datetime('now'))
            ramp_lockin(Lockin.dev1, Lockin.dev1.amplitude_rescaled, 0, Lockin.dev1.ramp_rate_rescaled);
            fprintf('done\n')

        end
    end

    close all

end

%% put temperature back to base
Settings.T_controller.set_T_setpoint(1, 0.1);

%load train, sound(y,Fs)
%% reset gate if needed via reset_gate(Settings,Gate)









