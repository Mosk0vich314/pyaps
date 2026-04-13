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
Settings.save_dir = 'C:\EmpaDaten\Samples\test';
Settings.sample = 'test';
Settings.ADC = {1, 1};    % 1e6 fixed gain % auto = linear with auto ranging; off = disabled; log = logarithmic (not yet implemented)
Settings.ADC_gain = [0 0 0 0]; % 2^N
Settings.switchbox.state = '';
Settings.get_sample_T = 0; %boolean
Settings.type = 'Gatesweep';
Settings.IVcutoff = 150; % Hz

Settings.switchbox.clock_bit = 11;
Settings.switchbox.latch_bit = 10;
Settings.switchbox.data_bit = 9;
Settings.switchbox.disable_bit = 8;
Settings.N_switches = 1;
Settings.coils_per_switch = 1;
Settings.N_coils = Settings.N_switches * Settings.coils_per_switch;

Switches.process = 'control_switches';
Switches.process_number = 5;

Gate.frequency = 10;          % Hz
Gate.sampling_rate = 500;
Gate.runtime = 100;  % sec, is actually considerably longer?
Gate.amplitude = 10;     % V
Gate.V_per_V = 10;      % V/V0
Gate.threshold1 = 0.1; % V
Gate.threshold2 = 0.1; % V
Gate.scanrate = 400000;       % Hz
Gate.points_av = Gate.scanrate / Gate.sampling_rate;        % points
Gate.settling_time = 0;      % ms
Gate.settling_time_autoranging = 0;      % ms
Gate.integration_time = 0;  % sec
Gate.auto = '';

Gate.output = 2;              % AO channel
Gate.process_number = 1;
Gate.process = 'Sweep_AO_read_AI_dual';
Gate.repeat = 1;


%% Initialize ADwin and piezo
Settings = Init(Settings, Gate, Switches);

%% switchbox
Switch_switchbox(Settings, Switches);

%% make gate vector
Time = linspace(0, Gate.runtime, Gate.runtime * Gate.sampling_rate);
Gate.bias = Gate.amplitude * sin(Time / pi*2 * Gate.runtime * Gate.frequency);

%% run measurement
for index = 1:Gate.repeat
       
    %% run IV % actually run gate-sweep
    fprintf('Running Gate sweep - %1.0f...', index)
    Gate.index = index;
    Gate = Run_sweep(Settings, Gate);
    
    %Gate = Realtime_sweep(Settings, Gate, 'IV');
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
        temp1 = GetData_Double(2, previous_counter + 1, actual_time - previous_counter);
        temp2 = GetData_Double(3, previous_counter + 1, actual_time - previous_counter);
        if max(abs(temp1)) > Gate.threshold1 && ~done1
            if max(temp1) > Gate.threshold1 && ~done1
                done1 = 1;
                disp('Needle 1 in contact')
                load splat, sound(y,Fs)
            end
            if max(abs(temp2)) > Gate.threshold2 && ~done2
                if max(temp2) > Gate.threshold2 && ~done2
                    done2 = 1;
                    disp('Needle 2 in contact')
                    load train, sound(y,Fs)
                end
                
                if done1 && done2
                    Stop_Process(sweep.process_number);
                    
                    %Switch_switchbox(Settings, Switches);
                    
                    %pause(0.1)
                    
                    %Make_IV
                    Switch_switchbox(Settings, Switches);
                    
                    pause(0.1)
                    
                    Make_IV_current_limit
                    run = 0;
                end
                %         end
                drawnow limitrate
            end
            
            %% prepare for next iteration
            previous_counter = actual_time;
        end
        Switch_switchbox(Settings, Switches);
        toc
    end
end