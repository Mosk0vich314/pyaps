%% clear
clear
close all hidden
clc
tic

%% Settings
Settings.save_dir = 'I:\Lakeshore10K\Zhang\20231214_DGP24\9K\dual_gate-AC';
Settings.sample = 'test_dual_gate'; %A2-GatetoGate G0b Test_100MOhm_50ohm_termination
Settings.auto = ''; %FEMTO
Settings.ADC_gain = [0 0 0 0 0 0 0 0]; % 2^N
Settings.get_sample_T = 'Lakeshore336'; % {'', 'Lakeshore336', 'Lakeshore325', 'Oxford_ITC'}
Settings.type = 'Stability_Timetraces';
Settings.ADwin = 'ProII'; % GoldII or ProII
Settings.res4p = 0;
Settings.second_der = 1; % second derivative, only possible in 2p

Settings.Temperatures = [5]; %[105:-15:105];

Bias.V_per_V = 1;          % V/V0
Bias.initV = 0;              % V
Bias.targetV = 0.1;              % V
Bias.endV = 0;              % V
Bias.ramp_rate = 0.1;
Bias.fixed_voltage = 'ADwin';
Bias.output = 1;

% Lockin 1 --> apply across sample
Lockin.dev1.sensitivity = 10;           % sensitivity (V). Use 10 for MFLI with no sensitivity set
Lockin.dev1.frequency = 10;           % Hz, use integers!
Lockin.dev1.harmonic = 1;           %
Lockin.dev1.timeconstant = 0.1;           % seconds
Lockin.dev1.amplitude_Vbias = 5;           % amplitude bias oscillation for conductance measurement mV
Lockin.dev1.ramp_rate = 5;           % mV / s
Lockin.dev1.V_per_V = 0.01;
Lockin.dev1.IVgain = 1e9;               %  IV converter
Lockin.dev1.model = 'ZI_MFLI';
Lockin.dev1.input_diff = 'A';
Lockin.dev1.input_range = 0.3;
Lockin.dev1.filter_order = 4;
Lockin.dev1.channels = {'x','y'};
Lockin.dev1.autoranging = 1; % 0 off; 1 on
Lockin.dev1.resync = 0;
Lockin.dev1.datarate = 3e3; % do not exceed 30e3!
Lockin.dev1.input_AC = 1;

% Lockin 2 --> measure across device
Lockin.dev2 = Lockin.dev1;
Lockin.dev2.Vgain = 1;               %  V amplifier
Lockin.dev2.input_diff = 'A';

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

Gate1.initV = 0;
Gate1.minV = -0.01;            % V
Gate1.maxV = 0.01;            % V
Gate1.points = 11;
Gate1.ramp_rate = 0.1;       % V/s
Gate1.waiting_time = 0;     % s after setting Gate.setV
Gate1.V_per_V = 1;          % V/V0
Gate1.sweep_dir = 'up';
Gate1.fixed_voltage = 'ADwin';
Gate1.output = 2;
Gate1.process_number = 3;
Gate1.process = 'Fixed_AO';

Gate2.initV = 0;
Gate2.minV = -0.01;            % V
Gate2.maxV = 0.01;            % V
Gate2.points = 11;
Gate2.ramp_rate = 0.1;       % V/s
Gate2.waiting_time = 0.5;     % s after setting Gate.setV
Gate2.V_per_V = 1;          % V/V0
Gate2.sweep_dir = 'up';
Gate2.fixed_voltage = 'ADwin';
Gate2.output = 3;
Gate2.process_number = 3;
Gate2.process = 'Fixed_AO';

Lockin.dev1.address = 'DEV7535'; % dI/dV
Lockin.dev2.address = 'DEV7496'; % dV

Gate_fixed.fixed_voltage = 'ADwin';
Gate_fixed.waiting_time = 0;     % s after setting Gate.setV  %%can this be implemented via Gate.settling_time?
Gate_fixed.output = [3 4 5 6 7 8];
Gate_fixed.targetV = [0 0 0 0 0 0];
Gate_fixed.initV = [0 0 0 0 0 0];
Gate_fixed.endV = [0 0 0 0 0 0];
Gate_fixed.V_per_V = [1 1 1 1 1 1];          % V/V0
Gate_fixed.ramp_rate = 0.4*ones(6,1);       % V/s

%% get ADC gains
Settings.ADC = {    Lockin.dev1.IVgain,...
    Lockin.dev2.Vgain,...
    };

%% Initialize
Settings = Init(Settings);

%% Initialize ADwin
[Settings, Timetrace] = get_readAI_process(Settings, Timetrace);
Settings = Init_ADwin(Settings, Timetrace, Gate1);

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

%% Init ADwin timetrace
Timetrace = Init_timetrace_ADwin(Settings, Timetrace);

