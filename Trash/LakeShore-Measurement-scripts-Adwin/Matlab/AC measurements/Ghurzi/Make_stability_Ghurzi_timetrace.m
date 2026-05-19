%% clear
clear
close all hidden
clc
tic

%% Settings
Settings.save_dir = 'C:\Samples\Test';
Settings.sample = 'test'; %A2-GatetoGate G0b Test_100MOhm_50ohm_termination
Settings.auto = ''; %FEMTO
Settings.ADC_gain = [0 0 0 0 0 0 0 0]; % 2^N
Settings.get_sample_T = 'Lakeshore336'; % {'', 'Lakeshore336', 'Lakeshore325', 'Oxford_ITC'}
Settings.type = 'Ghurzi_Timetraces';
Settings.ADwin = 'ProII'; % GoldII or ProII

Settings.Temperatures = [5]; %[105:-15:105];

VI.initI = 0;
VI.V_per_V = 1;          % V/V0
VI.maxI = 1e-4;              % A
VI.points = 11;
VI.minI = -VI.maxI;         % V
VI.ramp_rate_current = 1e-4;           % A/s
VI.VIgain = 1e-4;
VI.fixed_voltage = 'ADwin';
VI.waiting_time = 1;    % sec, wait after applying first bias point

% Lockin 1 --> apply across sample
Lockin.dev1.sensitivity = 10;           % sensitivity (V). Use 10 for MFLI with no sensitivity set
Lockin.dev1.frequency = 80;           % Hz, use integers!
Lockin.dev1.harmonic = 1;           %
Lockin.dev1.timeconstant = 0.5;           % seconds
Lockin.dev1.amplitude_Ibias = 1e-6;           % amplitude current (A)
Lockin.dev1.ramp_rate = 1e-4;           % A / s
Lockin.dev1.VI_gain = 1e-4;               %  current source gain
Lockin.dev1.V_per_V = 0.01;               %  current source gain
Lockin.dev1.V_gain = 1;                  % voltage measurement gain
Lockin.dev1.model = 'ZI_MFLI';
Lockin.dev1.input_diff = 'A';
Lockin.dev1.input_range = 0.3;
Lockin.dev1.filter_order = 4;
Lockin.dev1.channels = {'x','y'};
Lockin.dev1.autoranging = 0; % 0 off; 1 on
Lockin.dev1.resync = 0;
Lockin.dev1.datarate = 3e3; % do not exceed 30e3!
Lockin.dev1.input_AC = 1;

% Timetrace.runtime = 50 / (Lockin.dev1.frequency);
Timetrace.runtime = Get_integer_multiple_periods(Lockin.dev1.frequency, 50);
Timetrace.wait_time = Get_lockin_waiting_period(Lockin.dev1.filter_order, 90) * Lockin.dev1.timeconstant;      % s

% ADwin
Timetrace.scanrate = 500000;       % Hz
Timetrace.points_av = 10000;        % points
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
Gate.minV = -1;            % V
Gate.maxV = 1;            % V
Gate.points = 5;
Gate.ramp_rate = 1;       % V/s
Gate.waiting_time = 0;     % s after setting Gate.setV
Gate.V_per_V = 1;          % V/V0
Gate.sweep_dir = 'up';
Gate.fixed_voltage = 'ADwin';

Gate.output = 2;
Gate.process_number = 3;
Gate.process = 'Fixed_AO';

VI.output = 1;
VI.process_number = 3;
VI.process = 'Fixed_AO';

Lockin.dev1.address = 'DEV6628'; % dI/dV

Gate_fixed.fixed_voltage = 'ADwin';
Gate_fixed.waiting_time = 0;     % s after setting Gate.setV  %%can this be implemented via Gate.settling_time?
Gate_fixed.output = [3 4 5 6 7 8];
Gate_fixed.targetV = [0 0 0 0 0 0];
Gate_fixed.initV = [0 0 0 0 0 0];
Gate_fixed.endV = [0 0 0 0 0 0];
Gate_fixed.V_per_V = [1 1 1 1 1 1];          % V/V0
Gate_fixed.ramp_rate = 0.4*ones(6,1);       % V/s

%% get ADC gains
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

%% Init ADwin timetrace
Timetrace = Init_timetrace_ADwin(Settings, Timetrace);

%% convert bias lockin current to voltage
Lockin.dev1.amplitude_rescaled = Lockin.dev1.amplitude_Ibias / Lockin.dev1.VI_gain / Lockin.dev1.V_per_V;
Lockin.dev1.ramp_rate_rescaled = Lockin.dev1.ramp_rate / Lockin.dev1.VI_gain / Lockin.dev1.V_per_V;

%% define bias and gate vector
VI.ramp_rate = VI.ramp_rate_current / Lockin.dev1.VI_gain / VI.V_per_V;

Gate.startV = Gate.initV;          % V
Gate = Generate_voltage_array(Settings, Gate);

VI.startV = VI.initI / VI.VIgain / VI.V_per_V ;          % V
VI.current = linspace(VI.minI, VI.maxI, VI.points);
VI.voltage = VI.current / VI.VIgain / VI.V_per_V; %Bias sweep
VI.dV = abs(VI.voltage(2) - VI.voltage(1));

