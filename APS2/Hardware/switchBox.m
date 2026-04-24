classdef SwitchBox < handle
    % SwitchBox - Controls the switching relay via ADwin Digital Output
    
    properties (Access = public)
        Bit (1,1) double = 11
        ProcessNo (1,1) double = 5
        ProcessName char = 'Single_DO'
        Settings struct
    end

    methods (Access = public)
        function obj = SwitchBox(settings)
            % Constructor
            if nargin > 0
                obj.Settings = settings;
                
                % Create a config struct for the ADwin loader
                switchConfig.bit = obj.Bit;
                switchConfig.process = obj.ProcessName;
                
                try
                    % Ensure Init_ADwin_load_process is on your path
                    Init_ADwin_load_process(obj.Settings, switchConfig);
                    
                    % Configure Process Delay & Bit
                    % (Assuming global ADwin functions exist)
                    Set_Processdelay(obj.ProcessNo, 100000);
                    Set_Par(50, obj.Bit);
                catch ME
                    warning('SwitchBox ADwin Init failed: %s', ME.message);
                end
            end
        end

        function StartRoutine(obj)
            % Toggles the switch pulse
            try
                Start_Process(obj.ProcessNo);
                
                % Pulse logic: 0 -> 1 -> 0
                Set_Par(51, 0);
                Set_Par(51, 1);
                pause(0.01);
                Set_Par(51, 0);
                
                Stop_Process(obj.ProcessNo);
            catch ME
                fprintf(2, 'SwitchBox Error: %s\n', ME.message);
            end
        end
    end
end