%% convert bias lockin voltage
Lockin.dev1.amplitude_rescaled = Lockin.dev1.amplitude_Vbias * 1e-3 / Lockin.dev1.V_per_V;
Lockin.dev1.ramp_rate_rescaled = Lockin.dev1.ramp_rate * 1e-3 / Lockin.dev1.V_per_V;

%% define gate 1 and gate 2 vector
Gate1.startV = Gate1.initV;          % V
Gate2.startV = Gate2.initV;          % V

Gate1 = Generate_voltage_array(Settings, Gate1);
Gate2 = Generate_voltage_array(Settings, Gate2);

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

Labels.x_axis_label = 'Gate 2 voltage V';
Labels.y_axis_label = 'Gate 1 voltage V';
Labels.x_axis = Gate2.voltage;
Labels.y_axis = Gate1.voltage;

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
    
    %% set DC bias
    Bias.startV = Bias.initV;
    Bias.setV = Bias.targetV;
    fprintf('%s - Setting bias voltage = %1.2fV...', datetime('now'), Bias.targetV )
    Bias = Apply_fixed_voltage(Settings, Bias);
    fprintf('done\n')
    
    %% Initialize arrays
    Timetrace.repeat = length(Gate2.voltage);
    Timetrace.repeat2 = length(Gate1.voltage);
    Timetrace = Define_arrays_stability(Settings, Timetrace);
    
    %% ramp up fixed gates
    fprintf('%s - Setting fixed gates... ', datetime('now') )
    Gate_fixed.startV = Gate_fixed.initV;
    Gate_fixed.setV = Gate_fixed.targetV;
    
    Gate_fixed = Apply_fixed_voltage(Settings, Gate_fixed);
    fprintf('done\n')
    
    %% update plot name
    figure_name = sprintf('Dual Gate - %01dK', Settings.Temperatures(index));
    
    %% Run measurement
    for i = 1:Timetrace.repeat
        
        %% set gate 2 voltage
        fprintf('%s - Setting Vg2 = %1.2fV...', datetime('now'), Gate2.voltage(i) )
        Gate2.setV = Gate2.voltage(i);
        Gate2 = Apply_fixed_voltage(Settings, Gate2);
        fprintf('done\n')
        
        fprintf('%s - Gate 2 Settling time %1.2f sec...', datetime('now'), Gate2.waiting_time)
        pause(Gate2.waiting_time)
        if i==1 && j==1
            pause(3 * Gate2.waiting_time)
        end
        fprintf('done\n')
        
        %% resynchronize MFLI lockins
        if Lockin.dev1.resync
            Run_sync_ZI_lockins(Timetrace.mds, Timetrace.devices_string);
        end
        
        %% Make gate 1 sweep
        for j = 1:Timetrace.repeat2
            
            %% set gate 1 voltage
            Gate1.setV = Gate1.voltage(j);
            Gate1 = Apply_fixed_voltage(Settings, Gate1);
            
            if j == 1
                pause(Gate1.waiting_time)
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
            Timetrace = Process_data_stability(Settings, Timetrace, Lockin);
            
            %% make plot
            Timetrace = Realtime_timetrace_3D(Settings, Timetrace, Labels, figure_name);
            
            %% prepare new loop
            Gate1.startV = Gate1.setV;
        end
        
        %% prepare new loop
        Gate2.startV = Gate2.setV;
        
    end
    
    %% clean workpace
    Timetrace = rmfield(Timetrace, 'data');
    Timetrace = rmfield(Timetrace, 'time');
    Timetrace = rmfield(Timetrace, 'handles');
    
    %% save data
    filename = sprintf('%s/%s_%s_%s-%1.2eV-%01dK', Settings.save_dir, Settings.filename, Settings.sample, Settings.type, Bias.targetV, Settings.Temperatures(index));
    Save_data(Settings, Timetrace, Gate1, Gate2, Lockin, [filename '.mat']);
    
    %% save figure
    fig = findobj('Type', 'Figure', 'Name', figure_name);
    saveas(fig, [filename '.png'])
    saveas(fig, [filename '.fig'])
    
    %% set gate 1 voltage back to zero
    Gate1.startV = Gate1.setV;
    Gate1.setV = 0;
    Gate1 = Apply_fixed_voltage(Settings, Gate1);
    
    %% set gate 2 voltage back to zero
    Gate2.startV = Gate2.setV;
    Gate2.setV = 0;
    Gate2 = Apply_fixed_voltage(Settings, Gate2);
    
    %% ramp down lockin bias
    fprintf('Ramping down AC voltage bias...')
    ramp_lockin(Lockin.dev1, Lockin.dev1.amplitude_rescaled, 0, Lockin.dev1.ramp_rate_rescaled);
    fprintf('done\n')
    
    %% set DC bias to zero
    Bias.startV = Bias.targetV;
    Bias.setV = Bias.endV;
    fprintf('%s - Setting bias voltage = %1.2fV...', datetime('now'), Bias.endV )
    Bias = Apply_fixed_voltage(Settings, Bias);
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