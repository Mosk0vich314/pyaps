classdef IVMeasurement < BaseMeasurement
    % IVMeasurement - Performs I-V Sweeps
    
    properties
        IV struct
    end
    
    methods
        function obj = IVMeasurement(settings)
            % Call Parent Constructor
            obj@BaseMeasurement(settings);
            
            % Default IV Parameters
            obj.Settings.type = 'IV';
            obj.IV.startV = -0.5;
            obj.IV.maxV = 0.5;
            obj.IV.points = 501;
            obj.IV.scanrate = 450000;
            obj.IV.settling_time = 0;
            
            % ADwin Config for Sweep
            obj.IV.process = 'Sweep_AO';
            obj.IV.output = 1; % AO Channel
        end
        
        function Run(obj)
            fprintf('--- Starting IV Measurement ---\n');
            
            % 1. Setup ADwin
            obj.InitADwinProcess(obj.IV);
            
            % 2. Run Sweep (Assuming Run_sweep function exists globally)
            % Note: You might need to move Run_sweep logic here eventually
            % For now, I'll wrap the existing function call pattern
            try
                obj.IV = Run_sweep(obj.Settings, obj.IV);
                
                % 3. Store Data for Saving
                obj.Data.IV = obj.IV;
                
                % 4. Plot
                % Realtime_sweep(obj.Settings, obj.IV, 'IV Plot'); 
                
            catch ME
                fprintf(2, 'IV Run Failed: %s\n', ME.message);
            end
            
            % 5. Save
            obj.Save();
        end
    end
end