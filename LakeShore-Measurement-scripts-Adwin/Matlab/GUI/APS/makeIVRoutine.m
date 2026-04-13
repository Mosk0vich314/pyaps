classdef makeIVRoutine % < handle
    properties (Access = public)

        Settings
        IV
        Gate
        Gate_fixed

    end

    methods (Access = public)

        function obj = makeIVRoutine(settings)

            obj.Settings = settings;
            obj.Settings.type = 'IV';

            obj.IV.V_per_V = 1;          % V/V0
            obj.IV.startV = 0;            % V
            obj.IV.maxV = 0.5;          % V
            obj.IV.minV = -0.5;        % V
            obj.IV.points = 501;           % what happens for >   4000 points?? obj.IV.minV = -obj.IV.maxV;         % V
            obj.IV.sweep_dir = 'up';
            obj.IV.maxI = 0;            % A

            obj.IV.repeat = 1;
            obj.IV.scanrate = 450000;       % Hz
            obj.IV.BW_adjuster = 1;        % see av_points for explanation
            obj.IV.settling_time = 0;      % ms
            obj.IV.settling_time_autoranging = 200;      % ms

            obj.IV.output = 1;              % AO channel
            obj.IV.process_number = 1;

            obj.Gate.initV = 0;          % V
            obj.Gate.targetV = 0;            % V
            obj.Gate.endV = 0;            % V
            obj.Gate.ramp_rate = 1;       % V/s
            obj.Gate.waiting_time = 0;     % s after setting obj.Gate.setV  %%can this be implemented via obj.Gate.settling_time?
            obj.Gate.V_per_V = 1;          % V/V0
            obj.Gate.output = 2;            % AO channel
            obj.Gate.process_number = 3;
            obj.Gate.process = 'Fixed_AO';

            % Initialize
            obj.Settings = Init(obj.Settings);

            % Initialize ADwin
            [obj.Settings, obj.IV] = get_sweep_process(obj.Settings, obj.IV);
            obj.Settings = Init_ADwin_load_process(obj.Settings, obj.IV, obj.Gate);
            
            % Initialize empty bias array
            obj.IV.bias = [];


        end

        function saveClassData(obj, filename)
            % Construct a structured array with all necessary data
            dataToSave.Settings = obj.Settings;
            dataToSave.IV = obj.IV;
            dataToSave.Gate = obj.Gate;

            % Save the structured array to a MAT file
            save(filename, '-struct', 'dataToSave');
        end


        function obj = startRoutine(obj, devID, path)

            obj.IV = rmfield(obj.IV,'bias');
            obj.IV.dV = obj.IV.maxV / obj.IV.points *2;    % V
            obj.IV.points_av = obj.IV.BW_adjuster * obj.IV.scanrate / 50;        % points

            obj.Settings.save_dir = path;
            obj.Settings.sample = devID;

            % set gate voltage
            obj.Gate.startV = obj.Gate.initV;          % V
            obj.Gate.setV = obj.Gate.targetV;            % V

            fprintf('%s - Ramping obj.Gate to %1.2fV...', datetime('now'), obj.Gate.setV)
            obj.Gate = Apply_fixed_voltage(obj.Settings, obj.Gate);
            fprintf('done\n')

            % wait after gate set
            fprintf('%s - obj.Gate Settling...', datetime('now'))
            pause(obj.Gate.waiting_time)
            fprintf('done\n')

            % run measurement
            for i = 1:obj.IV.repeat

                % run obj.IV
                fprintf('%s - Running I(V) - %1.0f/%1.0f...', datetime('now'), i, obj.IV.repeat)
                obj.IV.index = i;
                obj.IV = Run_sweep(obj.Settings, obj.IV);

                % get current and show plot
                obj.IV = Realtime_sweep(obj.Settings, obj.IV, obj.Settings.type);

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

           
            % set gate voltage back to end voltage
            obj.Gate.startV = obj.Gate.targetV;          % V
            obj.Gate.setV = obj.Gate.endV;            % V

            fprintf('%s - Ramping obj.Gate to %1.2fV...', datetime('now'), obj.Gate.setV)
            obj.Gate = Apply_fixed_voltage(obj.Settings, obj.Gate);
            fprintf('done\n')          

            % plot surface plot
            if obj.IV.repeat > 1
                obj.IV = split_data_sweep(obj.Settings, obj.IV);
                Surf_sweep(obj.Settings, obj.IV, 'Surface plot')
                filename = sprintf('%s\\%s_%s_%s.png', obj.Settings.save_dir, obj.Settings.filename, obj.Settings.sample, obj.Settings.type);
                fig = findobj('Type', 'Figure', 'Name', 'Surface plot');
                saveas(fig, filename);
            end

            % plot density plot
            if obj.IV.repeat > 1
                Density_sweep(obj.Settings, obj.IV, 'Density plot')
                filename = sprintf('%s\\%s_%s_density_%s.png', obj.Settings.save_dir, obj.Settings.filename, obj.Settings.sample, obj.Settings.type);
                fig = findobj('Type', 'Figure', 'Name', 'Density plot');
                saveas(fig, filename);
            end
            pause(1)

        end

    end

end
