%% clear
clear
close all hidden
clc
instrreset
tic

% AI 1 - 4p Voltage X
% AI 2 - 4p Voltage Y
% AI 3 - 4p Voltage DC


%% Settings
Settings.save_dir =  'E:\Samples\20220727_Zhang_TBG_Dou1\D2\255mK\DualGatesweep_Ibias_DC';
Settings.sample = {'D2_C3-C5_10nA_TG-1_BG-2'};
Settings.auto = ''; %FEMTO
Settings.ADC_gain = [0 0 0 0 0 0 0 0]; % 2^N
Settings.get_sample_T = 'Oxford_ITC'; % {'', 'Lakeshore336', 'Lakeshore325', 'Oxford_ITC'}
Settings.type = 'Stability4p_Timetraces';
Settings.ADwin = 'GoldII'; % GoldII or ProII

VI.V_per_V = 1;          % V/V0
VI.initI = 0;              % A
VI.targetI = 10e-9;        % A
VI.endI = 0;              % A
VI.ramp_rateI = 2e-9; % A/s
VI.fixed_voltage = 'ADwin';
VI.Vgain = 1e3;     % voltage gain (V-measure V per V)
VI.VIgain = 1e-7;     % A/V (10MO pre-resistor)
VI.output = 1;
VI.process_number = 3;
VI.process = 'Fixed_AO';

Gate1.maxV = 5;              % V
Gate1.minV = -5;         % V
Gate1.points = 101;
Gate1.ramp_rate = 1;
Gate1.V_per_V = 1;          % V/V0
Gate1.sweep_dir = 'down';
Gate1.fixed_voltage = 'ADwin';

Gate2.maxV = 8;            % V
Gate2.minV = -8;            % V
Gate2.points = 151;
Gate2.ramp_rate = 1;       % V/s
Gate2.V_per_V = 1;          % V/V0
Gate2.sweep_dir = 'down';
Gate2.fixed_voltage = 'ADwin';
Gate2.waiting_time = 0;     % s after setting Gate.setV  %%can this be implemented via Gate.settling_time?

% Lockin 1 --> apply across device, measure conductance
Lockin1.sensitivity = 20e-3;           %
Lockin1.frequency = 17.777;           % Hz
Lockin1.harmonic = 1;           %
Lockin1.timeconstant = 0.1;           % seconds
Lockin1.amplitude_Ibias = 1e-9;           % current 1nA
Lockin1.ramp_rate = 1e-9;           % A / s
Lockin1.V_per_V = 1e-2;             % S0 In2 100
Lockin1.reserve = 1;               %  0 = high, 1 = normal, 2 = low

Timetrace.scanrate = 50000;       % Hz
Timetrace.points_av = 1000;        % points
Timetrace.settling_time = 0;      % ms
Timetrace.runtime = 0.01;      % 20/Lockin1.frequency
Timetrace.wait_time = 0*10 * Lockin1.timeconstant;      % 10 * Lockin1.timeconstant
Timetrace.settling_time_autoranging = 0;      % ms
Timetrace.process_number = 2;
Timetrace.clim = [];

Gate1.output = 2;
Gate1.process_number = 3;
Gate1.process = 'Fixed_AO';

Gate2.output = 3;
Gate2.process_number = 3;
Gate2.process = 'Fixed_AO';

Gate_fixed.fixed_voltage = 'OptoDAC';
Gate_fixed.waiting_time = 0;     % s after setting Gate.setV  %%can this be implemented via Gate.settling_time?
Gate_fixed.output = [1 2 3 4 5 6 7 8];
Gate_fixed.targetV = [0 0 0 0 0 0 0 0];
Gate_fixed.initV = [0 0 0 0 0 0 0 0];
Gate_fixed.endV = [0 0 0 0 0 0 0 0];
Gate_fixed.V_per_V = [5 5 5 5 5 5 5 5];          % V/V0
Gate_fixed.ramp_rate = 0.2*ones(8,1);       % V/s

Lockin1.address = 'GPIB0::1::INSTR'; % heater

%% get ADC gains
Settings.ADC = {    
    1 / (Lockin1.sensitivity / 10 / VI.Vgain), ...
    1 / (Lockin1.sensitivity / 10 / VI.Vgain), ...
    VI.Vgain,...
    1 ,...
    };

%% Initialize 
Settings = Init(Settings);

%% Initialize ADwin
Timetrace.process = 'Read_AI_multi';
Settings = Init_ADwin(Settings, Timetrace, VI);

%% Initialize Lockin
Lockin1 = Init_lockin(Lockin1);

%% convert current to voltage
Lockin1.amplitude_rescaled = Lockin1.amplitude_Ibias / VI.VIgain / Lockin1.V_per_V;
Lockin1.ramp_rate_rescaled = Lockin1.ramp_rate / VI.VIgain / Lockin1.V_per_V;

VI.initV = VI.initI / VI.VIgain / VI.V_per_V;        
VI.targetV = VI.targetI / VI.VIgain / VI.V_per_V;        
VI.endV = VI.endI / VI.VIgain / VI.V_per_V;        
VI.ramp_rate = VI.ramp_rateI / VI.VIgain / VI.V_per_V;        
 
