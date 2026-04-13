classdef Keithley2450 < handle

    properties (SetAccess = private)

    end

    properties (Transient)
        device
    end

    methods

        function Keithley = Keithley2450(address)
            Keithley.device = visadev(address);
        end

        %% reset
        % identify device
        function reset(Keithley)
            write(Keithley.device, '*RST');
        end

        %% get functions
        % get mode sense
        function mode = get_mode_sense(Keithley)
            write(Keithley.device, ':SENS:FUNC?');
            mode = strtrim(readline(Keithley.device));
        end

        function mode = get_mode_source(Keithley)
            write(Keithley.device, ':SOURCE:FUNC?');
            mode = strtrim(readline(Keithley.device));
        end

        % get power line cycles
        function numPLC = get_PLC_sense(Keithley, mode)
            write(Keithley.device, sprintf(':SENS:%s:NPLC?', upper(mode)));
            numPLC = strtrim(readline(Keithley.device));
        end

        function numPLC = get_PLC_source(Keithley, mode)
            write(Keithley.device, sprintf(':SOURCE:%s:NPLC?', upper(mode)));
            numPLC = strtrim(readline(Keithley.device));
        end

        %% set functions
        % change mode
        function set_mode_sense(Keithley, mode)
            switch mode
                case 'I'
                    modeTMP ='CURR:DC';
                    write(Keithley.device, sprintf(':SENS:FUNC %s%s%s', char(39), modeTMP, char(39)));
                case 'V'
                    modeTMP = 'VOLT:DC';
                    write(Keithley.device, sprintf(':SENS:FUNC %s%s%s', char(39), modeTMP, char(39)));
            end
        end

        function set_mode_source(Keithley, mode)
            switch mode
                case 'I'
                    modeTMP ='CURR';
                    write(Keithley.device, sprintf(':SOURCE:FUNC %s', modeTMP));
                case 'V'
                    modeTMP = 'VOLT';
                    write(Keithley.device, sprintf(':SOURCE:FUNC %s', modeTMP));
            end
        end


        function set_mode_combi(Keithley, mode)
            switch mode
                case 'IV'
                    Keithley.set_mode_sense('I')
                    Keithley.set_mode_source('V')
                case 'VI'
                    Keithley.set_mode_source('I')
                    Keithley.set_mode_sense('V')
            end

        end


        function set_terminal_loc(Keithley, mode)
            write(Keithley.device, sprintf(':ROUT:TERM %s', mode));
        end
        
        % set number of PLC
        function set_PLC_sense(Keithley, mode, cycles)
            if cycles > 10 ; cycles = 10;  end
            if cycles < 0.01 ; cycles = 0.01;  end
            mode = strrep(mode, """", "");
            write(Keithley.device, sprintf('SENS:%s:NPLC %01d', mode, cycles));
        end

        function set_PLC_source(Keithley, mode, cycles)
            if cycles > 10 ; cycles = 10;  end
            if cycles < 0.01 ; cycles = 0.01;  end
            mode = strrep(mode, """", "");
            write(Keithley.device, sprintf('SOURCE:%s:NPLC %01d', mode, cycles));
        end

        function set_PLC(Keithley, cycles)
            Keithley.set_PLC_sense( Keithley.get_mode_sense(), cycles)
%             Keithley.set_PLC_source( Keithley.get_mode_source(), cycles)
        end

        % set compliance
        function set_current_limit_IVmode(Keithley, current)
            write(Keithley.device, sprintf(':SOUR:VOLT:ILIMIT %0.5e', current));
        end

        function set_voltage_limit_VImode(Keithley, voltage)
            write(Keithley.device, sprintf(':SOUR:CURR:VLIMIT %0.5e', voltage));
        end

        % set output
        function set_voltage_source(Keithley, voltage)
            write(Keithley.device, sprintf(':SOUR:VOLT %0.5e', voltage));
        end

        function set_current_source(Keithley, current)
            write(Keithley.device, sprintf(':SOUR:CURR %0.5e', current));
        end

        function set_output(Keithley, mode)
            write(Keithley.device, sprintf(':OUTP %s', mode));
        end

        % set front/rear
        function set_rear(Keithley)
            write(Keithley.device, ':ROUT:TERM REAR');
        end
        
        function set_front(Keithley)
            write(Keithley.device, ':ROUT:TERM FRONT');
        end

        %% reading
        function set_autorange(Keithley, mode)
            switch mode
                case 0
                    write(Keithley.device, ':CURR:RANG:AUTO OFF');
                case 1
                    write(Keithley.device, ':CURR:RANG:AUTO ON');
            end
        end

        function dataPoint = read(Keithley)
            write(Keithley.device,':READ?');
            dataPoint = strtrim(readline(Keithley.device));
        end

        % read array from software trigger
        function [time, data] = read_array(Keithley, points, delay)
            write(Keithley.device, sprintf(':TRIG:LOAD "SimpleLoop", %01d, %1.3f', points, delay));
            write(Keithley.device,':INIT');
            write(Keithley.device,':*WAI');
            pause(points * delay)
            write(Keithley.device,sprintf(':TRAC:DATA? 1, %01d, "defbuffer1", READ, REL', points));
            data = readline(Keithley.device);
            data = str2double(split(data,','));
            time = data(2:2:end);
            data = data(1:2:end);
       end
        
       %



% function make_measurement(Keithley)    
%     
%             
%                         :TRIG:LOAD "SimpleLoop", 10, 0.1
%             :OUTP ON
%             :INIT
%             *WAI
%             :OUTP OFF
%             :TRAC:DATA? 1, 10, "defbuffer1", READ, REL
% 



        %
        %         % set resolution
        %         function set_resolution(Keithley, resolution)
        %             string = sprintf('SENS:%s:DIG %01d', Keithley.mode, resolution);
        %             fprintf(Keithley.device, string);
        %         end
        %
        %         % set autozero
        %         function set_autozero(Keithley, state)
        %             fprintf(Keithley.device, ':SYST:AZER:STAT %s', state);
        %         end
        %
        %         % set digital filter
        %         function set_digital_filter(Keithley, state)
        %             string = sprintf('SENS:%s:AVER:STAT %s', Keithley.mode, state);
        %             fprintf(Keithley.device, string);
        %         end
        %
        %         % set range
        %         function set_upper_range(Keithley, upper_range)
        %             string = sprintf('SENS:%s:RANG:UPP %01d', Keithley.mode, upper_range);
        %             fprintf(Keithley.device, string);
        %         end
        %
        %         % set range
        %         function set_auto_range(Keithley, state)
        %             string = sprintf('SENS:%s:RANG:AUTO %s', Keithley.mode, state);
        %             fprintf(Keithley.device, string);
        %         end
        %
        %         %% Buffer
        %         function clear_buffer(Keithley)
        %             fprintf(Keithley.device, 'DATA:CLE');
        %         end
        %
        %         function set_points_buffer(Keithley, points)
        %             fprintf(Keithley.device, sprintf(':DATA:POIN %01d',points));
        %             Keithley.buffer_points = points;
        %         end
        %
        %         function output = get_points_buffer(Keithley)
        %             output = str2double(query(Keithley.device, 'DATA:POIN?'));
        %         end
        %
        %         function set_data_feed(Keithley, feed)
        %             fprintf(Keithley.device, 'DATA:FEED %s',feed);
        %         end
        %
        %         function output = get_data_feed(Keithley)
        %             output = strtrim(query(Keithley.device, 'DATA:FEED?'));
        %         end
        %
        %         function stop_buffer_acquisition(Keithley)
        %             fprintf(Keithley.device, 'DATA:FEED:CONT NEV');
        %         end
        %
        %         function [free, used] = get_buffer_size(Keithley)
        %             output = query(Keithley.device, 'DATA:FREE?');
        %             output = str2double(strsplit(strtrim(output),','));
        %             free = output(1);
        %             used = output(2);
        %         end
        %
        %
        %         %% read data
        %         % fetch single value
        %         function output = read_single(Keithley)
        %             output = str2double(strtrim(query(Keithley.device, ':FETC?')));
        %         end
        %
        %         function start_buffer_acquisition(Keithley, points, PLC, range)
        %             Keithley.clear_buffer;
        %
        % %             fprintf(Keithley.device, ':INIT:CONT ON');
        % %             fprintf(Keithley.device, ':ABORt');
        % %             fprintf(Keithley.device, ':TRIG:COUNT 1');
        %
        %             Keithley.set_points_buffer(points);
        %             Keithley.set_PLC(PLC);
        %             Keithley.set_display('OFF');
        %             Keithley.set_autozero('OFF');
        %             Keithley.set_digital_filter('OFF');
        %
        %             if ischar(range)
        %                 Keithley.set_auto_range(range);
        %             end
        %             if isnumeric(range)
        %                 Keithley.set_auto_range('OFF');
        %                 Keithley.set_upper_range(range);
        %             end
        %
        %             fprintf(Keithley.device, ':DATA:FEED:CONT NEXT');
        %         end
        %
        %         function wait_for_buffer(Keithley)
        %             [~, used] = Keithley.get_buffer_size;
        %             used_old = 0;
        %             while used < Keithley.buffer_points * Keithley.bits_per_number
        %                 pause(1)
        %                 [~, used] = Keithley.get_buffer_size;
        %                 fprintf('Samples per sec: %01d \n',abs(used_old-used) / Keithley.bits_per_number)
        %                 used_old = used;
        %             end
        %             Keithley.set_display('ON');
        %         end
        %
        %         function data = get_buffer_data(Keithley)
        %             warning('off')
        %             fprintf(Keithley.device,':DATA:DATA?');
        %             string = fgets(Keithley.device);
        %             while string(end) == ','
        %                 string = [string fgets(Keithley.device)];
        %             end
        %             data = str2double(strsplit(strtrim(string),','))   ;
        %             warning('on')
        %         end

    end

end