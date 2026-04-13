classdef makeStabilityRoutine % < handle
    properties (Access = public)


        Settings
        IV
        Gate
        Gate_fixed

        stopFlag = 0

    end

    methods (Access = public)

        function obj = makeStabilityRoutine(settings)

            obj.Settings = settings;
            obj.Settings.type = 'Stability';

            obj.IV.V_per_V = 1;          % V/V0
            obj.IV.startV = 0;            % V
            obj.IV.maxV = 0.2;      % V
            obj.IV.minV = -obj.IV.maxV;        % V
            obj.IV.points = 1001;           % what happens for >   4000 points?? obj.IV.minV = -obj.IV.maxV;         % V
            obj.IV.sweep_dir = 'up';

            obj.IV.repeat = 1;
            obj.IV.scanrate = 450000;
            obj.IV.BW_adjuster = 1;        % see av_points for explanation
            obj.IV.settling_time = 0;      % ms
            obj.IV.settling_time_autoranging = 200;      % ms
            obj.IV.maxI = 0;        % A

            obj.IV.output = 1;              % AO channel
            obj.IV.process_number = 1;

            obj.IV.clim_lin = [];%[-3e-7 3e-7 0 5e-7]; %[-1e-11 1e-11 0 5e-11];
            obj.IV.clim_log = [];%[-13 -6 -10 -5]; % [-13 -11 -12 -9];

            obj.Gate.initV = 0;          % V
            obj.Gate.minV = -0.5;            % V
            obj.Gate.maxV = 0.5;  
            obj.Gate.dV = 0.001;            % V
            obj.Gate.endV = 0.0;            % V
            obj.Gate.ramp_rate = 0.5;       % V/s
            obj.Gate.V_per_V = 10;            % V/V0
            obj.Gate.sweep_dir = 'up';
            obj.Gate.waiting_time = 0.1;

            obj.Gate.output = 2;            % AO channel
            obj.Gate.process_number = 3;
            obj.Gate.process = 'Fixed_AO';

            % Initialize
            obj.Settings = Init(obj.Settings);

            % Initialize ADwin
            [obj.Settings, obj.IV] = get_sweep_process(obj.Settings, obj.IV);
            obj.Settings = Init_ADwin_load_process(obj.Settings, obj.IV, obj.Gate);
            
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

            % obj.IV = rmfield(obj.IV,'bias');
            obj.IV.dV = obj.IV.maxV / obj.IV.points *2;    % V
            obj.IV.points_av = obj.IV.BW_adjuster * obj.IV.scanrate / 50;        % points

            obj.Settings.save_dir = path;
            obj.Settings.sample = devID;

            %% make gate vector
            obj.Gate.startV = obj.Gate.initV;
            obj.Gate.voltage = obj.Gate.minV:obj.Gate.dV:obj.Gate.maxV; %obj.Gate upsweep
            if  strcmp(obj.Gate.sweep_dir, 'down')
                obj.Gate.voltage = fliplr(obj.Gate.voltage);
            end

            obj.IV.repeat = length(obj.Gate.voltage);

            % run measurement
            for i = 1:obj.IV.repeat
               
                if obj.stopFlag

                    obj.stopFlag = 0;
                    break

                end
                
                %% set gate voltage
                obj.Gate.setV = obj.Gate.voltage(i);
                obj.Gate = Apply_fixed_voltage(obj.Settings, obj.Gate);

                % wait after gate set
                fprintf('obj.Gate Settling\n')
                pause(obj.Gate.waiting_time)
                if i == 1
                    pause(2 * obj.Gate.waiting_time)
                end

                %% run IV
                fprintf('Running I(V)  No. : %01d /%01d\n Vg = %1.2f', i, obj.IV.repeat, obj.Gate.voltage(i) )
                obj.IV.index = i;
                obj.IV = Run_sweep(obj.Settings, obj.IV);

                % get current and show plot
                obj.IV.x_axis = obj.Gate.voltage;
                obj.IV = Realtime_sweep3D(obj.Settings, obj.IV, obj.Settings.type);
                fprintf('done\n')

                %% prepare for next round
                obj.Gate.startV = obj.Gate.setV;

                % if obj.stopFlag
                % 
                %     obj.stopFlag = 0;
                %     break
                % 
                % end

            end

            %% save figure
            for i = 1:numel(obj.Settings.sample)
                fig = obj.IV.handles(i).fig;
                filename = sprintf('%s/%s_%s_%s_%1.0fK', obj.Settings.save_dir, obj.Settings.filename, obj.Settings.sample{i}, obj.Settings.type, obj.Settings.T);

                saveas(fig, [filename '.png'])
                saveas(fig, [filename '.fig'])
            end

            Samplename = obj.Settings.sample{1}; for i = 2:numel(obj.Settings.sample); Samplename = [Samplename '-' obj.Settings.sample{i}]; end
            filename = sprintf('%s/%s_%s_%s_%1.0fK.mat', obj.Settings.save_dir, obj.Settings.filename, Samplename, obj.Settings.type, obj.Settings.T);

            obj.IV = rmfield(obj.IV,'handles');
            obj.saveClassData(filename);


            %% set gate voltage back to start voltage
            obj.Gate.startV = obj.Gate.setV;
            obj.Gate.setV = obj.Gate.endV;
            obj.Gate = Apply_fixed_voltage(obj.Settings, obj.Gate);

            % % plot surface plot
            % IV = split_data_sweep(Settings, IV);
            % close all hidden;
            % Surf_stability(Settings, IV, Gate, Settings.type)
            % fig = findobj('Name', Settings.type);
            % for i = 1:numel(Settings.sample)
            %     saveas(figure(i), sprintf('%s/%s_%s_%s_%s.png', Settings.save_dir, Settings.filename, Settings.sample{i}, Settings.type, Gate.sweep_dir))
            %     saveas(figure(i), sprintf('%s/%s_%s_%s_%s.fig', Settings.save_dir, Settings.filename, Settings.sample{i}, Settings.type, Gate.sweep_dir))
            % end
            % 
            % toc
            % load train, sound(y,Fs)
            % reset gate if needed via reset_gate(Settings,Gate)

            pause(1)

        end

        % function obj = stopRoutine(obj)
        % 
        %    obj.stopFlag = 1;
        % 
        % end

    end

end