%% set lockin bias
fprintf('Ramping up AC voltage bias...')
ramp_lockin(Lockin1, 0, Lockin1.amplitude_rescaled, Lockin1.ramp_rate_rescaled);
fprintf('done\n')

%% define Gate 1 and Gate2 vector
Gate1.startV = 0.0;          % V
Gate2.startV = 0.0;          % V

Gate1 = Generate_voltage_array(Settings, Gate1);
Gate2 = Generate_voltage_array(Settings, Gate2);

%% ramp up fixed gates
fprintf('%s - Setting fixed gates... ', datetime('now') )
Gate_fixed.startV = Gate_fixed.initV;
Gate_fixed.setV = Gate_fixed.targetV;

Gate_fixed = Apply_fixed_voltage(Settings, Gate_fixed);
fprintf('done\n')

fprintf('%s - Waiting fixed gates settling time... ', datetime('now') )
pause(Gate_fixed.waiting_time)
fprintf('done\n')

%% Apply fixed bias current
fprintf('%s - Setting fixed bias... ', datetime('now') )
VI.startV = VI.initV;
VI.setV = VI.targetV;
VI = Apply_fixed_voltage(Settings, VI);
fprintf('done\n')

%% Run measurement
Timetrace.repeat = length(Gate2.voltage);
Timetrace.repeat2 = length(Gate1.voltage);
counter = 1;

for i = 1:Timetrace.repeat
    for j = 1:Timetrace.repeat2
        
       
        %% set gate 2 voltage
        Gate2.setV = Gate2.voltage(i);
        if Gate2.setV ~= Gate2.startV
            
            fprintf('%s - Setting Gate 2 = %1.2f...', datetime('now'), Gate2.setV )
            Gate2 = Apply_fixed_voltage(Settings, Gate2);
            fprintf('done\n')
            
            fprintf('%s - Gate 2 Settling time %1.2f sec...', datetime('now'), Gate2.waiting_time)
            pause(Gate2.waiting_time)
            if i==1 && j==1
                pause(3 * Gate2.waiting_time)
            end
            fprintf('done\n')
        end
        
        %% set gate 1 voltage
        Gate1.setV = Gate1.voltage(i);
        fprintf('%s - Setting Gate 1 = %1.2f...', datetime('now'), Gate1.setV )
        Gate1 = Apply_fixed_voltage(Settings, Gate1);
        fprintf('done\n')
        
        %% for for lockin
        pause(Timetrace.wait_time)
            
        %% run Timetrace
        fprintf('%s - Running Timetrace : %01d /%01d...', datetime('now'), counter, Timetrace.repeat*Timetrace.repeat2)
        Timetrace.index = i;
        Timetrace.index2 = j;
        Timetrace = Run_timetrace(Settings, Timetrace);
        
        %% get current and show plot
        Figure.title = 'Dual gate 4p';
        Figure.label1 = 'Gate 1 voltage (V)';
        Figure.label2 = 'Gate 2 voltage (V)';
        [Timetrace, Gate1] = Realtime_timetrace_conductance4p_Ibias_3D(Settings, Timetrace, VI, Gate1, Gate2, Lockin1, Figure);
        fprintf('done\n')
        
        %% prepare new cycle
        Gate1.startV = Gate1.setV;
        Gate2.startV = Gate2.setV;
        
        counter =  counter + 1;
    end
end

%% save data 
Samplename = Settings.sample{1};
filename = sprintf('%s/%s_%s_%s.mat', Settings.save_dir, Settings.filename, Samplename, Settings.type);
Save_data(Settings, Timetrace, Gate1, Gate2, Gate_fixed, Lockin1, filename);
%     Save_data(Settings, Timetrace, Gate1, Gate2, Gate_fixed, Lockin1, Lockin2, filename);

%% save figure
fig = findobj('Type', 'Figure', 'Name', 'Dual gate 4p');
saveas(fig, sprintf('%s/%s_%s_%s.png', Settings.save_dir, Settings.filename, Samplename, Settings.type))
saveas(fig, sprintf('%s/%s_%s_%s.fig', Settings.save_dir, Settings.filename, Samplename, Settings.type))

%% set gate 1 back to zero
Gate1.startV = Gate1.setV;
Gate1.setV = 0;
Gate1 = Apply_fixed_voltage(Settings, Gate1);

%% set gate 2 back to zero
Gate2.startV = Gate2.setV;
Gate2.setV = 0;
Gate2 = Apply_fixed_voltage(Settings, Gate2);

%% set DC current bias to zero
VI.startV = VI.targetV;
VI.setV = VI.endV;
VI = Apply_fixed_voltage(Settings, VI);

%% ramp down fixed gates
fprintf('%s - Setting fixed gates... ', datetime('now') )
Gate_fixed.startV = Gate_fixed.targetV;
Gate_fixed.setV = Gate_fixed.endV;

Gate_fixed = Apply_fixed_voltage(Settings, Gate_fixed);
fprintf('done\n')

%% ramp down lockin bias
fprintf('Ramping down AC voltage bias...')
ramp_lockin(Lockin1, Lockin1.amplitude_rescaled, 0, Lockin1.ramp_rate_rescaled);
fprintf('done\n')

toc
%load train, sound(y,Fs)
%% reset gate if needed via reset_gate(Settings,Gate)