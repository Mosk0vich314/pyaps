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
Bias.ramp_rate = 0.1;       % V/s
Bias.initV = 0;            % V
Bias.targetV = 0.01;            % V
Bias.endV = 0;            % V
Bias.output = 1;              % AO channel
Bias.process = 'Fixed_AO';

Histo.start_V = 0.0;
Histo.number_traces = 1;
Histo.scanrate = 300000;       % Hz  max 300kHz, set by DAC
Histo.points_av = 100;        % points
Histo.output = 2;               % output for drive voltage
Histo.process = 'MCBJ_histogram_BPI_HiRes_DAC';

Histo.high_G = 60;              % G0      conductance for going from making  --> breaking, should be smaller than initG
Histo.inter_G = 20 ;             % G0        conductance from breaking 1 --> breaking 2
Histo.low_G = 1e-2;              % G0       conductance from breaking 2 --> postbreaking
Histo.post_breaking_voltage = 0.003;       % V
Histo.V_per_V = 1;  % amplifier gain for drive voltage

Histo.breaking_speed1 = 0.01;       % V/s
Histo.breaking_speed2 = 0.001;       % V/s
Histo.making_speed = 0.01;       % V/s
Histo.reset_drive_voltage = 1;

Histo.SignalLength = 32; % 5 bit
Histo.SignalWidth = 100; % mV

Plot.nGbins = 401;
Plot.nDbins = 401;

Plot.xmin = -0.0005; % nm
Plot.xmax = 0.0015;    % nm
Plot.Gmin = 1e-7; % G0set(gca,'xdir','reverse')
Plot.Gmax = 1000;   % G0
Plot.V_to_nm = 1;

%% Initialize
Settings = Init(Settings);

%% Initialize ADwin
Settings = Init_ADwin(Settings, Bias, Histo);

%% initialize MCBJ histgram
[Settings, Histo] = Init_MCBJ_breaking_trace_HiRes(Settings, Histo, Bias);

%% Ramp up bias voltage
Bias.startV = Bias.initV;
Bias.setV = Bias.targetV;
Bias = Apply_fixed_voltage(Settings, Bias);

%% init data
Histo.data_breaking = cell(Histo.number_traces);
Histo.data_making = cell(Histo.number_traces);

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
        'error';
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