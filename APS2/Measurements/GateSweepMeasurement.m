classdef GateSweepMeasurement < BaseMeasurement
    % GateSweepMeasurement - Performs Gate Sweeps
    
    properties
        Gate struct
        Bias struct
    end
    
    methods
        function obj = GateSweepMeasurement(settings)
            obj@BaseMeasurement(settings);
            
            obj.Settings.type = 'Gatesweep';
            
            % Gate Params
            obj.Gate.startV = -50;
            obj.Gate.maxV = 50;
            obj.Gate.points = 1001;
            obj.Gate.process = 'Sweep_AO'; 
            obj.Gate.output = 2; % Different AO channel
            
            % Bias Params
            obj.Bias.setV = 0.1; % Fixed Bias
        end
        
        function Run(obj)
            fprintf('--- Starting Gate Sweep ---\n');
            
            % 1. Set Fixed Bias First
            % (Assuming Apply_fixed_voltage exists)
            % Apply_fixed_voltage(obj.Settings, obj.Bias);
            
            % 2. Setup ADwin for Gate Sweep
            obj.InitADwinProcess(obj.Gate);
            
            try
                obj.Gate = Run_sweep(obj.Settings, obj.Gate);
                obj.Data.Gate = obj.Gate;
                obj.Data.Bias = obj.Bias;
            catch ME
                fprintf(2, 'Gate Sweep Failed: %s\n', ME.message);
            end
            
            obj.Save();
        end
    end
end