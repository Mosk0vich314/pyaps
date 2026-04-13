classdef Temperature_controller_Oxford_ITC < handle

    properties (SetAccess = private)
        serial_address
    end

    properties (Transient)
        device
    end

    properties
        sensors = ["DB7.T1", "DB6.T1", "MB1.T1", "DB8.T1", "MB0.H1", "DB1.H1", "DB2.H1", "DB3.P1", "DB4.G1"];
        % 1. DB7.T1 --> He high     - Cernox
        % 2. DB6.T1 --> He 4 pot    -
        % 3. MB1.T1 --> He 3 sorb   - Allen-Bradley
        % 4. DB8.T1 --> He low      - RuO2
    end

    methods

        function T_controller = Temperature_controller_Oxford_ITC(address)
            T_controller.serial_address = address;
            T_controller.device = serial(address);
            set(T_controller.device,'Timeout',2)
            fopen(T_controller.device);
        end

        %% identify device --- WORKS

        function output = identify(T_controller)
            try;fclose(T_controller.device);end
            fopen(T_controller.device);
            fprintf(T_controller.device,"*IDN?");
            output = strtrim(fscanf(T_controller.device));
            fclose(T_controller.device);
        end

        %% clear interface command

        function cls(T_controller)
            try;fclose(T_controller.device);end
            fopen(T_controller.device);
            fprintf(T_controller.device,"*CLS");
            fclose(T_controller.device);
        end

        %% set power-up settings

        function reset(T_controller)
            try;fclose(T_controller.device);end
            fopen(T_controller.device);
            fprintf(T_controller.device,"*RST");
            fclose(T_controller.device);
        end


        %% get PID value --- WORKS

        function output = get_PID(T_controller, sensor)
            pid_val_str = ["P", "I", "D"];
            output = [0, 0, 0];
            try;fclose(T_controller.device);end
            fopen(T_controller.device);
            for c = 1:length(output)
                fprintf(T_controller.device, sprintf("READ:DEV:%s:TEMP:LOOP:%c", T_controller.sensors{sensor}, pid_val_str(c)));
                device_answer = fscanf(T_controller.device);
                ans_arr = strsplit(device_answer, ":");
                output(c) = str2double(ans_arr(length(ans_arr)));
            end
            fclose(T_controller.device);
        end

        % To Do
        % check if input 'sensor' is a temp sensor


        %% set PID --- WORKS

        function set_PID(T_controller, sensor, P, I, D)
            try;fclose(T_controller.device);end
            pid_val_str = ["P", "I", "D"];
            input = [P, I, D];
            fopen(T_controller.device);
            for c = 1:length(input)
                fprintf(T_controller.device, sprintf("SET:DEV:%s:TEMP:LOOP:%s:%5.5f", T_controller.sensors{sensor}, pid_val_str(c), input(c)));
            end
            fclose(T_controller.device);
        end

        % To Do
        % check if input 'sensor' is a temp sensor


        %% set heater off --- WORKS

        function set_heater_off(T_controller, sensor)
            try;fclose(T_controller.device);end
            fopen(T_controller.device);
            fprintf(T_controller.device, sprintf("SET:DEV:%s:TEMP:LOOP:HSET:0", T_controller.sensors{sensor}));
            fclose(T_controller.device);
        end

        % To Do
        % check if input 'sensor' is a temp sensor

        %% set heater on

        function set_heater_on(T_controller, sensor, power)
            try;fclose(T_controller.device);end
            fopen(T_controller.device);
            fprintf(T_controller.device, sprintf("SET:DEV:%s:TEMP:LOOP:HSET:%01d",T_controller.sensors{sensor},power));
            fclose(T_controller.device);
        end
        % To Do
        % check if temperature range parameter is needed
        % check if 'sensor' is a temp sensor%% set heater on


        %% get heater power
        function power = get_heater_power(T_controller, sensor)
            try;fclose(T_controller.device);end
            fopen(T_controller.device);
            fprintf(T_controller.device, sprintf("READ:DEV:%s:TEMP:LOOP:HSET",T_controller.sensors{sensor}));
            tmp = fscanf(T_controller.device);
            power = regexp(tmp, 'HSET:(\d+)','tokens');
            power = str2double(power{1}{1});
            fclose(T_controller.device);
        end
        % To Do
        % check if temperature range parameter is needed
        % check if 'sensor' is a temp sensor


        %% set T setpoint --- WORKS

        function set_T_setpoint(T_controller, sensor, t_setpoint)
            try;fclose(T_controller.device);end
            fopen(T_controller.device);
            fprintf(T_controller.device,sprintf("SET:DEV:%s:TEMP:LOOP:ENAB:ON", T_controller.sensors{sensor}));
            fprintf(T_controller.device,sprintf("SET:DEV:%s:TEMP:LOOP:TSET:%d", T_controller.sensors{sensor}, t_setpoint));
            fclose(T_controller.device);

            if sensor == 1 && t_setpoint > 201
                pause(6)
                set_heater_on(T_controller, 2, min(100,(t_setpoint-200))) % Oliver (t_setpoint-200)/2
                %set_heater_on(T_controller, 3, min(t_setpoint-200,100)) %
                %Oliver
            else
                sensor == 1 && t_setpoint < 201
                pause(6)
                set_heater_on(T_controller, 2, min(100, 0))
                %fprintf(T_controller.device,sprintf("SET:DEV:%s:TEMP:LOOP:TSET:%d",
                %T_controller.sensors{2}, 4)); %% Oliver
            end

        end

        % To Do
        % check if input 'sensor' is a temp sensor
        % check if input 't_setpoint' is a number

        %% wait T setpoint --- DONE
        function [time,error] = wait_T_setpoint(varargin, sensor)
            try;fclose(T_controller.device);end
            T_controller = varargin{1};
            output = varargin{2};
            if length(varargin)>2
                window_size_time = varargin{3};
            else
                window_size_time = 10.0;
            end
            if length(varargin)>3
                T_stability = varargin{4};
            else
                T_stability = 0.05;
            end
            if length(varargin)>4
                T_deviation = varargin{5};
            else
                T_deviation = 0.05;
            end
            if length(varargin)>5
                Timeout = varargin{6};
            else
                Timeout = 900.0;
            end

            fopen(T_controller.device);
            window_size = round(window_size_time / 0.01375);
            T_setpoint = get_T_setpoint(T_controller, sensor);

            T_array = zeros(1,window_size);
            run = true;
            tStart = tic;
            idx={'A','B','C','D'};

            while run
                T_new = get_temp(T_controller, sensor);
                %       disp(T_new)
                T_array  = [T_array T_new];
                T_array(1) = [];

                T_mean = mean(T_array);
                T_dev = std(T_array);

                %       [toc(tStart) T_new T_setpoint (abs(T_mean - T_setpoint) < T_stability) (T_dev < T_deviation)]
                if (abs(T_mean - T_setpoint) < T_stability) && (T_dev < T_deviation)
                    run = false;
                    error = 0;
                    time = toc(tStart);
                end
                if toc(tStart) > Timeout
                    run = false;
                    error = 1;
                    time = toc(tStart);
                end
            end
            fclose(T_controller.device);
        end

        %% get T setpoint --- WORKS

        function output = get_T_setpoint(T_controller, sensor)
            try;fclose(T_controller.device);end
            fopen(T_controller.device);
            fprintf(T_controller.device,sprintf("READ:DEV:%s:TEMP:LOOP:TSET", T_controller.sensors{sensor}));
            value = fscanf(T_controller.device);
            splitted_val = strsplit(value, ":");
            target_arr = splitted_val(length(splitted_val));
            target = strsplit(target_arr{1}, "K");
            output = str2double(target{1});
            fclose(T_controller.device);
        end

        %% get Temperature --- WORKS

        function output = get_temp(T_controller, sensor)
            try;fclose(T_controller.device);end
            fopen(T_controller.device);
            fprintf(T_controller.device,sprintf("READ:DEV:%s:TEMP:SIG:TEMP", T_controller.sensors{sensor}));
            value = fscanf(T_controller.device);
            splitted_val = strsplit(value, ":");
            target_arr = splitted_val(length(splitted_val));
            target = strsplit(target_arr{1}, "K");
            output = str2double(target{1});
            fclose(T_controller.device);
        end

    end

end