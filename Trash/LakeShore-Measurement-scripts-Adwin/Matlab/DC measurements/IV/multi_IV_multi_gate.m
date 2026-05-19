%% clear
 clear
close all hidden
clc
tic

%% Settings
Settings.save_dir = 'E:\Samples\ANL_EB_04\9AGNR_AuMica_S527\Postannealing\warming_up\multi_IV_multi_gate'; % 'E:\Samples\ANL_EB_04\pretransfer\IV'; %'E:\Samples\flaa_AngEvap_22\9AGNR\IV';
Settings.sample = 'I17';
Settings.ADC = {1e9, 'off', 'off', 'off', 'off', 'off', 'off', 'off'};    % 1e6 fixed gain % auto = linear with auto ranging; off = disabled; log = logarithmic (not yet implemented)
Settings.auto = 'off';
Settings.ADC_gain = [0 0 0 0]; % 2^N
Settings.get_sample_T = 'Lakeshore336'; % {'', 'Lakeshore336', 'Lakeshore325', 'Oxford_ITC'}
Settings.ADwin = 'GoldII'; % GoldII or ProII

Settings.type = 'IVs';
Settings.IVcutoff = 150; % Hz
% Settings.comment = ''

IV.V_per_V = 1;          % V/V0
IV.startV = 0.0;            % V
IV.maxV = 1;             % V
IV.points = 300;
IV.minV = -IV.maxV;         % V
IV.dV = IV.maxV / IV.points *2;    % V

IV.N_per_gate = 40;
IV.points_av = 9000;        % points
IV.settling_time = 0;      % ms
IV.settling_time_autoranging = 200;      % ms
IV.scanrate = 450000;       % Hz

IV.output = 1;              % AO channel
IV.process_number = 1;
IV.sweep_dir = 'up';

Gate.beginV = 0;          % V
Gate.minV = -100;            % V
Gate.maxV = 100;            % V
Gate.dV = 10;            % V
Gate.ramp_rate = 5;       % V/s
Gate.V_per_V = 10;          % V/V0
Gate.output = 2;            % AO channel

Gate.process_number = 3;
Gate.process = 'Fixed_AO';

Gate_fixed.fixed_voltage = 'OptoDAC';
Gate_fixed.waiting_time = 0;     % s after setting Gate.setV  %%can this be implemented via Gate.settling_time?
Gate_fixed.output = [1 2 3 4 5 6 7 8];
Gate_fixed.targetV = [0 0 0 0 0 0 0 0];
Gate_fixed.initV = [0 0 0 0 0 0 0 0];
Gate_fixed.endV = [0 0 0 0 0 0 0 0];
Gate_fixed.V_per_V = [5 5 5 5 5 5 5 5];          % V/V0
Gate_fixed.ramp_rate = 0.4*ones(8,1);       % V/s
Gate_fixed.type = 'Gate_fixed';
Gate_fixed.process_number = 3;

Save = 1;

%% Initialize 
Settings = Init(Settings);

%% Initialize ADwin
[Settings, IV] = get_sweep_process(Settings, IV);
Settings = Init_ADwin(Settings, IV, Gate);

%% ramp up fixed gates
fprintf('%s - Setting fixed gates... ', datetime('now') )
Gate_fixed.startV = Gate_fixed.initV;
Gate_fixed.setV = Gate_fixed.targetV;

Gate_fixed = Apply_fixed_voltage(Settings, Gate_fixed);
fprintf('done\n')

fprintf('%s - Waiting fixed gates settling time... ', datetime('now') )
pause(Gate_fixed.waiting_time)
fprintf('done\n')

%% Initialize gate
Gate.bias = [Gate.maxV:-Gate.dV:Gate.minV 0]';
% Gate.bias = [Gate.beginV:Gate.dV:Gate.maxV Gate.maxV:-Gate.dV:Gate.minV Gate.minV:Gate.dV:Gate.beginV]';
Gate.numGate = length(Gate.bias);
Gate.startV = Gate.beginV; 
IV.repeat = length(Gate.bias) * IV.N_per_gate;

%% run measurement
for j = 1:Gate.numGate
    
    Gate.setV = Gate.bias(j);
    Gate = Apply_fixed_voltage(Settings, Gate);
    Gate.startV = Gate.setV;

    for i = 1:IV.N_per_gate
        
        %% run IV
        IV.index = i + ((j-1) * IV.N_per_gate);
        fprintf('Running I(V) - %01d/%01d - Vg = %1.2fV\n', IV.index, IV.repeat, Gate.setV )
        IV = Run_sweep(Settings, IV);
        
        %% get current and show plot
        IV = Realtime_sweep(Settings, IV, 'IV');

        fprintf('done\n')
        toc
    end
end

%% save figure
fig = findobj('Name','IV');
saveas(fig, sprintf('%s/%s_%s_%s.png', Settings.save_dir, Settings.filename, Settings.sample, Settings.type))
saveas(fig, sprintf('%s/%s_%s_%s.fig', Settings.save_dir, Settings.filename, Settings.sample, Settings.type))=

%% save data
if Save == 1
    filename = sprintf('%s/%s_%s_%s.mat', Settings.save_dir, Settings.filename, Settings.sample, Settings.type);
    Save_data(Settings, IV, Gate, filename);
  %  Save_data_dat(Settings, IV, Gate, filename, 'current');
end

%% ramp down fixed gates
fprintf('%s - Setting fixed gates... ', datetime('now') )
Gate_fixed.startV = Gate_fixed.targetV;
Gate_fixed.setV = Gate_fixed.endV;

Gate_fixed = Apply_fixed_voltage(Settings, Gate_fixed);
fprintf('done\n')

%% plot surface plot
if IV.repeat > 1
    IV = split_data_sweep(Settings, IV);
    Surf_sweep(Settings, IV, 'Surface plot')
end

% close all
% load train, sound(y,Fs)

%% 
figure;hold on
for i=1:IV.repeat
    plot(IV.bias, IV.current{1}(:,i),'.','markersize',20)
end