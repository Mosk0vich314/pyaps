% This script runs a TEP gatesweep for different bias voltages, heater frequencies, heater amplitudes and temperatures.
% Settings.thermo sets whether the thermovoltage is obtained from thermocurrent + dI/dV (2p or 4p) or a direct thermovoltage measurement

%% clear
clear
close all hidden
clc

%% Settings
Settings.save_dir = 'C:\Samples\Fred\CNTPEMfab23\C66\bottomLeft\thirdCooldown\base\TEP\afterFix\heaterDep\gateSweepsTEP';         
Settings.sample = 'SD'; %A2-GatetoGate G0b Test_100MOhm_50ohm_termination
Settings.auto = ''; %FEMTO
Settings.ADC_gain = [0 0 0 0 ]; % 2^N
Settings.get_sample_T = 'Oxford_ITC'; % {'', 'Lakeshore336', 'Lakeshore325', 'Oxford_ITC'}
Settings.type = 'Gate_sweep_TEP_Timetraces';
Settings.ADwin = 'GoldII'; % GoldII or ProII
Settings.res4p = 0;
Settings.thermo = 'Current';

% Settings.Heaters = linspace(0, 0.1, 11);
Settings.Heaters = linspace(0, 0.1,11); 

Settings.Temperatures = [0.1]; %[105:-15:105];

Bias.initV = 0;
Bias.V_per_V = 0.1;          % V/V0
Bias.voltage = 0.0005;              % V
Bias.ramp_rate = 0.001;
Bias.fixed_voltage = 'ADwin';
Bias.waiting_time = 0;          %sec

% Lockin 1 --> apply on heater
Lockin.dev1.sensitivity = 10;           % sensitivity (V). Use 10 for MFLI with no sensitivity set
Lockin.dev1.harmonic = [1 2 4 6];           %
Lockin.dev1.demod_oscillator = 1;           %
Lockin.dev1.frequency_array = [32];

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

% Lockin 2 --> apply across device, measure conductance, DC current measured on AUX1
Lockin.dev2 = Lockin.dev1;
Lockin.dev2.sensitivity = 10;           % sensitivity (V). Use 10 for MFLI with no sensitivity set
Lockin.dev2.frequency = 187;           % Hz
Lockin.dev2.harmonic = 1;           %
Lockin.dev2.amplitude_Vbias = 0.1;           % amplitude bias oscillation for conductance measurement mV
Lockin.dev2.ramp_rate = 0.1;           % mV / s
Lockin.dev2.V_per_V = 0.001;
Lockin.dev2.model = 'ZI_MFLI';
Lockin.dev2.input_diff = 'A';
Lockin.dev1.input_range = 1;
Lockin.dev2.Vgain = 1;

% Lockin 3 --> measure thermovoltage / 4p voltage across device
Lockin.dev3 = Lockin.dev1;
Lockin.dev3.sensitivity = 10;           % sensitivity (V). Use 10 for MFLI with no sensitivity set
Lockin.dev3.Vgain = 1;               %  IV converter
Lockin.dev3.input_diff = 'A';

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

Gate.initV = 0;
Gate.maxV = 4;              % V
Gate.minV = -4;         % V
Gate.points = 3001;
Gate.ramp_rate = 0.1;       % V/s
Gate.waiting_time = 0.0;     % s after setting Gate.setV
Gate.V_per_V = 1;          % V/V0
Gate.sweep_dir = 'up';
Gate.fixed_voltage = 'ADwin';

Gate.output = 2;
Gate.process_number = 3;
Gate.process = 'Fixed_AO';

Bias.output = 1;
Bias.process_number = 3;
Bias.process = 'Fixed_AO';

Lockin.dev1.address = 'DEV7540'; % heater - thermocurrent
Lockin.dev2.address = 'DEV7535'; % bias
Lockin.dev3.address = 'DEV6628'; % thermovoltage

%% get lockin wait time
Timetrace.wait_time = Get_lockin_waiting_period(Lockin.dev1.filter_order, Lockin.dev1.accuracy) * Lockin.dev1.timeconstant;      % s

%% get ADC gains for ADwin
Settings.ADC = {Lockin.dev1.IVgain,...
    Lockin.dev3.Vgain
    };
%% Initialize
Settings = Init(Settings);

%% Initialize Lockin
clear ziDAQ
ziDAQ('connect', 'localhost', 8004, 6);

if Settings.res4p == 1 || strcmpi(Settings.thermo, 'voltage')
    Timetrace.N_devices = 3;
else
    Timetrace.N_devices = 2;
end

Lockin.device_names = fieldnames(Lockin);
Lockin.dev1.frequency = Lockin.dev1.frequency_array(1) ;           % Hz

