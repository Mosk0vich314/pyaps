%% clear
clear
close all hidden
clc
tic

%%
% changed V_per_V to 10
% changed max(tempi) to max(abs(tempi)) as there was a negative offset
% ruining everything
% 

%% Settings
Settings.save_dir = 'C:\Users\lab405\Documents\ADwin_AuPS_tests\25052020_AutomatedProbeStation\IV';
Settings.sample = 'F55';
Settings.ADC = {1e9, 1e9};    % 1e6 fixed gain % auto = linear with auto ranging; off = disabled; log = logarithmic (not yet implemented)
Settings.ADC_gain = [0 0 0 0]; % 2^N
Settings.switchbox.state = '';
Settings.get_sample_T = 0; %boolean
Settings.type = 'Gatesweep';
Settings.IVcutoff = 150; % Hz
Settings.auto = '';

%
Settings.switchbox.clock_bit = 11;
Settings.switchbox.latch_bit = 10;
Settings.switchbox.data_bit = 9;
Settings.switchbox.disable_bit = 8;
Settings.N_switches = 1;
Settings.coils_per_switch = 1;
Settings.N_coils = Settings.N_switches * Settings.coils_per_switch;

Switches.process = 'control_switches';
Switches.process_number = 5;
Switches.switch_frequency = 100; % otehrwise doesn't run

Gate.frequency = 10;          % Hz
Gate.sampling_rate = 500;
Gate.runtime = 60;  % sec, is actually considerably longer?
Gate.amplitude = 10;     % V
Gate.V_per_V = 10;      % V/V0
% % thresholds set for 1e9 gain
Gate.threshold1 = 0.03; % V
%   Gate.threshold2 = 1e-3; % V
Gate.threshold2 = 0.03; % V
Gate.scanrate = 400000;       % Hz
%Gate.points_av = Gate.scanrate / Gate.sampling_rate;        % points
Gate.points_av = Gate.scanrate/50;
Gate.settling_time = 0;      % ms
Gate.settling_time_autoranging = 0;      % ms
Gate.integration_time = 0;  % sec

Gate.output = 2;              % AO channel
Gate.process_number = 1;
Gate.process = 'Sweep_AO_read_AI_dual';
Gate.repeat = 1;

%% Initialize ADwin and piezo
Settings = Init(Settings, Gate, Switches);

%% switchbox
%Switch_switchbox(Settings, Switches);

%% make gate vector
Time = linspace(0, Gate.runtime, Gate.runtime * Gate.sampling_rate);
Gate.bias = Gate.amplitude * sin(2*pi * Time * Gate.frequency);

%% run measurement
for index = 1:Gate.repeat
    
    %% run IV % actually run gate-sweep
    fprintf('Running Gate sweep - %1.0f...\n', index)
    Gate.index = index;
    Gate = Run_sweep(Settings, Gate);
    
    Gate = Realtime_sweep(Settings, Gate, 'IV');
    pause(0.2)
    
    %% run loop
    run = true;
    sweep = Gate;
    previous_counter = 1;
    done1 = 0;
    done2 = 0;
    
    while run && Get_Par(25) > 0
        
        run = Process_Status(sweep.process_number);
        actual_time = Get_Par(25) - 1;
        
        %% get current and update plot
        %         try
        temp1 = GetData_Double(2, previous_counter + 1, ctual_time - previous_counter);
        temp2 = GetData_Double(3, previous_counter + 1, actual_time - previous_counter);
%         [ max(temp1) max(temp2)]
        if max(abs(temp1)) > Gate.threshold1 && ~done1
            done1 = 1;
            disp('Needle 1 in contact')
            load splat, sound(y,Fs)
        end
        if max(abs(temp2)) > Gate.threshold2 && ~done2
            done2 = 1;
            disp('Needle 2 in contact')
            load train, sound(y,Fs)
        end
        
        if done1 && done2
            Stop_Process(sweep.process_number);
                        
            %Switch_switchbox(Settings, Switches);
            
            %pause(0.1)
            
            %Make_IV
            run = false;
        end
        %         end
        drawnow limitrate
    end
    
    %% prepare for next iteration
    previous_counter = actual_time;
end
Switch_switchbox(Settings, Switches);