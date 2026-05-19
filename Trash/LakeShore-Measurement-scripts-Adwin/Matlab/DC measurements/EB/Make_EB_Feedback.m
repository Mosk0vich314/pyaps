%% clear
clear
close all hidden
clc
tic

%% Settings
Settings.save_dir = 'E:\Samples\Zhang_SWNT_04\AD\EB';
Settings.sample = 'E2';
Settings.ADC = {1e4, 'off', 'off', 'off'};    % 1e6 fixed gain % auto = linear with auto ranging; off = disabled; log = logarithmic (not yet implemented)
Settings.ADC_gain = [0 0 0 0]; % 2^N
Settings.get_sample_T = 'Lakeshore336'; % {'', 'Lakeshore336', 'Lakeshore325', 'Oxford_ITC'}
Settings.T_controller_address = 'GPIB0::8::INSTR';
Settings.type = 'IVs';
Settings.IVcutoff = 150; % Hz
% Settings.comment = ''

EB.V_per_V = 10;          % V/V0
EB.startV = 0;            % V
EB.maxV = 40;              % V
EB.sweep_rate = 20;         %V/min
EB.sweep_rate_back = 5; %V/s
EB.current_threshhold = 0.9;  % in percent
EB.R_threshold = 1000000;    % Ohm
   

EB.mov_win = 50;
EB.repeat = 1;
EB.settling_time = 0;      % ms
EB.settling_time_autoranging = 0;      % ms
EB.scanrate = 450000;       % Hz
% IV.offset =

EB.output = 1;              % AO channel
EB.process_number = 8;

Gate.initV = 0;          % V
Gate.targetV = 0;            % V
Gate.endV = 0;            % V
Gate.ramp_rate = 15;       % V/s
Gate.waiting_time = 0;     % s after setting Gate.setV  %%can this be implemented via Gate.settling_time?
Gate.V_per_V = 25;          % V/V0
Gate.output = 2;            % AO channel

Gate.process_number = 3;
Gate.process = 'Fixed_AO';

Gate_fixed.fixed_voltage = 'ADwin';
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
N_inputs = 0;
for i=1:length(Settings.ADC)
    if isnumeric(Settings.ADC{i})
        N_inputs = N_inputs + 1;
    end
end

if N_inputs == 1
    EB.process = 'Feedback_EB';
end
if N_inputs == 2
    EB.process = 'Sweep_AO_read_AI_dual';
end

Settings = Init_ADwin(Settings, EB, Gate);

%% set gate voltage
Gate.startV = Gate.initV;
Gate.setV = Gate.targetV;
Gate = Apply_fixed_voltage(Settings, Gate);

% wait after gate set
fprintf('Gate Settling\n')
%pause(Gate.waiting_time)




%% ramp up fixed gates
fprintf('%s - Setting fixed gates... ', datetime('now') )
Gate_fixed.startV = Gate_fixed.initV;
Gate_fixed.setV = Gate_fixed.targetV;

Gate_fixed = Apply_fixed_voltage(Settings, Gate_fixed);
fprintf('done\n')

fprintf('%s - Waiting fixed gates settling time... ', datetime('now') )
pause(Gate_fixed.waiting_time)
fprintf('done\n')


%% run measurement
for i = 1:EB.repeat
     %% run IV
    fprintf('Running EB - %1.0f/%1.0f...', i, EB.repeat)
    EB.index = i;
    EB = Run_sweep_feedback_EB(Settings, EB);
   
    %% get current and show plot
    EB = Realtime_sweep_feedback_EB(Settings, EB, 'IV');
    fprintf('done\n')
    
    %% EB ending condition
    Bias  = EB.current{i}(end, 1);
    Current = EB.current{i}(end, 2);
    if Bias / Current >= EB.R_threshold
       break
    end
    
    if Bias == EB.maxV
        break
    end
    
end

%% save data
if Save == 1
    filename = sprintf('%s/%s_%s_%s.mat', Settings.save_dir, Settings.filename, Settings.sample, Settings.type);
    Save_data(Settings, EB, Gate, filename);
end

%% set gate voltage back to start voltage
Gate.startV = Gate.targetV;
Gate.setV = Gate.endV;
Gate = Apply_fixed_voltage(Settings, Gate);



%% ramp down fixed gates
fprintf('%s - Setting fixed gates... ', datetime('now') )
Gate_fixed.startV = Gate_fixed.targetV;
Gate_fixed.setV = Gate_fixed.endV;

Gate_fixed = Apply_fixed_voltage(Settings, Gate_fixed);
fprintf('done\n')

%%
toc