for i = 1:Timetrace.N_devices
    Lockin.(Lockin.device_names{i}) = Init_lockin(Lockin.(Lockin.device_names{i}));
end

%% Initialize ADwin
[Settings, Timetrace] = get_readAI_process(Settings, Timetrace);
Settings = Init_ADwin(Settings, Timetrace, Gate);

if Timetrace.N_devices == 3
    Settings.N_ADC = 2;
else
    Settings.N_ADC = 1;
end

%% for 4p measurement, set lockin 3
if Settings.res4p == 1
    Lockin.dev3.dev.set_frequency(Lockin.dev2.frequency)
    Lockin.dev3.dev.set_harmonic(1)
end

%% for thermovoltage measurement, set lockin 3
if strcmpi(Settings.thermo, 'voltage')
    Lockin.dev3.dev.set_frequency(Lockin.dev1.frequency_array(1))
    Lockin.dev3.dev.set_harmonic(2)
end

%% initialize DAQ
Timetrace = Init_lockin_ZI_DAQ(Timetrace, Lockin);

%% synchronize lockins
if Timetrace.N_devices == 3
    mydlg = warndlg('Go to LabOne and stop any existing MDS');
    waitfor(mydlg);
end

[mds, Timetrace.devices_string] = Init_sync_ZI_lockins(Timetrace.device_list);
Run_sync_ZI_lockins(mds, Timetrace.devices_string);

% run phase sync for third lockin, instead of external reference
if Timetrace.N_devices == 3
    Run_phasesync_ZI_lockins(mds, Timetrace.devices_string);
end

%% convert bias lockin voltage
Lockin.dev2.amplitude_rescaled = Lockin.dev2.amplitude_Vbias * 1e-3 / Lockin.dev2.V_per_V;
Lockin.dev2.ramp_rate_rescaled = Lockin.dev2.ramp_rate * 1e-3 / Lockin.dev2.V_per_V;

%% define bias and gate vector
Gate.startV = Gate.initV;          % V
Gate = Generate_voltage_array(Settings, Gate);

Bias.startV = Bias.initV;          % V

Timetrace.repeat = length(Bias.voltage);
Timetrace.repeat2 = length(Gate.voltage);

%% plot settings
switch lower(Settings.thermo)
    case 'current'

        Labels.titles.IV = 'DC current (A)';

        Labels.titles.dIdV2p = 'dI/dV 2p - X(A/V)' ;
        Labels.component.dIdV2p = 'X';

        if Settings.res4p == 1
            Labels.titles.dIdV4p = 'dI/dV 4p - X (A/V)' ;
            Labels.component.dIdV4p = 'X';
        end

        Labels.titles.thermocurrent = 'Thermocurrent - Y (A)';
        Labels.component.thermocurrent = 'Y';

        Labels.titles.thermovoltage2p = 'Thermovoltage 2p (V)';
        Labels.component.thermovoltage2p = 'R';

        if Settings.res4p == 1
            Labels.titles.thermovoltage4p = 'Thermovoltage 4p (V)';
            Labels.component.thermovoltage4p = 'R';
        end

    case 'voltage'

        Labels.titles.thermovoltage = 'Thermovoltage - Y (V)';
        Labels.component.thermovoltage = 'Y';

end

Labels.x_axis_label = 'Gate voltage V';
Labels.x_axis = Gate.voltage;

