%% clear
clear
close all hidden
clc
tic

%% Settings
Settings.save_dir = 'E:\Samples\flaa_AngEvap225\9AGNR\9K\Gatesweep';   % 'E:\Samples\flaa_AngEvap_22\9AGNR\300K\Gatesweep';
Settings.sample = 'test';
Settings.ADC = {1e9, 'off', 'off', 'off', 'off', 'off', 'off', 'off'};    % 1e6 fixed gain % auto = linear with auto ranging; off = disabled; log = logarithmic (not yet implemented)
Settings.ADC_gain = [0 0 0 0]; % 2^N
Settings.get_sample_T = 'Lakeshore336'; % {'', 'Lakeshore336', 'Lakeshore325', 'Oxford_ITC'}
Settings.T_controller_address = 'GPIB0::8::INSTR';
Settings.T = 150:10:300;

Settings.type = 'Gt';
Settings.IVcutoff = 150; % Hz
% Settings.comment = ''

Gt.V_per_V = 1.0;          % V/V0
Gt.runtime = 10;            % sec
Gt.startV = 0.0;            % V
Gt.setV = 0.0;              % V
Gt.endV = 0.0;              % V
Gt.ramp_rate = 1;       % V/s

Gt.points_av = 1;          % points
Gt.settling_time = 0;      % ms
Gt.settling_time_autoranging = 0;      % ms
Gt.scanrate = 490000;       % Hz max 465kHz for single channel, 420kHz for dual channel
Gt.repeat = 1;

Gt.output = 1;              % AO
Gt.process_number = 2;

Gate.beginV = 0;          % V
Gate.minV = -100;            % V
Gate.maxV = 100;            % V
Gate.dV = 10;            % V
Gate.ramp_rate = 5;       % V/s
Gate.V_per_V = 10;          % V/V0
Gate.output = 2;            % AO channel
Gate.waiting_time = 0;     % s after setting Gate.setV

Gate.process_number = 3;
Gate.process = 'Fixed_AO';

Bias.initV = 0;          % V
Bias.minV = 0.5;            % V
Bias.maxV = 1.5;            % V
Bias.dV = 0.5;            % V
Bias.endV = 0.0;            % V
Bias.ramp_rate = 0.5;       % V/s
Bias.V_per_V = 1;          % V/V0
Bias.scanrate = 40000;       % Hz
Bias.waiting_time = 1;      %sec
Bias.output = 1;
Bias.process_number = 3;
Bias.process = 'Fixed_AO';

Save = 1;

%% Initialize ADwin
N_inputs = 0;
for i=1:length(Settings.ADC)
    if isnumeric(Settings.ADC{i})
        N_inputs = N_inputs + 1;
    end
end

if N_inputs == 1
    if Gt.points_av == 1
        Gt.process = 'Fixed_AO_read_AI_single_fast';
    else
        Gt.process = 'Fixed_AO_read_AI_single';
    end
end
if N_inputs == 2
    Gt.process = 'Sweep_AO_read_AI_dual';
end
if N_inputs > 2
    Gt.process = 'Sweep_AO_read_AI_multi';
end

Settings = Init(Settings, Gt, Gate);

%% Initialize
Settings.nT = length(Settings.T);

Gate.bias = [Gate.beginV:Gate.dV:Gate.maxV Gate.maxV:-Gate.dV:Gate.minV Gate.minV:Gate.dV:Gate.beginV]';
Gate.numGate = length(Gate.bias);
Gate.startV = Gate.beginV;

Bias.voltage = Bias.minV:Bias.dV:Bias.maxV;
Bias.N_voltage = length(Bias.voltage);
Bias.startV = Bias.initV;          % V

Gt.repeat = Gate.numGate * Bias.N_voltage;

%% run measurement

for l = 1:Settings.nT
    
    %% set T
    Settings.T_controller.set_T_setpoint(1, Settings.T(l));
    fprintf('Setting T - %01dK\n', Settings.T(l))
    
    if l ~= 1
        pause(1200)
    end
    
    for j = 1:Gate.numGate
        
        %% apply gate
        Gate.setV = Gate.bias(j);
        Gate = Apply_fixed_voltage(Settings, Gate);
        Gate.startV = Gate.setV;
        
        pause(Gate.waiting_time)
        
        for i = 1:Bias.N_voltage
            
            %% set bias voltage
            Bias.setV = Bias.voltage(i);
            Bias.end = Bias.setV;
            Bias = Apply_fixed_voltage(Settings, Bias);
            Bias.startV = Bias.setV;          % V
            
            pause(Bias.waiting_time)
            
            Gt.index = i + ((j-1) * Bias.N_voltage);
            
            %% run Gt
            Gt.startV = Bias.setV;            % V
            Gt.setV = Bias.setV;              % V
            Gt.endV = Bias.setV;              % V
            
            fprintf('Running G(t) - %1.0f/%1.0f...', Gt.index, Gt.repeat)
            Gt = Run_fixed(Settings, Gt);
            
            %% get current and show plot
            Gt = Realtime_Gt(Settings, Gt, 'Gt');
            fprintf('done\n')
            
        end
        
        %% reset bias voltage
        Bias.setV = 0;
        Bias = Apply_fixed_voltage(Settings, Bias);
        Bias.startV = 0;
        
    end
    
    %% save data
    if Save == 1
        filename = sprintf('%s/%s_%s_%s_%1.0fK.mat', Settings.save_dir, Settings.filename, Settings.sample, Settings.type, Settings.T(l));
        Save_data(Settings, Gt, Gate, filename);
        %         Save_data_dat(Settings, IV, Gate, filename, 'current');
    end
end

toc

% close all
% load train, sound(y,Fs)