%% clear
clear
close all
clc
tic 
%% Settings
Settings.save_dir = 'E:\Samples\Pads0903_9AGNR\Pretransfer\IV';
Settings.sample = 'A55';
Settings.ADC = {1e9, 'off','off','off'};    % 1e6 fixed gain % auto = linear with auto ranging; off = disabled; log = logarithmic (not yet implemented)
Settings.ADC_gain = [0 0 0 0]; % 2^N
Settings.switchbox.state = '';
Settings.get_sample_T = 0;
Settings.type = 'Gatesweep';
Settings.IVcutoff = 100; % Hz

Gate.V_per_V = 10.0;          % V/V0
Gate.startV = 0.0;            % V
Gate.maxV = 10.0;              % V
Gate.minV = -Gate.maxV;         % V
% Gate.dV = 0.05;              % V
Gate.dV = 5;              % V

Gate.points_av = 9600;        % points
Gate.settling_time = 0;      % ms
Gate.settling_time_autoranging = 0;      % ms
Gate.integration_time = 0.0;  % sec  
Gate.scanrate = 480000;       % Hz

Gate.output = 2;              % AO channel
Gate.process_number = 1;
Gate.process = 'Sweep_AO_read_AI_single'; % load record_G(t) as process 2

Bias.initV = 0.0;          % V
Bias.minV = 0.1;            % V
Bias.maxV = -0.1;            % V
Bias.dV = 0.05;            % V
Bias.endV = 0.0;            % V
Bias.ramp_rate = 0.1;       % V/s
Bias.V_per_V = 1;          % V/V0
Bias.scanrate = 480000;       % Hz

Bias.output = 1;
Bias.process_number = 3;
Bias.process = 'Fixed_AO';

Save = 0;
Show_realtime = 0;

%% Initialize ADwin and piezo
Settings = Init(Settings, Gate, Bias);

%% generate bias vector
Bias.voltage = linspace(Bias.minV, Bias.maxV, 1+abs(Bias.minV-Bias.maxV)/Bias.dV);
%Bias.voltage = Bias.minV;
Bias.N_voltage = length(Bias.voltage);

Bias.startV = Bias.initV;          % V
Gate.repeat = Bias.N_voltage;

%% run measurement
for i = 1:Gate.repeat
% for i = 1:20
    
    
    %% set bias voltage
    Bias.setV = Bias.voltage(i);
    Bias = Apply_fixed_voltage(Settings, Bias);
    Bias.startV = Bias.setV;          % V
    
    %% run IV
    fprintf('Running Gate sweep - %1.0f/%1.0f...', i, Bias.N_voltage)
    Gate.index = i;
    Gate = Run_sweep(Settings, Gate);
    
    %% get current and show plot
    if Show_realtime
        Gate = Realtime_sweep(Settings, Gate, 'IV');
    else
        Gate = Get_data_sweep(Settings, Gate);
%         Plot_sweep(Settings, Gate, 'IV')
    end
    fprintf('done\n')
    
end

%% save data
if Save == 1
    filename = sprintf('%s_%s_%s', Settings.filename, Settings.sample, Settings.type);
    Save_data(Settings, Gate, Bias, filename); 
    Save_data_dat(Settings, Gate, Bias, filename, 'current'); 
end

%% set gate voltage back to start voltage
Bias.setV = Bias.endV;
Bias = Apply_fixed_voltage(Settings, Bias);

% %% plot surface plot
% if Gate.repeat > 1
%     Gate = split_data_sweep(Settings, Gate);
%     Surf_sweep(Settings, Gate, 'Surface plot')
% end
% 
% %% plot density plot
% if Gate.repeat > 1
%     Density_sweep(Settings, Gate, 'Density plot')
% end
toc
% load train, sound(y,Fs)