%% T dependence
for index = 1:length(Settings.Temperatures)

    %% define T controller
    if index ~= 1
        Settings = Init_T_controller(Settings);
        Settings.T_controller.set_T_setpoint(1, Settings.Temperatures(index));
        fprintf('%s - Setting temperature to %1.2f K...', datetime('now'), Settings.Temperatures(index))
        pause(20*60)
        fprintf('done\n')
    end

    %% heater dependence
    for index2 = 1:length(Settings.Heaters)

        fprintf('%s - Heater current %1.4f mA\n', datetime('now'), Settings.Heaters(index2))

        %% convert heater current to lockin voltage
        Lockin.dev1.amplitude_current = Settings.Heaters(index2);
        Lockin.dev1.amplitude_rescaled = Lockin.dev1.amplitude_current * 1e-3 / Lockin.dev1.VI_gain;
        Lockin.dev1.ramp_rate_rescaled = Lockin.dev1.ramp_rate * 1e-3 / Lockin.dev1.VI_gain;

        %%  frequency dependence
        for index3 = 1:length(Lockin.dev1.frequency_array)
            
            %% update timeconstant
            Lockin.dev1.timeconstant = 10 / min(Lockin.dev1.frequency_array(index3)*2, Lockin.dev2.frequency);
            Timetrace.wait_time = Get_lockin_waiting_period(Lockin.dev1.filter_order, Lockin.dev1.accuracy) * Lockin.dev1.timeconstant;      % s

            Lockin.dev1.dev.set_timeconstant(Lockin.dev1.timeconstant);
            Lockin.dev2.dev.set_timeconstant(Lockin.dev1.timeconstant);

            %% set heater frequency
            Timetrace.actual_runtime = Get_integer_multiple_periods(Lockin.dev1.frequency_array(index3), Lockin.dev2.frequency);
            Timetrace.actual_runtime = 0.2;

            fprintf('Runtime is set to %1.3f ms\n', Timetrace.actual_runtime* 1e3);
            Lockin.dev1.dev.set_frequency(Lockin.dev1.frequency_array(index3));

            % for direct thermovoltage, set frequency lockin
            if strcmpi(Settings.thermo, 'voltage')
                Lockin.dev3.dev.set_frequency(Lockin.dev1.frequency_array(index3));
            end

            fprintf('%s - Heater frequency to %1.2f Hz\n', datetime('now'), Lockin.dev1.frequency_array(index3))

            %% set lockin bias
            fprintf('%s - Ramping up AC voltage bias...', datetime('now'))
            ramp_lockin(Lockin.dev2, 0, Lockin.dev2.amplitude_rescaled, Lockin.dev2.ramp_rate_rescaled);
            fprintf('done\n')

            %% set lockin current
            fprintf('%s - Ramping up AC heater current...', datetime('now'))
            ramp_lockin(Lockin.dev1, 0, Lockin.dev1.amplitude_rescaled, Lockin.dev1.ramp_rate_rescaled);
            fprintf('done\n')

            %% Define empty arrays
            Timetrace = Define_arrays_TEP(Settings, Timetrace);

            %% resynchronize MFLI lockins
            if Lockin.dev1.resync
                Run_sync_ZI_lockins(mds, Timetrace.devices_string)
                Run_phasesync_ZI_lockins(mds, Timetrace.devices_string);
            end

            %% Init ADwin timetrace (has to be done at every frequencies
            Timetrace.runtime = Timetrace.actual_runtime  + 100;
            Timetrace = Init_timetrace_ADwin(Settings, Timetrace);
            Timetrace.runtime = Timetrace.actual_runtime;

            %% update figure name
            figure_name = sprintf('TEP %s - %1.4fmA-%01dK-%1.3fHz', Settings.thermo, Settings.Heaters(index2), Settings.Temperatures(index), Lockin.dev1.frequency_array(index3));

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
                    if Lockin.dev1.autoranging
                        MFLI_autorange(Lockin, Timetrace.N_devices);
                    end

                    %% wait for lockin
                    if j==1
                        pause(10*Timetrace.wait_time);
                    else
                        pause(Timetrace.wait_time);
                    end

                    %% run Timetrace
                    Timetrace.index = i;
                    Timetrace.index2 = j;

                    fprintf('%s - Running Timetrace : %01d /%01d...', datetime('now'), (i-1)*Timetrace.repeat2 + j , Timetrace.repeat * Timetrace.repeat2)
                    Timetrace = Acquire_data_timetrace_ADwin_MFLI(Settings, Timetrace, Lockin);
                    fprintf('done \n');

                    %% Process data
                    Timetrace = Process_data_TEP(Settings, Timetrace, Lockin);

                    %% show plot
                    Timetrace = Realtime_timetrace_1D(Settings, Timetrace, Labels, figure_name);

                    %% prepare new cycle
                    Gate.startV = Gate.setV;
                end
                Bias.startV = Bias.setV;
            end

            %% clean workspace
            Timetrace = rmfield(Timetrace,'data');
            Timetrace = rmfield(Timetrace,'time');
            Timetrace = rmfield(Timetrace,'handles');

            %% save data
            filename = sprintf('%s/%s_%s_%s_%s-%1.4fmA-%01dK-%1.3fHz', Settings.save_dir, Settings.filename, Settings.sample, Settings.type, Settings.thermo, Settings.Heaters(index2), Settings.Temperatures(index), Lockin.dev1.frequency_array(index3));

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

            %% ramp down lockin current
            fprintf('%s - Ramping down AC heater current ...', datetime('now'))
            ramp_lockin(Lockin.dev1, Lockin.dev1.amplitude_rescaled, 0, Lockin.dev1.ramp_rate_rescaled);
            fprintf('done\n')

            %% ramp down lockin bias
            fprintf('%s - Ramping down AC voltage bias...', datetime('now'))
            ramp_lockin(Lockin.dev2, Lockin.dev2.amplitude_rescaled, 0, Lockin.dev2.ramp_rate_rescaled);
            fprintf('done\n')
            pause(5);
            close all hidden
        end
        % pause(5);
    end
end

%load train, sound(y,Fs)
%% reset gate if needed via reset_gate(Settings,Gate)