classdef Attocube_controller < handle
    
    properties (SetAccess = private)
        serial_address
        axis
    end
    
    properties (Transient)
        device
    end
    
    methods (Static)
        
        % write and read device
        function [output, error] = ask(Attocube,command)
            try fclose(Attocube.device);end
            fopen(Attocube.device);
            fprintf(Attocube.device,command);
            fscanf(Attocube.device);
            output = fscanf(Attocube.device,'%s');
            error = fscanf(Attocube.device,'%s');
            error = ~strncmp(error,'OK',2);
            fclose(Attocube.device);
        end
        
        % write to device
        function [error] = write(Attocube,command)
            try fclose(Attocube.device);end
            fopen(Attocube.device);
            fprintf(Attocube.device,command);
            fscanf(Attocube.device);
            err = fscanf(Attocube.device,'%s');
            error = ~strncmp(err,'OK',2);
            fclose(Attocube.device);
        end
        
        % convert frequency to speed in um/s
        function speed = convert_frequency_to_speed(varargin)
            freq = varargin{1};
            if freq > 10000; freq = 10000; end
            if length(varargin)>1; stepsize_min = varargin{2}; else; stepsize_min = 50e-9; end
            if stepsize_min > 1e-3; stepsize_min = stepsize_min * 1e-9; end
            speed = freq * stepsize_min * 1e6;
        end
        
        % convert frequency to speed in um/s
        function freq = convert_speed_to_frequency(varargin)
            speed = varargin{1};
            if length(varargin)>1; stepsize = varargin{2}; else; stepsize = 50e-9; end
            if speed > 1e-2; speed = speed * 1e-6; end
            freq = speed / stepsize;
        end
        
    end
    
    methods
        
        function Attocube = Attocube_controller(serial_address, axis)
            Attocube.serial_address = serial_address;
            Attocube.axis = axis;
            Attocube.device=serial(serial_address,'BaudRate',9600);
        end
        
        %% get functions
        % identify device
        function [output, error] = identify(Attocube)
            [output, error] = Attocube.ask(Attocube,sprintf('getser %01d', Attocube.axis));
        end
        
        % get mode
        function [output, error] = get_mode(Attocube)
            [output, error] = Attocube.ask(Attocube,sprintf('getm %01d', Attocube.axis));
            output = regexp(output,'mode=(\w+)','tokens');
            output=output{1}{1};
        end
        
        % get frequency
        function [output, error] = get_frequeny(Attocube)
            [output, error] = Attocube.ask(Attocube,sprintf('getf %01d', Attocube.axis));
            output = regexp(output,'\w+=([0-9]+)','tokens');
            output=str2double(output{1}{1});
        end
        
        % get amplitude
        function [output, error] = get_voltage(Attocube)
            [output, error] = Attocube.ask(Attocube,sprintf('getv %01d', Attocube.axis));
            output = regexp(output,'\w+=([0-9]+)','tokens');
            output=str2double(output{1}{1});
        end
        
        % get get_output voltage
        function [output, error] = get_outputV(Attocube)
            [output, error] = Attocube.ask(Attocube,sprintf('geto %01d', Attocube.axis));
            output = regexp(output,'\w+=([0-9]+)','tokens');
            output=str2double(output{1}{1});
        end
        
        % get capacitance
        function [output, error] = get_capacitance(Attocube)
            Attocube.write(Attocube,sprintf('setm %01d gnd', Attocube.axis));
            Attocube.write(Attocube,sprintf('setm %01d cap', Attocube.axis));
            Attocube.write(Attocube,'capw');
            [output, error] = Attocube.ask(Attocube,sprintf('getc %01d', Attocube.axis));
            output = regexp(output,'\w+=([.0-9]+)([a-z])','tokens');
            range=output{1}{2};
            output=str2double(output{1}{1});
            if strncmp(range,'n',1)
                output = output * 1e-9;
            elseif strncmp(range,'u',1)
                output = output * 1e-6;
            end
            Attocube.write(Attocube,sprintf('setm %01d gnd', Attocube.axis));
        end
        
        %% set functions
        % set mode
        function error = set_mode(Attocube, mode)
            error = Attocube.write(Attocube,sprintf('setm %01d %s', Attocube.axis, mode));
        end
        
        % set frequency
        function error = set_frequency(Attocube, input)
            error = Attocube.write(Attocube,sprintf('setf %01d %01d', Attocube.axis, input));
        end
        
        % set amplitude
        function error = set_voltage(Attocube, input)
            error = Attocube.write(Attocube,sprintf('setv %01d %01d', Attocube.axis, input));
        end
        
        %% motion functions
        function error = stop(Attocube, varargin)
            error = Attocube.write(Attocube,sprintf('stop %01d', Attocube.axis));
        end
        
        function error = step(Attocube, varargin)
            stepsize = varargin{1};
            speed = varargin{2};
            breaking = varargin{3};
            if length(varargin)>3; stepsize_min = varargin{4}; else; stepsize_min = 500e-9; end
            if stepsize_min > 1e-3; stepsize_min = stepsize_min * 1e-9; end
            if stepsize > 1e-3; stepsize = stepsize * 1e-6; end
            if speed > 1e-3; speed = speed * 1e-6; end
            
            % get steps
            N_steps = round(stepsize / stepsize_min);
            
            % get and set speed
            freq = Attocube.convert_speed_to_frequency(Attocube, speed, stepsize_min);
            
            Attocube.set_frequency(freq);
            
            Attocube.set_mode('stp')
            
            % move
            if breaking
                error = Attocube.write(Attocube,sprintf('stepu %01d %01d', Attocube.axis, N_steps));
            else
                error = Attocube.write(Attocube,sprintf('stepd %01d %01d', Attocube.axis, N_steps));
            end
            
            Attocube.set_mode('gnd')
        end
        
        
    end
    
end