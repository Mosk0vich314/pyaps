classdef makeGateSweepRoutine % < handle
    properties (Access = public)


        Settings
        Gate
        Bias
        Gate_fixed


    end

    methods (Access = public)

        function obj = makeGateSweepRoutine(settings)

            obj.Settings = settings;
            obj.Settings.type = 'Gatesweep';

            obj.Gate.V_per_V = 10;          % V/V0
            obj.Gate.startV = 0;            % V
            obj.Gate.maxV = 50;
            obj.Gate.minV = -50;        % V
            obj.Gate.points = 1001;           % what happens for >   4000 points?? obj.IV.minV = -obj.IV.maxV;         % V
            obj.Gate.sweep_dir = 'up';

            obj.Gate.repeat = 1;
            obj.Gate.scanrate = 450000;
            obj.Gate.BW_adjuster = 1;        % see av_points for explanation
            obj.Gate.settling_time = 0;      % ms
            obj.Gate.settling_time_autoranging = 300;      % ms

            obj.Gate.output = 2;              % AO channel
            obj.Gate.process_number = 1;

            obj.Bias.initV = 0;          % V
            obj.Bias.minV = 0.1;            % V
            obj.Bias.maxV = 0.1;  
            obj.Bias.dV = 0.1;            % V
            obj.Bias.endV = 0;            % V
            obj.Bias.ramp_rate = 0.1;       % V/s
            obj.Bias.V_per_V = 1;            % V/V0

            obj.Bias.output = 1;            % AO channel
            obj.Bias.process_number = 3;
            obj.Bias.process = 'Fixed_AO';

            % Initialize
            obj.Settings = Init(obj.Settings);

            % Initialize ADwin
            [obj.Settings, obj.Gate] = get_sweep_process(obj.Settings, obj.Gate);
            obj.Settings = Init_ADwin_load_process(obj.Settings, obj.Gate, obj.Bias);
            


        end

        function saveClassData(obj, filename)
            % Construct a structured array with all necessary data
            dataToSave.Settings = obj.Settings;
            dataToSave.Gate = obj.Gate;
            dataToSave.Bias = obj.Bias;

            % Save the structured array to a MAT file
            save(filename, '-struct', 'dataToSave');
        end


        function obj = startRoutine(obj, devID, path)

            obj.Gate.dV = obj.Gate.maxV / obj.Gate.points *2;    % V
            obj.Gate.points_av = obj.Gate.BW_adjuster * obj.Gate.scanrate / 50;        % points

            obj.Settings.save_dir = path;
            obj.Settings.sample = devID;

            %% generate bias vector
            obj.Bias.voltage = obj.Bias.minV:obj.Bias.dV:obj.Bias.maxV;
            obj.Bias.N_voltage = length(obj.Bias.voltage);

            obj.Bias.startV = obj.Bias.initV;          % V
            obj.Gate.repeat = obj.Bias.N_voltage;

            % run measurement
            for i = 1:obj.Gate.repeat

                %% set bias voltage
                obj.Bias.setV = obj.Bias.voltage(i);
                fprintf('%s - Ramping bias...', datetime('now'))
                obj.Bias = Apply_fixed_voltage(obj.Settings, obj.Bias);
                fprintf('done\n')
                obj.Bias.startV = obj.Bias.setV;          % V
                pause(2)

                %% run IV % actually run gate-sweep
                fprintf('%s - Running gate sweep - %1.0f/%1.0f...', datetime('now'), i, obj.Gate.repeat)
                obj.Gate.index = i;
                obj.Gate = Run_sweep(obj.Settings, obj.Gate);

                %% get current and show plot
                obj.Gate = Realtime_sweep(obj.Settings, obj.Gate, obj.Settings.type);

                fprintf('done\n')

            end

            % save figure
            fig = findobj('Name', obj.Settings.type);
            filename = sprintf('%s\\%s_%s_%s_%1.0fK', obj.Settings.save_dir, obj.Settings.filename, obj.Settings.sample, obj.Settings.type, obj.Settings.T);
            saveas(fig, [filename '.png'])
            saveas(fig, [filename '.fig'])

            % save data
            % Settings = obj.Settings;
            % IV = obj.IV;
            % Gate = obj.Gate;
            % Save_data(Settings, IV, Gate, [filename '.mat'])
            obj.saveClassData(filename);


            %% set gate voltage back to start voltage
            obj.Bias.setV = obj.Bias.endV;
            obj.Bias = Apply_fixed_voltage(obj.Settings, obj.Bias);

            %% plot surface plot
            if obj.Gate.repeat > 1
                obj.Gate = split_data_sweep(obj.Settings, obj.Gate);
                Surf_sweep(obj.Settings, obj.Gate, 'Surface plot')
            end

            pause(1)

        end

    end

end
