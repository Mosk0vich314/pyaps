%% clear
clear
close all
clc

%% Settings
Settings.save_dir = 'E:\Mickael\test_Adwin';
Settings.N_ADC = 4;
Settings.ADC = {'auto', 'off', 'off', 'off'};    % 1e6 fixed gain % auto = linear with auto ranging; off = disabled; log = logarithmic (not yet implemented)
Settings.ADC_gain = [0 0 0 0]; % 2^N

Histo.V_per_V = 1.0;          % V/V0
Histo.output = 1;
Histo.startV = 0.0;            % V
Histo.setV = 0.10;              % V
Histo.endV = 0.0;              % V

Histo.runtime = 100;            % sec
Histo.points_av = 40000;          % points
Histo.settling_time = 1;      % ms
Histo.integration_time = 0.0;  % sec
Histo.scanrate = 400000;       % Hz

Histo.stepsize = 500;            % nm
Histo.breaking_speed1 = 1;      % um/s
Histo.breaking_speed2 = 1;      % um/s
Histo.making_speed = 1;         % um/s

Histo.upper_G = 1;             % G0
Histo.inter_G = 1e-1;           % G0
Histo.lower_G = 1e-3;           % G0
Histo.added_breaking = 20;      % um

% plot settings
Histo.plot.Gmin = 1e-7;       % G0
Histo.plot.Gmax = 20;         % G0
Histo.plot.Xmin = 0.5;       % nm
Histo.plot.Xmax = 5;         % nm
Histo.plot.nGbins = 251;
Histo.plot.nDbins = 161;
Histo.plot.attenuation = 5e-5;

Save = 0;
N_traces = 1000;

Histo.process_number = 4;
Histo.process = 'ADwin_script/piezo_histogram_18b';

%% Initialize 
Settings = Init(Settings);

%% Initialize ADwin
Settings = Init_ADwin(Settings, Histo);

%% Initialize histogram plots
Histo.Histo = zeros(Histo.plot.nGbins, Histo.plot.nDbins);
Histo.G_array = linspace(log10(Histo.plot.Gmin), log10(Histo.plot.Gmax), Histo.plot.nGbins);
Histo.D_array = linspace(Histo.plot.Xmin, Histo.plot.Xmax, Histo.plot.nDbins);

%% set piezo settings
piezo1 = Attocube_controller('COM4',1);
% piezo.set_stepsize(500);
% piezo.convert_stepsize_to_voltage
piezo1.set_voltage(20);

piezo1.set_frequency(1000);


%% run measurements

for i = 1:N_traces
    
    %% start single trace
    Histo = Start_trace(Settings, Histo);
    
    %% get current
    Histo = Get_Histo(Settings, Histo);
    
    %% show plot
    Histo = Plot_Histo(Settings, Histo, 'Histogram', [0.15 0.15 0.7 0.7]);
    
    %% save data
    if Save == 1
        Save_data(Settings, Histo);
    end
    
end