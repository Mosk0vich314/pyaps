%% clear
clear
close all hidden
clc

%% Settings
Settings.save_dir = 'C:\samples\PIETRO\MCBJ2T_6_2';
Settings.sample = 'A3.1'; %A2-GatetoGate G0b Test_100MOhm_50ohm_termination
Settings.ADC = {1e5, 1};
Settings.auto = 'BPI'; % FEMTOwait_cycles_breaking2
Settings.ADC_gain = [0 0 0 0 0 0 0 0]; % 2^N
Settings.get_sample_T = ''; % {'', 'Lakeshore336', 'Lakeshore325', 'Oxford_ITC'}
Settings.type = 'Timetrace';
Settings.ADwin = 'GoldII'; % GoldII or ProII
Setting.G0 = 77.48091729e-6;

Bias.V_per_V = 1;          % V/V0
Bias.ramp_rate = 0.1;       % V/s
Bias.initV = 0;            % V
Bias.targetV = 0.1;            % V
Bias.endV = 0;            % V
Bias.output = 1;              % AO channel
Bias.process = 'Fixed_AO';

Timetrace.runtime = 500;      % s
Timetrace.scanrate = 500000;       % Hz
Timetrace.points_av = 1000;        % points
Timetrace.settling_time = 0;      % ms
Timetrace.settling_time_autoranging = 0;      % ms
Timetrace.process_number = 2;
Timetrace.clim = [];
Timetrace.process_number = 2;
Timetrace.model = 'ADwin';

Initialize.stop_on_target = 0;
Initialize.move_static = 0;
Initialize.targetG = 1; %G0
Initialize.reset_drive_voltage = 1;

Static.Plot.Gmin = 1e-7; % G0
Static.Plot.Gmax = 1000;   % G0
Static.V_per_V = 1;          % V/V0
Static.ramp_rate = 0.01; % V/s
Static.output = 2;              % AO channel
Static.process = 'Fixed_AO';
Static.wait_for_finish = 0; % do no lock terminal during ramping

%% Initialize
Settings = Init(Settings);

%% Initialize ADwin
[Settings, Timetrace] = get_readAI_process(Settings, Timetrace);
Settings = Init_ADwin(Settings, Bias, Timetrace);

%% get target current
Initialize.targetI = Initialize.targetG * Settings.G0 * Bias.targetV;

%% Ramp up bias voltage
Bias.startV = Bias.initV;
Bias.setV = Bias.targetV;
Bias = Apply_fixed_voltage(Settings, Bias);

%% define starting static voltage
if Initialize.reset_drive_voltage || Get_Par(80) == 0
    Static.startV = 0;            % V
else
    Static.startV = convert_bin_to_V(Get_Par(80), Settings.output_max, Settings.output_resolution);            % V
end

%% start Timetrace
Timetrace = Run_timetrace(Settings, Timetrace);

%% get static direction
if Initialize.move_static
    measured_I = abs(Get_FPar(1));
    if  measured_I < Initialize.targetI % making
        Static.setV = 0;            % V
        Initialize.breaking = 0;
    else % breaking
        Static.setV = 10;            % V
        Initialize.breaking = 1;
    end
end

%% start static ramp
if Initialize.move_static
    Static = Apply_fixed_voltage(Settings, Static);
end

%% get current and show plot
[Timetrace, Initialize] = Realtime_timetrace_MCBJ_Init(Settings, Timetrace, Bias, Initialize, Settings.type);

%% display error
switch Initialize.status
    case 1
        disp('Initialization Running')
    case 2
        disp('Initialization succesful')
    case 3
        disp('Error - Cannot break')
    case 4
        disp('Error - Cannot make')
end
