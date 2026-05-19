classdef Keithley2182 < handle
    
    properties (SetAccess = private)
        serial_address
        device
        bits_per_number
    end
    
    properties (Transient)
        mode
        PLC
        ID
        buffer_points
        range
    end
    
    methods
        
        function Keithley = Keithley2182(address)
            Keithley.serial_address = address;
            Keithley.device = visa('ni',address);
            set(Keithley.device,'Timeout',2)
            fopen(Keithley.device);
            
            Keithley.bits_per_number = 18;
            
            % get mode
            Keithley.mode = query(Keithley.device, 'SENS:FUNC?');
            Keithley.mode = regexprep(strtrim(Keithley.mode),'"','');
            
            % get ID
            Keithley.ID = strtrim(query(Keithley.device, '*IDN?'));
            
            % get PLC
            string = sprintf('SENS:%s:NPLC?', Keithley.mode);
            Keithley.PLC = str2double(query(Keithley.device, string));
            
            % get buffer size
            Keithley.buffer_points = str2double(strtrim(query(Keithley.device, 'DATA:POIN?')));
            
        end
        
        %% close connection
        function close(Keithley)
            fclose(Keithley.device);
        end
        
        %% set custom command
        function output = send_command(Keithley, command)
            output = strtrim(query(Keithley.device, command));
        end
        
        %% get functions
        % identify device
        function identify(Keithley)
            Keithley.ID = strtrim(query(Keithley.device, '*IDN?'));
        end
        
        % get mode
        function get_mode(Keithley)
            Keithley.mode = query(Keithley.device, 'SENS:FUNC?');
            Keithley.mode = regexprep(strtrim(Keithley.mode),'"','');
        end
        
        % get power line cycles
        function get_PLC(Keithley)
            string = sprintf('SENS:%s:NPLC?', Keithley.mode);
            Keithley.PLC = str2double(query(Keithley.device, string));
        end
        
        %% set functions
        % change mode
        function set_mode(Keithley, mode)
            string = sprintf('SENS:FUNC %s%s%s', char(39), mode, char(39));
            fprintf(Keithley.device, string);
            get_mode(Keithley);
            set_PLC(Keithley, Keithley.PLC)
        end
        
        % set number of PLC
        function set_PLC(Keithley, cycles)
            if cycles > 50 ; cycles = 10;  end
            if cycles < 0.01 ; cycles = 0.01;  end
            string = sprintf('SENS:%s:NPLC %01d', Keithley.mode, cycles);
            fprintf(Keithley.device, string);
            get_PLC(Keithley);
        end
        
        % set display
        function set_display(Keithley, state)
            fprintf(Keithley.device, ':DISP:ENAB %s', state);
        end
        
        % set resolution
        function set_resolution(Keithley, resolution)
            string = sprintf('SENS:%s:DIG %01d', Keithley.mode, resolution);
            fprintf(Keithley.device, string);   
        end
        
        % set autozero
        function set_autozero(Keithley, state)
            fprintf(Keithley.device, ':SYST:AZER:STAT %s', state);
        end
        
        % set channel
        function set_channel(Keithley, channel)
            fprintf(Keithley.device, ':SENS:CHAN %01d', channel);
        end
        
        % set digital filter
        function set_digital_filter(Keithley, state)
            string = sprintf('SENS:%s:DFIL:STAT %s', Keithley.mode, state);
            fprintf(Keithley.device, string);
        end
                
        % set analogue filter
        function set_analogue_filter(Keithley, state)
            string = sprintf('SENS:%s:LPASs:STAT %s', Keithley.mode, state);
            fprintf(Keithley.device, string);
        end
        
        % set range
        function set_upper_range(Keithley, upper_range)
            string = sprintf('SENS:%s:RANG:UPP %01d', Keithley.mode, upper_range);
            fprintf(Keithley.device, string);
        end
        
        % set range
        function set_auto_range(Keithley, state)
            string = sprintf('SENS:%s:RANG:AUTO %s', Keithley.mode, state);
            fprintf(Keithley.device, string);
        end
        
        %% Buffer
        function clear_buffer(Keithley)
            fprintf(Keithley.device, 'DATA:CLE');
        end
        
        function set_points_buffer(Keithley, points)
            fprintf(Keithley.device, sprintf(':DATA:POIN %01d',points));
            Keithley.buffer_points = points;
        end
        
        function output = get_points_buffer(Keithley)
            output = str2double(query(Keithley.device, 'DATA:POIN?'));
        end
        
        function set_data_feed(Keithley, feed)
            fprintf(Keithley.device, 'DATA:FEED %s',feed);
        end
        
        function output = get_data_feed(Keithley)
            output = strtrim(query(Keithley.device, 'DATA:FEED?'));
        end
        
        function stop_buffer_acquisition(Keithley)
            fprintf(Keithley.device, 'DATA:FEED:CONT NEV');
        end
        
        function [free, used] = get_buffer_size(Keithley)
            output = query(Keithley.device, 'DATA:FREE?');
            output = str2double(strsplit(strtrim(output),','));
            free = output(1);
            used = output(2);
        end
        
        
        %% read data
        % fetch single value
        function output = read_single(Keithley)
            output = str2double(strtrim(query(Keithley.device, ':FETC?')));
        end
        
        function start_buffer_acquisition(Keithley, points, PLC, range)
            Keithley.clear_buffer;
            Keithley.set_points_buffer(points);
            Keithley.set_PLC(PLC);
            Keithley.set_display('OFF');
            Keithley.set_autozero('OFF');
            Keithley.set_analogue_filter('OFF');
            Keithley.set_digital_filter('OFF');
            
            if ischar(range)
                Keithley.set_auto_range(range);
            end
            if isnumeric(range)
                Keithley.set_auto_range('OFF');
                Keithley.set_upper_range(range);
            end
            
            fprintf(Keithley.device, ':DATA:FEED:CONT NEXT');
        end
        
        function wait_for_buffer(Keithley)
            [~, used] = Keithley.get_buffer_size;
            used_old = 0;
            while used < Keithley.buffer_points * Keithley.bits_per_number
                pause(1)
                [~, used] = Keithley.get_buffer_size;
                fprintf('Samples per sec: %01d \n',abs(used_old-used) / Keithley.bits_per_number)
                used_old = used;
            end
            Keithley.set_display('ON');

        end
        
        function data = get_buffer_data(Keithley)
            warning('off')
            fprintf(Keithley.device,':DATA:DATA?');
            string = fgets(Keithley.device);
            while string(end) == ','
                string = [string fgets(Keithley.device)];
            end
            data = str2double(strsplit(strtrim(string),','))   ;
            warning('on')
        end
        
    end
    
end