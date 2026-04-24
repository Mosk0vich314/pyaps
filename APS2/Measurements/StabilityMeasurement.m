classdef StabilityMeasurement < BaseMeasurement
    % StabilityMeasurement - Performs stability measurements over time/gate
    
    properties
        IV struct
        Gate struct
        StopFlag (1,1) logical = false
    end
    
    methods
        function obj = StabilityMeasurement(settings)
            obj@BaseMeasurement(settings);
            obj.Settings.type = 'Stability';
            
            % IV Params
            obj.IV.startV = 0; 
            obj.IV.maxV = 0.2;
            obj.IV.minV = -0.2;
            obj.IV.points = 1001;
            obj.IV.sweep_dir = 'up';
            obj.IV.scanrate = 450000;
            obj.IV.process_number = 1;
            
            % Gate Params
            obj.Gate.initV = 0;
            obj.Gate.minV = -0.5;
            obj.Gate.maxV = 0.5;
            obj.Gate.dV = 0.001;
            obj.Gate.ramp_rate = 0.5;
            obj.Gate.process = 'Fixed_AO';
            obj.Gate.process_number = 3;
            obj.Gate.waiting_time = 0.1;
        end
        
        function Run(obj)
            fprintf('--- Starting Stability Measurement ---\n');
            
            % 1. Init ADwin
            obj.InitADwinProcess(obj.IV);
            obj.InitADwinProcess(obj.Gate);
            
            % 2. Generate Gate Vector
            gateV = obj.Gate.minV : obj.Gate.dV : obj.Gate.maxV;
            if strcmp(obj.Gate.sweep_dir, 'down')
                gateV = fliplr(gateV);
            end
            
            obj.IV.repeat = length(gateV);
            
            % 3. Measurement Loop
            for i = 1:obj.IV.repeat
                if obj.StopFlag, break; end
                
                % Set Gate
                obj.Gate.setV = gateV(i);
                % Apply_fixed_voltage(obj.Settings, obj.Gate); % (Assuming global function)
                
                pause(obj.Gate.waiting_time);
                
                % Run IV
                try
                    obj.IV.index = i;
                    obj.IV = Run_sweep(obj.Settings, obj.IV); % (Assuming global function)
                    
                    % Store Data
                    obj.Data.IV = obj.IV; 
                    obj.Data.Gate = obj.Gate;
                    
                    % Realtime Plot
                    % Realtime_sweep3D(...) 
                catch ME
                    fprintf(2, 'Stability Error: %s\n', ME.message);
                end
            end
            
            obj.Save();
        end
        
        function Stop(obj)
            obj.StopFlag = true;
        end
    end
end