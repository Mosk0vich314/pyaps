%% clear
clear
close all
clc

%% Initialize ADwin and piezo
Init;

%% Settings
Settings.save_dir = 'D:/Mickael/';
Settings.N_ADC = 4;
Settings.ADC = {1e9, 'off', 'off', 'off'};          % 1e6 fixed gain % lin = linear with auto ranging; off = disabled
Settings.ADC_gain = [0 0 0 0]; % 2^N

Gt.runtime = 3;            % sec
Gt.startV = 0.0;            % V
Gt.setV = 0.1;              % V
Gt.endV = 0.0;              % V
Gt.points_av = 4000;          % points
Gt.settling_time = 0;      % ms
Gt.integration_time = 0.0;  % sec
Gt.scanrate = 200000;       % Hz
Gt.V_per_V = 1.0;          % V/V0
Save = 1;

%% load on ADwin
Load_Process('ADwin_script/test_piezo_step.TC5'); % load record_G(t) as process 2

%% 