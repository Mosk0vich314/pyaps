% This script runs a gatesweep for different bias voltages, frequencies, and temperatures.

%% clear
clear
close all hidden
clc

%% Settings
Settings.save_dir = 'C:\Samples\20240123_Zhang_TBG_QD3_TR_re-measure\260mK\gatesweep_Tdep';
Settings.sample = 'D-R_0VDC_1mVAC_1000pts_300K'; %
Settings.auto = ''; %FEMTO
Settings.ADC_gain = [0 0 0 0 0 0 0 0]; % 2^N
Settings.get_sample_T = 'Oxford_ITC'; % {'', 'Lakeshore336', 'Lakeshore325', 'Oxford_ITC'}
Settings.type = 'Gate_sweep_Timetraces';
Settings.ADwin = 'GoldII'; % GoldII or ProII
Settings.res4p = 0;
Settings.second_der = 0; % second derivative, only possible in 2p

Settings.Temperatures = [01]; %[105:-15:105];

Bias.initV = 0;
Bias.V_per_V = 0.1;          % V/V0
Bias.voltage = 0;              % V
Bias.ramp_rate = 0.01;
Bias.fixed_voltage = 'ADwin';
Bias.waiting_time = 0;          %sec

% Lockin 1 --> apply across device, measure current, DC current measured on AUX1
Lockin.dev1.sensitivity = 10;           % sensitivity (V). Use 10 for MFLI with no sensitivity set
Lockin.dev1.frequency = 30;           % Hz, use integers!
Lockin.dev1.harmonic = 1;           %
Lockin.dev1.timeconstant = 0.1;           % seconds
Lockin.dev1.amplitude_Vbias = 1;           % amplitude bias oscillation for conductance measurement mV
Lockin.dev1.ramp_rate = 0.1;           % mV / s
Lockin.dev1.V_per_V = 0.001;
Lockin.dev1.IVgain = 1e6;               %  IV converter
Lockin.dev1.model = 'ZI_MFLI';
Lockin.dev1.input_diff = 'A';
Lockin.dev1.input_range = 0.3;
Lockin.dev1.filter_order = 4;
Lockin.dev1.channels = {'x','y'};
Lockin.dev1.autoranging = 0; % 0 off; 1 on
Lockin.dev1.resync = 0;
Lockin.dev1.datarate = 3e3; % do not exceed 30e3!
Lockin.dev1.input_AC = 1;

% Lockin 2 --> apply across device, measure 4p voltage
Lockin.dev2 = Lockin.dev1;
Lockin.dev2.input_diff = 'A';
Lockin.dev2.Vgain = 1;        %  V gain

Timetrace.wait_time = Get_lockin_waiting_period(Lockin.dev1.filter_order, 90) * Lockin.dev1.timeconstant;      % s

% ADwin
Timetrace.scanrate = 250000;       % Hz
Timetrace.points_av = Timetrace.scanrate / 50;        % points
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
Gate.minV = -8;            % V
Gate.maxV = 8;            % V
Gate.points = 1001;
Gate.ramp_rate = 0.5;       % V/s
Gate.waiting_time = 0;     % s after setting Gate.setV
Gate.V_per_V = 1;          % V/V0
Gate.sweep_dir = 'up';
Gate.fixed_voltage = 'ADwin';

Gate.output = 2;
Gate.process_number = 3;
Gate.process = 'Fixed_AO';

Bias.output = 1;
Bias.process_number = 3;
Bias.process = 'Fixed_AO';

Lockin.dev1.address = 'DEV7540'; % current
%%Lockin.dev2.address = 'DEV7540'; % 4p voltage

Gate_fixed.fixed_voltage = 'ADwin';
Gate_fixed.waiting_time = 0;     % s after setting Gate.setV
Gate_fixed.output = [3 4 5 6 7 8];
Gate_fixed.targetV = [0 0 0 0 0 0];
Gate_fixed.initV = [0 0 0 0 0 0];
Gate_fixed.endV = [0 0 0 0 0 0];
Gate_fixed.V_per_V = [1 1 1 1 1 1];          % V/V0
Gate_fixed.ramp_rate = 0.4*ones(6,1);       % V/s

%% get ADC gains for ADwin
Settings.ADC = {Lockin.dev1.IVgain,...
    Lockin.dev2.Vgain,...
    };

%% Initialize
Settings = Init(Settings);

%% Initialize ADwin
[Settings, Timetrace] = get_readAI_process(Settings, Timetrace);
Settings = Init_ADwin(Settings, Timetrace, Gate);

%% Initialize Lockin
clear ziDAQ
ziDAQ('connect', 'localhost', 8004, 6);

