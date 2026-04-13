%% clear
clear
close all hidden
clc
tic

%% Settings
Settings.save_dir = 'E:\Samples\Schmuck_GTTJ_01\EB';
Settings.sample = 'H18_AIR';
Settings.ADC = {1e4, 1e4, 'off', 'off'};    % 1e6 fixed gain % auto = linear with auto ranging; off = disabled; log = logarithmic (not yet implemented)
Settings.ADC_gain = [0 0 0 0]; % 2^N
Settings.get_sample_T = ''; % {'', 'Lakeshore336', 'Lakeshore325', 'Oxford_ITC'}
Settings.T_controller_address = 'GPIB0::8::INSTR';
Settings.IVcutoff = 150; % Hz
Settings.type = 'EB';
% Settings.comment = ''




EB.endV = 20; % V maximal Voltage to apply
EB.output = 1;            % AO channel
EB.V_per_V = 10;
EB.dV = 0.005; % V 
EB.baseV = 0; % V reference value for voltage step calculations
EB.Output_Amplification = 1; % Multiplier for output voltage
EB.startV_low = 0.05;
EB.startV_high = 0.15;% V
EB.setV_low = 0.1;
EB.setV_high = 0.15;
EB.threshhold_low = 1e6; % low voltage threshhold
EB.threshhold_high = 1e6; % high voltage threshhold
EB.timecounter = 500; % length of plateau
EB.cyclecounter = 10; % number of cycles before increasing voltage


EB.scanrate = 400000;
EB.settling_time = 0;
% EB.loops = 10;
EB.points_av = 100; % points to average over




EB.process_number = 7;
EB.process = 'Electroburning';



Save = 1;


%% Initialize 
Settings = Init(Settings);

%% Initialize ADwin
Settings = Init_ADwin(Settings, EB);


%% run IV
EB = Run_EB(Settings, EB);
% get current and show plot
EB = Realtime_sweep_EB(Settings, EB, 'EB');

EB = Get_data_EB(Settings, EB);
plot(EB.Voltage{1}, [EB.data{1},EB.data{2}])








% save data
if Save == 1
    filename = sprintf('%s/%s_%s_%s.mat', Settings.save_dir, Settings.filename, Settings.sample, Settings.type);
    Save_data(Settings, EB, filename);
    Save_data_dat(Settings, EB, filename, 'current');
end



fprintf('done\n')
toc
pause(3)

% load train, sound(y,Fs)