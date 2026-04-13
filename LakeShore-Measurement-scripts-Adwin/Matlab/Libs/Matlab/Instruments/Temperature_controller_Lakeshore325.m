classdef Temperature_controller_Lakeshore325 < handle
    
    properties (SetAccess = private)
        serial_address
    end
    
    properties (Transient)
        device
    end
    
    methods
        
        function T_controller = Temperature_controller_Lakeshore325(address)
            T_controller.serial_address = address;
            if startsWith(address,'GPIB')
                tokens = regexp(address,'GPIB(\d+)::(\d+)::','tokens');
                board = str2double(tokens{1}{1});
                number = str2double(tokens{1}{2});
                T_controller.device = gpib('ni',board,number);
            else
                T_controller.device = visa('ni',address);
            end
            set(T_controller.device,'Timeout',2)
            fopen(T_controller.device);
        end
        
        %% identify device
        function output = identify(T_controller)
            try;fclose(T_controller.device);end
            fopen(T_controller.device);
            fprintf(T_controller.device,"*IDN?");
            output = fscanf(T_controller.device);
            fclose(T_controller.device);
        end
        
         %% close connection 
        function output = close(T_controller)
            try;fclose(T_controller.device);end
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
        
        %% autotune for PID settings power-up settings
        function autotune(varargin)
            try;fclose(T_controller.device);end
            if length(varargin) == 1
                disp('autotune <output> <mode>')
                disp('output: #PID channel')
                disp('mode:')
                disp('0. P only')
                disp('1. P I only')
                disp('2. P I D')
            elseif length(varargin)==3
                T_controller = varargin{1};
                output = varargin{2};
                mode = varargin{3};
                
                fopen(T_controller.device);
                fprintf(T_controller.device,sprintf("ATUNE %1.0f %1.0f",output, mode));
                fclose(T_controller.device);
            else
                disp('error input')
            end
        end
        
        %% get PID value
        function [P,I,D] = get_PID(T_controller, output)
            try;fclose(T_controller.device);end
            fopen(T_controller.device);
            fprintf(T_controller.device,sprintf("PID? %1.0f",output));
            output = fscanf(T_controller.device);
            tmp=strsplit(output,',');
            P = str2double(tmp{1});
            I = str2double(tmp{2});
            D = str2double(tmp{3});
            fclose(T_controller.device);
        end
        
        %% set power-up settings
        function set_PID(T_controller,output,P,I,D)
            try;fclose(T_controller.device);end
            fopen(T_controller.device);
            fprintf(T_controller.device,sprintf("PID %1.0f %1.0f %1.0f %1.0f",output,P,I,D));
            fclose(T_controller.device);
        end
        
        %% get heater range settings
        function output = get_heater_range(T_controller,output)
            try;fclose(T_controller.device);end
            fopen(T_controller.device);
            fprintf(T_controller.device,sprintf("RANGE? %1.0f ",output));
            output = str2double(fscanf(T_controller.device));
            fclose(T_controller.device);
        end
        
        %% set heater off
        function set_heater_off(T_controller,output)
            try;fclose(T_controller.device);end
            fopen(T_controller.device);
            fprintf(T_controller.device,sprintf("RANGE % 0 ",output));
            fclose(T_controller.device);
        end
        
        %% set heater on
        function set_heater_on(T_controller, output, T)
            try;fclose(T_controller.device);end
            fopen(T_controller.device);
            if T<20
                range = 1;
            else
                range = 2;
            end
            fprintf(T_controller.device, sprintf("RANGE %1.0f %1.0f ",output,range));
            fclose(T_controller.device);
        end
        
        %% get zones
        function [upper_bound,P,I,D,range,rate] = get_zones(T_controller,output,zone)
            try;fclose(T_controller.device);end
            fopen(T_controller.device);
            fprintf(T_controller.device,sprintf("ZONE? %1.0f %1.0f ",output,zone));
            string = fscanf(T_controller.device);
            fclose(T_controller.device);
            str=strsplit(string,',');
            upper_bound = str2double(str{1});
            P = str2double(str{2});
            I = str2double(str{3});
            D = str2double(str{4});
            range = str2double(str{6});
            rate = str2double(str{7});
        end
        
        %% set zones
        function set_zones(T_controller,output,zone,upper_bound,P,I,D,range,rate)
            try;fclose(T_controller.device);end
            input = 0; 
            m_out = 0;
            fopen(T_controller.device);
            fprintf(T_controller.device,sprintf("ZONE %1.0f  %1.0f %1.0f %1.0f %1.0f %1.0f %1.0f %1.0f ",output,zone,upper_bound,P,I,D,m_out,range,input,rate));
            fclose(T_controller.device);
        end
        
        %% set heater range settings
        function set_heater_range(varargin)
            try;fclose(T_controller.device);end
            if length(varargin) == 1
                disp('RANGE <output> <range>')
                disp('output: #PID channel')
                disp('range:')
                disp('0. off')
                disp('1. low')
                disp('2. high')
            elseif length(varargin)==3
                T_controller = varargin{1};
                output = varargin{2};
                range = varargin{3};
                
                try;fclose(T_controller.device);end
                fopen(T_controller.device);
                fprintf(T_controller.device,sprintf("RANGE %1.0f %1.0f",output, range));
                fclose(T_controller.device);
            else
                disp('error input')
            end
            
        end
        
        %% set T setpoint
        function set_T_setpoint(T_controller, output, T_setpoint)
            try;fclose(T_controller.device);end
            fopen(T_controller.device);
            fprintf(T_controller.device,sprintf("SETP %1.3f %1.3f ", output, T_setpoint));
            fclose(T_controller.device);
            
            set_heater_on(T_controller, output, T_setpoint)
            
        end
        
        %% wait T setpoint
        function [time,error] = wait_T_setpoint(varargin)
            T_controller = varargin{1};
            output = varargin{2};
            T_setpoint = varargin{3};
            if length(varargin)>3
                window_size_time = varargin{4};
            else
                window_size_time = 10.0;
            end
            if length(varargin)>4
                T_stability = varargin{5};
            else
                T_stability = 0.05;
            end
            if length(varargin)>5
                T_deviation = varargin{6};
            else
                T_deviation = 0.05;
            end
            if length(varargin)>6
                Timeout = varargin{7};
            else
                Timeout = 900.0;
            end
            
            try;fclose(T_controller.device);end
            fopen(T_controller.device);
            window_size = round(window_size_time / 0.5);
                       
            T_array = zeros(1,window_size);
            run = true;
            tStart = tic;
            idx={'A','B','C','D'};
            
            while run
                fprintf(T_controller.device,sprintf("KRDG? %s",idx{output}));
                T_new = str2double(fscanf(T_controller.device));
