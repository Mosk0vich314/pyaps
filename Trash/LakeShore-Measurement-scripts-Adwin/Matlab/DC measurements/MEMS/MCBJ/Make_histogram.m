%% clear
clear
close all hidden
clc

%% Settings
Settings.save_dir = 'C:\samples\PIETRO\MCBJ2T_6_2';
Settings.sample = 'test'; %A2-GatetoGate G0b Test_100MOhm_50ohm_termination
Settings.ADC = {1e5, 1};
Settings.auto = 'BPI'; % FEMTOwait_cycles_breaking2
Settings.ADC_gain = [0 0 0 0 0 0 0 0]; % 2^N
Settings.get_sample_T = ''; % {'', 'Lakeshore336', 'Lakeshore325', 'Oxford_ITC'}
Settings.type = 'Histogram';
Settings.ADwin = 'GoldII'; % GoldII or ProII
Setting.G0 = 77.48091729e-6;

Bias.V_per_V = 1;          % V/V0
Bias.ramp_rate = 0.01;       % V/s
Bias.initV = 0;            % V
Bias.targetV = 0.01;            % V
Bias.endV = 0;            % V
Bias.output = 1;              % AO channel
Bias.process = 'Fixed_AO';

Histo.start_V = 0.0;
Histo.number_traces = 1000;
Histo.scanrate = 500000;       % Hz
Histo.points_av = 1000;        % points
Histo.output = 3;               % output for drive voltage
Histo.process = 'MCBJ_histogram_BPI';

Histo.initG = 60;           % conductance for initialization using static V, also when cannot make/break
Histo.high_G = 60;              % G0      conductance for going from making  --> breaking, should be smaller than initG
Histo.inter_G = 20 ;             % G0        conductance from breaking 1 --> breaking 2
Histo.low_G = 1e-2;              % G0       conductance from breaking 2 --> postbreaking
Histo.post_breaking_voltage = 0.003;       % V
Histo.V_per_V = 0.03;  % amplifier gain for drive voltage

Histo.breaking_speed1 = 0.01;       % V/s
Histo.breaking_speed2 = 0.001;       % V/s
Histo.making_speed = 0.01;       % V/s
Histo.reset_drive_voltage = 0;

Plot.nGbins = 401;
Plot.nDbins = 401;

Plot.xmin = -0.0005; % nm
Plot.xmax = 0.0015;    % nm
Plot.Gmin = 1e-7; % G0set(gca,'xdir','reverse')
Plot.Gmax = 1000;   % G0
Plot.V_to_nm = 1;

Static.reset_drive_voltage = 0;
Static.Plot.Gmin = 1e-7; % G0
Static.Plot.Gmax = 1000;   % G0
Static.V_per_V = 1;          % V/V0
Static.ramp_rate = 0.01; % V/s
Static.output = 2;              % AO channel
Static.process = 'Fixed_AO';
Static.wait_for_finish = 0; % do no lock terminal during ramping

Timetrace.runtime = 500;      % s
Timetrace.scanrate = 20000;       % Hz
Timetrace.points_av = 100;        % points
Timetrace.process_number = 2;
Timetrace.clim = [];
Timetrace.process_number = 2;
Timetrace.model = 'ADwin';

%% Initialize
Settings = Init(Settings);

%% Initialize ADwin
[Settings, Timetrace] = get_readAI_process(Settings, Timetrace);
Settings = Init_ADwin(Settings, Bias, Histo, Timetrace);

%% initialize MCBJ histgram
[Settings, Histo] = Init_MCBJ_breaking_trace(Settings, Histo, Bias);

%% Ramp up bias voltage
Bias.startV = Bias.initV;
Bias.setV = Bias.targetV;
Bias = Apply_fixed_voltage(Settings, Bias);

%% init data
Histo.data_breaking = cell(Histo.number_traces);
Histo.data_making = cell(Histo.number_traces);

%% define starting static voltage
if Static.reset_drive_voltage || Get_Par(80) == 0
    Static.startV = 0;            % V
else
    Static.startV = convert_bin_to_V(Get_Par(80), Settings.output_max, Settings.output_resolution);            % V
end

%% init Initialize
Initialize.targetI = Histo.initG * Settings.G0 * Bias.targetV;
Initialize.stop_on_target = 1;
Initialize.move_static = 1;

%% start timetrace
Timetrace.settling_time = 0;
Timetrace.settling_time_autoranging = 0;
Timetrace = Run_timetrace(Settings, Timetrace);

%% get static direction
pause(0.01)
measured_I = abs(Get_FPar(1));
if  measured_I < Initialize.targetI % making
    Static.setV = 0;            % V
    Initialize.breaking = 0;
else % breaking
    Static.setV = 10;            % V
    Initialize.breaking = 1;
end

%% start Initialization
Static = Apply_fixed_voltage(Settings, Static);

%% get current and show plot Initialization
[Timetrace, Initialize] = Realtime_timetrace_MCBJ_Init(Settings, Timetrace, Bias, Initialize, 'Initialization');

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

close all

%% run measurement
for i = 1:Histo.number_traces
    % start process
    Start_Process(7);

    % plot data
    Histo.index = i;
    Histo = Plot_MCBJ_breaking_trace(Settings, Histo, Bias, Plot, Settings.type);

    %% progress
    fprintf('Trace %01d : Status %01d\n', i, Get_Par(62))

    %% if cannot break or break
    if Histo.status == 3 || Histo.status == 4

        if Histo.status == 3 % cannot break
            Static.setV = 10;            % V
            Initialize.breaking = 1;
        end

        if Histo.status == 4   % cannot make
            Static.setV = 0;            % V
            Initialize.breaking = 0;
        end

        %% start Initialization
        Static.reset_drive_voltage = 0;

        %% start timetrace
        Timetrace = Run_timetrace(Settings, Timetrace);

        %% start ramp
        Static = Apply_fixed_voltage(Settings, Static);

        %% get current and show plot Initialization
        [Timetrace, Initialize] = Realtime_timetrace_MCBJ_Init(Settings, Timetrace, Bias, Initialize, 'Initialization');
        close(Timetrace.fig)

        %% reset current voltage in histogram
        Set_Par(61, convert_V_to_bin(0, Settings.output_min, Settings.output_max, Settings.output_resolution));

    end

end

%% save figure
fig = findobj('Name', Settings.type);
filename = sprintf('%s/%s_%s_%s', Settings.save_dir, Settings.filename, Settings.sample, Settings.type);
saveas(fig, [filename '.png'])
saveas(fig, [filename '.fig'])

%% save data
Save_data(Settings, Histo, Bias, [filename '.mat']);

%% Ramp down bias voltage
Bias.startV = Bias.targetV;
Bias.setV = Bias.endV;
Bias = Apply_fixed_voltage(Settings, Bias);

%% save figure
fig = findobj('Name', Settings.type);
filename = sprintf('%s/%s_%s_%s', Settings.save_dir, Settings.filename, Settings.sample, Settings.type);
saveas(fig, [filename '.png'])
saveas(fig, [filename '.fig'])

%% save data
Save_data(Settings, Bias, Histo, Plot, [filename '.mat']);