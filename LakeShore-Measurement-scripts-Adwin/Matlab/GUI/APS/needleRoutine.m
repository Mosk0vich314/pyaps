classdef needleRoutine 
    properties (Access = public)


        Settings
        Gate
        Timetrace

        runtime = 1.200
        threshold =       2e-09

    end

    methods (Access = public)

        function obj = needleRoutine(settings)

            obj.Settings = settings;
            obj.Settings.type = 'Gatesweep';

            obj.Gate.V_per_V = 10;          % V/V0
            obj.Gate.Amplitude = 10; %V
            obj.Gate.Frequency = 10; %Hz
            obj.Gate.points_per_cycle = 100;
            obj.Gate.output = 2;              % AO channel

            obj.Gate.process = 'Waveform_AO';
            obj.Gate.type = 'Gatesweep';

            obj.Timetrace.runtime = obj.runtime; %s
            obj.Timetrace.scanrate = 500000;       % Hz
            obj.Timetrace.points_av = 1 * obj.Timetrace.scanrate / (obj.Gate.Frequency * obj.Gate.points_per_cycle) ;        % points
            obj.Timetrace.model = 'ADwin';
            obj.Timetrace.settling_time = 0;
            obj.Timetrace.settling_time_autoranging = 200;

            %Gate Waveform
            obj.Gate.time = linspace(1 / (obj.Gate.Frequency * obj.Gate.points_per_cycle), obj.Timetrace.runtime + 0.2, obj.Gate.Frequency * obj.Gate.points_per_cycle * (obj.Timetrace.runtime + 0.2))';
            obj.Gate.bias = obj.Gate.Amplitude * sin(2*pi*obj.Gate.Frequency * obj.Gate.time); %V
            obj.Gate.scanrate = obj.Gate.Frequency * obj.Gate.points_per_cycle;

            [obj.Settings, obj.Timetrace] = get_readAI_process(obj.Settings, obj.Timetrace);
            obj.Settings = Init_ADwin_load_process(obj.Settings, obj.Timetrace, obj.Gate);

        end

        function obj = startRoutine(obj)


            % Start sine wave
            obj.Gate = Run_sweepAO(obj.Settings, obj.Gate);

            % Run Timetrace
            obj.Gate.index = 1;
            obj.Gate.repeat = 1;

            obj.Timetrace = Run_timetrace(obj.Settings, obj.Timetrace);

        end

    end

end