%                 disp(T_new)
                T_array  = [T_array T_new];
                T_array(1) = [];
                
                if sum(T_array == 0) == 0
                    T_mean = mean(T_array);
                    T_dev = std(T_array);
                    
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
                pause(0.5)
            end
            fclose(T_controller.device);
        end
        
        %% get T setpoint
        function output = get_T_setpoint(T_controller,output)
            try;fclose(T_controller.device);end
            fopen(T_controller.device);
            fprintf(T_controller.device,sprintf("SETP? %1.3f ",output));
            output = str2double(fscanf(T_controller.device));
            fclose(T_controller.device);
        end
        
        
        %% get Temperature
        function output = get_temp(T_controller,output)
            try;fclose(T_controller.device);end
            fopen(T_controller.device);
            idx={'A','B','C','D'};
            fprintf(T_controller.device,sprintf("KRDG? %s",idx{output}));
            output = str2double(fscanf(T_controller.device));
            fclose(T_controller.device);
        end
        
        
        %% calibration files
        function set_calibration(T_controller, curve, filename)
           
            fid=fopen(filename);
            data=textscan(fid,'%s %s');  %f32 for single precision
            fclose(fid);
            
            Model = data{1}{2};
            SerialNumber = data{1}{4};
            Type = str2double(data{1}{6});
            SetPoint_limit = str2double(data{1}{8});
            Coefficient = str2double(data{1}{10});
            
            fopen(T_controller.device);
            fprintf(T_controller.device,sprintf('CRVHDR %1.0f,%s,%s,%1.0f,%1.0f,%1.0f[term]', curve, Model, SerialNumber, Type, SetPoint_limit, Coefficient));
            fclose(T_controller.device);
                        
            fid=fopen(filename);
            data=textscan(fid,'%f %f %f ','HeaderLines',9);  %f32 for single precision
            fclose(fid);
            
            Index = data{1};
            Resistance = data{2};
            Temperature = data{3};
            
            N_points = length(Index);
            
            fopen(T_controller.device);
            for i=1:N_points
                fprintf(T_controller.device,sprintf('CRVPT %1.0f,%1.0f,%1.4f,%1.4f[term]', curve, Index(i), Resistance(i), Temperature(i)));
                
            end
            fclose(T_controller.device);
            
        end
        
        function output = get_curve_header(T_controller, curve)
            try;fclose(T_controller.device);end
            fopen(T_controller.device);
            fprintf(T_controller.device,sprintf('CRVHDR? %1.0f[term]', curve));
            output = strtrim(fscanf(T_controller.device));
            fclose(T_controller.device);
        end
        
        function set_curve_header(T_controller, curve, name, serialnumber, format, limit, coefficient)
            try;fclose(T_controller.device);end
            fopen(T_controller.device);
            fprintf(T_controller.device,sprintf('CRVHDR %1.0f,%s,%s,%1.0f,%1.0f,%1.0f[term]', curve, name, serialnumber, format, limit, coefficient));
            fclose(T_controller.device);

        end
        
        function set_curve(T_controller, input, curve)
            try;fclose(T_controller.device);end
            inputs = {'A','B'};
            fopen(T_controller.device);
            fprintf(T_controller.device,sprintf('INCRV %s,%1.0f',inputs{input}, curve));
            fclose(T_controller.device);
        end
        
        function output = get_curve(T_controller)
            try;fclose(T_controller.device);end
            fopen(T_controller.device);
            fprintf(T_controller.device,'INCRV?');
            output = str2double(fscanf(T_controller.device));

            fclose(T_controller.device);
        end
        
        function data = get_calibration(T_controller, curve)
            fopen(T_controller.device);
            data = [];
            for i=1:200
                try
                    fprintf(T_controller.device,sprintf('CRVPT? %1.0f,%1.0f[term] ', curve, i));
                    output = strtrim(fscanf(T_controller.device));
                    output = regexprep(output,';','');
                    data(i,:) = str2double(strsplit(output,','));
                end
            end
            fclose(T_controller.device);
            data(sum(data,2)==0,:)=[];
            
        end
        
        
    end
    
end