%% plot settings
Labels.titles.dV = 'DC voltage (V)';

Labels.titles.conductance = 'Conductance (A/V)' ;
Labels.component.conductance = 'X';

Labels.titles.resistance = 'Resistance (\Omega)' ;
Labels.component.resistance = 'X';

Labels.x_axis_label = 'Gate voltage V';
Labels.x_axis = Gate.voltage;

Labels.y_axis_label = 'DC current (A)';
Labels.y_axis = VI.current;

%% T dependence
for index = 1:length(Settings.Temperatures)

    %% define T controller
    if index ~= 1
        Settings = Init_T_controller(Settings);
        Settings.T_controller.set_T_setpoint(1, Settings.Temperatures(index));
        fprintf('Setting temperature to %1.2f K...', Settings.Temperatures(index))
        pause(20*60)
        fprintf('done\n')
    end

    %% set lockin bias
    fprintf('Ramping up AC voltage bias...')
    ramp_lockin(Lockin.dev1, 0, Lockin.dev1.amplitude_rescaled, Lockin.dev1.ramp_rate_rescaled);
    fprintf('done\n')

    %% Initialize arrays
    Timetrace.repeat = length(Gate.voltage);
    Timetrace.repeat2 = length(VI.voltage);
    Timetrace = Define_arrays_stability_Ibias(Settings, Timetrace);

    %% ramp up fixed gates
    fprintf('%s - Setting fixed gates... ', datetime('now') )
    Gate_fixed.startV = Gate_fixed.initV;
    Gate_fixed.setV = Gate_fixed.targetV;

    Gate_fixed = Apply_fixed_voltage(Settings, Gate_fixed);
    fprintf('done\n')

    %% update plot name
    figure_name = sprintf('Ghurzi - %01dK', Settings.Temperatures(index));

    %% Run measurement
    for i = 1:Timetrace.repeat

        %% set gate voltage
        fprintf('%s - Setting Vg = %1.2f...', datetime('now'), Gate.voltage(i) )
        Gate.setV = Gate.voltage(i);
        Gate = Apply_fixed_voltage(Settings, Gate);
        fprintf('done\n')

        fprintf('%s - Gate Settling time %1.2f sec...', datetime('now'), Gate.waiting_time)
        pause(Gate.waiting_time)
        if i==1 && j==1
            pause(3 * Gate.waiting_time)
        end
        fprintf('done\n')

        %% resynchronize MFLI lockins
        if Lockin.dev1.resync
            Run_sync_ZI_lockins(Timetrace.mds, Timetrace.devices_string);
        end

        %% Make VI
        for j = 1:Timetrace.repeat2

            %% set bias voltage
            %                 fprintf('%s - Setting Vb = %1.2e...', datetime('now'), VI.voltage(j) )
            VI.setV = VI.voltage(j);
            VI = Apply_fixed_voltage(Settings, VI);
            %                 fprintf('done\n')

            if j == 1
                pause(VI.waiting_time)
            end

            %% autorange input, based on 100ms timetrace
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

            %% process data
            Timetrace = Process_data_stability_Ibias(Settings, Timetrace, Lockin);

            %% make plot
            Timetrace = Realtime_timetrace_3D(Settings, Timetrace, Labels, figure_name);

            %% prepare new loop
            VI.startV = VI.setV;
        end

        %% prepare new loop
        Gate.startV = Gate.setV;

    end

    %% clean workpace
    Timetrace = rmfield(Timetrace, 'data');
    Timetrace = rmfield(Timetrace, 'time');
    Timetrace = rmfield(Timetrace, 'handles');

    %% save data
    filename = sprintf('%s/%s_%s_%s-%01dK', Settings.save_dir, Settings.filename, Settings.sample, Settings.type, Settings.Temperatures(index));
    Save_data(Settings, Timetrace, VI, Gate, Lockin, [filename '.mat']);

    %% save figure
    fig = findobj('Type', 'Figure', 'Name', figure_name);
    saveas(fig, [filename '.png'])
    saveas(fig, [filename '.fig'])

    %% set gate voltage back to zero
    Gate.startV = Gate.setV;
    Gate.setV = 0;
    Gate = Apply_fixed_voltage(Settings, Gate);

    %% set bias voltage back to zero
    VI.startV = VI.setV;
    VI.setV = 0;
    VI = Apply_fixed_voltage(Settings, VI);

    %% ramp down lockin bias
    fprintf('Ramping down AC voltage bias...')
    ramp_lockin(Lockin.dev1, Lockin.dev1.amplitude_rescaled, 0, Lockin.dev1.ramp_rate_rescaled);
    fprintf('done\n')

    %% ramp down fixed gates
    fprintf('%s - Setting fixed gates... ', datetime('now') )
    Gate_fixed.startV = Gate_fixed.targetV;
    Gate_fixed.setV = Gate_fixed.endV;

    Gate_fixed = Apply_fixed_voltage(Settings, Gate_fixed);
    fprintf('done\n')

end

%load train, sound(y,Fs)
%% reset gate if needed via reset_gate(Settings,Gate)