if Settings.res4p == 1 || Settings.second_der == 1
    Timetrace.N_devices = 2;
else
    Timetrace.N_devices = 1;
end

Lockin.device_names = fieldnames(Lockin);
for i = 1:Timetrace.N_devices
    Lockin.(Lockin.device_names{i}) = Init_lockin(Lockin.(Lockin.device_names{i}));
end

%% set up Lockin.dev2 for 4p measurement
if Settings.res4p == 1
    Lockin.dev2.dev.set_frequency(Lockin.dev1.frequency)
    Lockin.dev2.dev.set_harmonic(1)
end

%% set up Lockin.dev2 for second derivative on 2 omega
if Settings.second_der == 1
    Lockin.dev2.dev.set_frequency(Lockin.dev1.frequency)
    Lockin.dev2.dev.set_harmonic(2)
end

%% initialize DAQ
Timetrace = Init_lockin_ZI_DAQ(Timetrace, Lockin);

%% synchronize lockins
if Timetrace.N_devices == 2
    mydlg = warndlg('Go to LabOne and stop any existing MDS');
    waitfor(mydlg);

    [Timetrace.mds, Timetrace.devices_string] = Init_sync_ZI_lockins(Timetrace.device_list);
    Run_sync_ZI_lockins(Timetrace.mds, Timetrace.devices_string);

    % run phase sync for third lockin, instead of external reference
    Run_phasesync_ZI_lockins(Timetrace.mds, Timetrace.devices_string);
end

%% convert bias lockin voltage
Lockin.dev1.amplitude_rescaled = Lockin.dev1.amplitude_Vbias * 1e-3 / Lockin.dev1.V_per_V;
Lockin.dev1.ramp_rate_rescaled = Lockin.dev1.ramp_rate * 1e-3 / Lockin.dev1.V_per_V;

%% define bias and gate vector
Gate.startV = Gate.initV;          % V
Gate = Generate_voltage_array(Settings, Gate);

Bias.startV = Bias.initV;          % V

%% plot settings
Labels.titles.IV = 'DC current (A)';
Labels.titles.dIdV2p = 'dI/dV 2p (A/V)' ;
Labels.component.dIdV2p = 'X';

if Settings.second_der == 1
    Labels.titles.dI2d2V2p = 'dI^2/d^2V 2p (A/V)' ;
    Labels.component.dI2d2V2p = 'X';
end

if Settings.res4p == 1
    Labels.titles.dIdV4p = 'dI/dV 4p (A/V)' ;
    Labels.component.dIdV4p = 'X';
end

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

        % for 4p voltage, set frequency lockin
        if Settings.res4p == 1
            Lockin.dev2.dev.set_frequency(Lockin.dev1.frequency(index2));
        end

        fprintf('%s - Frequency to %1.2f Hz\n', datetime('now'), Lockin.dev1.frequency(index2))

        %% Init ADwin timetrace
        Timetrace = Init_timetrace_ADwin(Settings, Timetrace);

        %% Run measurement
        Timetrace.repeat = length(Bias.voltage);
        Timetrace.repeat2 = length(Gate.voltage);
        Timetrace = Define_arrays_stability(Settings, Timetrace);

        %% resynchronize MFLI lockins
        if Lockin.dev1.resync
            Run_sync_ZI_lockins(Timetrace.mds, Timetrace.devices_string);
        end

        %% update figure name
        figure_name = sprintf('Gatesweep V bias AC - %01dK-%1.3fHz', Settings.Temperatures(index), Lockin.dev1.frequency(index2));

        %% Run for different bias voltage
        for i = 1:Timetrace.repeat

            %% set bias voltage
            fprintf('%s - Setting Vb = %1.3f...', datetime('now'), Bias.voltage(i) )
            Bias.setV = Bias.voltage(i);
            Bias = Apply_fixed_voltage(Settings, Bias);
            fprintf('done\n')

            fprintf('%s - Bias Settling time %1.2f sec...', datetime('now'), Bias.waiting_time)
            pause(Bias.waiting_time)
            fprintf('done\n')

            %% Make Gate sweep
            for j = 1:Timetrace.repeat2

                %% set gate voltage
                %                     fprintf('%s - Setting Vg = %1.2f...', datetime('now'), Gate.voltage(j) )
                Gate.setV = Gate.voltage(j);
                Gate = Apply_fixed_voltage(Settings, Gate);
                %                     fprintf('done\n')

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
                Timetrace = Process_data_stability(Settings, Timetrace, Lockin);

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
        fprintf('%s - Ramping down AC voltage bias...', datetime('now'))
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