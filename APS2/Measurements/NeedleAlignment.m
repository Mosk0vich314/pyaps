classdef NeedleAlignment < BaseMeasurement
    % NeedleAlignment - Oscillates the gate to help alignment
    
    properties
        Gate struct
        Timetrace struct
    end
    
    methods
        function obj = NeedleAlignment(settings)
            obj@BaseMeasurement(settings);
            obj.Settings.type = 'NeedleAlign';
            
            % Waveform Params
            obj.Gate.Amplitude = 10; % V
            obj.Gate.Frequency = 10; % Hz
            obj.Gate.process = 'Waveform_AO';
            
            obj.Timetrace.runtime = 1.2;
            obj.Timetrace.scanrate = 500000;
        end
        
        function Run(obj)
            fprintf('--- Starting Needle Alignment ---\n');
            
            % Generate Waveform (Sine)
            pts = obj.Timetrace.scanrate / obj.Gate.Frequency;
            t = linspace(0, 1/obj.Gate.Frequency, pts);
            waveform = obj.Gate.Amplitude * sin(2*pi*obj.Gate.Frequency * t);
            
            % Setup ADwin
            obj.InitADwinProcess(obj.Gate);
            
            % Send Waveform (Pseudo-code, replace with actual ADwin call)
            % Send_Waveform(waveform);
            
            fprintf('Running Alignment Loop (Ctrl+C to stop)...\n');
            % Loop logic here...
        end
    end
end