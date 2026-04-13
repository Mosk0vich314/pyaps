classdef Keithley2636 < handle
    
    properties (SetAccess = private)
        serial_address
        device
        bits_per_number
    end
    
    properties (Transient)
        output_mode
        reading_mode
        PLC
        ID
        buffer_points
        range
    end
    
    methods
        
        function Keithley = Keithley2636(address)
            Keithley.serial_address = address;
            Keithley.device = visa('ni',address);
            set(Keithley.device,'Timeout',2)
            fopen(Keithley.device);
            
            Keithley.output_mode{1}='v';
            Keithley.output_mode{2}='v';  
            Keithley.reading_mode{1}='v';
            Keithley.reading_mode{2}='v';
        end
                
        %% General 
        % beep
        function beep(Keithley)
            fprintf(Keithley.device,'beeper.beep(0.5, 2400)');
            pause(1)
            fprintf(Keithley.device,'beeper.beep(0.5, 2400)');
            pause(1)
            fprintf(Keithley.device,'beeper.beep(0.5, 2400)');
        end
       
        % custom command
        function send_command(Keithley, command)
            fprintf(Keithley.device, command);
        end
        
        % custom command
        function q = query(Keithley, command)
            q = query(Keithley.device, command);
        end
        
        % reset
        function reset(Keithley, channel)
            channels = {'a', 'b'};
            string = sprintf('smu%s.reset()', channels{channel});
            fprintf(Keithley.device, string);
        end
        
        % close connection
        function close(Keithley)
            fclose(Keithley.device);
        end
                       
        % set channel type (V/I)
        function set_output_channel(Keithley, channel, type)
            % channel: 1 or 2
            % type:  I or V
            channels = {'a', 'b'};
            if upper(type) == 'V'
                string = sprintf('smu%s.source.func = smu%s.OUTPUT_DCVOLTS', channels{channel}, channels{channel});
            end
            if upper(type) == 'I'
                string = sprintf('smu%s.source.func = smu%s.OUTPUT_DCAMPS', channels{channel}, channels{channel});
            end
            Keithley.output_mode{channel} = lower(type);
            fprintf(Keithley.device, string);
        end
        
                        
        % set channel type (V/I)
        function set_display(Keithley, state)
            % channel: 1 or 2
            % type:  I or V
            string = sprintf('display.screen = %01d', state);
            fprintf(Keithley.device, string);
        end
        
        % set user text
        function set_text(Keithley, text)
            string = sprintf('display.settext("%s")', text);
            fprintf(Keithley.device, string);
        end
                
        % clear trigger
        function clear_trigger(Keithley)
            fprintf(Keithley.device, 'display.trigger.clear()');
        end
        
        % set local lock
        function set_lock(Keithley, state)
            fprintf(Keithley.device, 'display.locallockout = %01d', state);
        end
                
        % set delay 
        function set_delay(Keithley, channel, delay)
            channels = {'a', 'b'};
            string = sprintf('smu%s.measure.delay=%1.6f',channels{channel}, delay);
            fprintf(Keithley.device, string);
        end
        
        % send key
        function send_key(Keithley, key)
            string = sprintf('display.sendkey(%01d)', key);
            fprintf(Keithley.device, string);
        end
        
        function set_reading_channel(Keithley, channel, type)
            %channel: 1 or 2 
            % type: 0(DCAmps), 1(DCvolts), 2(Ohms), 3(Watts)
            channels = {'a', 'b'};
            if upper(type) == 'V'
                string = sprintf('display.smu%s.measure.func=display.MEASURE_DCVOLTS',channels{channel});
            end
            if upper(type) == 'I'
                string = sprintf('display.smu%s.measure.func=display.MEASURE_DCAMPS',channels{channel});
            end
            if upper(type) == 'R'
                string = sprintf('display.smu%s.measure.func=display.MEASURE_OHMS',channels{channel});
            end
            if upper(type) == 'P'
                string = sprintf('display.smu%s.measure.func=display.MEASURE_WATTS',channels{channel});
            end
            Keithley.reading_mode{channel} = lower(type);
            fprintf(Keithley.device, string);
        end
        
        
        function output = single_reading(Keithley, channel, type)
            % channel: 1 or 2
            % type:  I or V
            channels = {'a', 'b'};
            string = sprintf('reading = smu%s.measure.%s()',channels{channel},lower(type));
            fprintf(Keithley.device, string);
            fprintf(Keithley.device, 'print(reading)');
            output = fgets(Keithley.device);
        end
        
               
        % set output voltage
        function set_output_voltage(Keithley, channel, voltage)
            % channel: 1 or 2
            % voltage:  in V
            channels = {'a', 'b'};
            string = sprintf('smu%s.source.levelv = %1.3f', channels{channel}, voltage);
            fprintf(Keithley.device, string);
        end
        
        % set output current
        function set_output_current(Keithley, channel, current)
            % channel: 1 or 2
            % current:  in A
            if current > 10 ; current = 10;  disp('Maximum current = 100000'); end
            if current < 1e-8 ; current = 1e-8; disp('Minimum current = 1e-8 A'); end

            if abs(10^ceil(log10(current))-current)<1e-9
                Keithley.set_upper_output_range(channel, 2 * 10^ceil(log10(current)))
            else
                Keithley.set_upper_output_range(channel, 10^ceil(log10(current)))
            end
            
            channels = {'a', 'b'};
            string = sprintf('smu%s.source.leveli = %1.8f', channels{channel}, current);
            fprintf(Keithley.device, string);
        end
        
        % apply V/I on output
        function start_output(Keithley, channel)
            % channel: 1 or 2
            channels = {'a', 'b'};
            string = sprintf('smu%s.source.output = smu%s.OUTPUT_ON', channels{channel}, channels{channel});
            fprintf(Keithley.device, string);
        end
        
        % set reading continuous
        function set_reading_continuous(Keithley, channel, buffer)
            % channel: 1 or 2
            channels = {'a', 'b'};
            string = sprintf('smu%s.trigger.measure.%s(smu%s.nvbuffer%01d)', channels{channel}, lower(Keithley.reading_mode{channel}),  channels{channel}, buffer);
            fprintf(Keithley.device, string); % have SMU A take resistance measurements and store them in a buffer
            fprintf(Keithley.device, 'smu%s.trigger.measure.action = 1', channels{channel}); % enable SMU A to measure during trigger model
            fprintf(Keithley.device, 'smu%s.measure.delay = 0.01', channels{channel}); % introduce delay before each measurement
            fprintf(Keithley.device, 'smu%s.trigger.count = 0', channels{channel}); % Have SMU A loop in trigger layer indefinitely (keep taking measurements)
            fprintf(Keithley.device, 'smu%s.trigger.initiate()', channels{channel}); % Have SMU A loop in trigger layer indefinitely (keep taking measurements)
        end
        
        % stop applying V/I on output
        function stop_output(Keithley, channel)
            % channel: 1 or 2
            channels = {'a', 'b'};
            string = sprintf('smu%s.source.output = smu%s.OUTPUT_OFF', channels{channel}, channels{channel});
            fprintf(Keithley.device, string);
        end
        
        % set output limit
        function set_limit(Keithley, channel, type, limit)
            % channel: 1 or 2
            % type:  I or V
            channels = {'a', 'b'};
            string = sprintf('smu%s.source.limit%s = %1.3f', channels{channel}, lower(type), limit);
            fprintf(Keithley.device, string);
        end
                        
        % Load an anonymous TSP script into the K2636 nonvolatile memory.
        function load_TSP(Keithley, TSP_file)
            fileID = fopen(TSP_file);
            fprintf(Keithley.device, 'loadscript');
            counter = 1;
            while ~feof(fileID)
                line = fgets(fileID); % read line by line
                fprintf(Keithley.device, line);
                counter = counter + 1;
            end
            fclose(fileID);
            fprintf(Keithley.device, 'endscript');
        end
        
        % Run the anonymous TSP script currently loaded in the K2636 memory.
        function run_TSP(Keithley)
            fprintf(Keithley.device, 'script.anonymous.run()');
        end
        
        % set number of PLC
        function set_PLC(Keithley, channel, cycles)
            % channel: 1 or 2
            % cycles:  number of power line cycles (0.001-25)
            if cycles > 25 ; cycles = 25; disp('Maximum PLC = 25');  end
            if cycles < 0.001 ; cycles = 0.001; disp('Minimum PLC = 0.001');  end
            channels = {'a', 'b'};
            string = sprintf('smu%s.measure.nplc = %01d', channels{channel}, cycles);
            fprintf(Keithley.device, string);
            Keithley.PLC = cycles;
        end
                
        % set autorange
        function set_auto_range(Keithley, channel, type, state)
            % channel: 1 or 2
            % type:  I or V
            % state: ON or OFF
            channels = {'a', 'b'};
            string = sprintf('smu%s.source.autorange%s = smu%s.AUTORANGE_%s', channels{channel}, lower(type), channels{channel}, state);
            fprintf(Keithley.device, string);
        end
                  
        % abort
        function abort(Keithley, channel)
            % channel: 1 or 2
            channels = {'a', 'b'};
            string = sprintf('smu%s.abort()', channels{channel});
            fprintf(Keithley.device, string);
        end
        
        % set filter
        function set_filter(Keithley, channel, state)
            % channel: 1 or 2
            % state: ON or OFF
            channels = {'a', 'b'};
            string = sprintf('smu%s.measure.filter.enable = smu%s.FILTER_%s', channels{channel},channels{channel},state);
            fprintf(Keithley.device, string);
        end
        
        % set autozero
        function set_autozero(Keithley, channel, state)
            % channel: 1 or 2
            % state: AUTO (Automatic checking of reference and zero measurments; an autozero is performed when needed)
            % State: OFF
            % State: ONCE (Performs autozero once, then  disables autozero)
            channels = {'a', 'b'};
            string = sprintf('smu%s.measure.autozero = smu%s.AUTOZERO_%s', channels{channel}, channels{channel}, state);
            fprintf(Keithley.device, string);
        end
        
        function set_upper_output_range(Keithley,channel,range)
          % range: 
           channels = {'a', 'b'};
           string=sprintf('smu%s.source.range%s=%1.12f',channels{channel},Keithley.output_mode{channel},range);
           fprintf(Keithley.device, string);
        end
        
                
    %% Buffer
        function clear_buffer(Keithley, channel, buffer)
            % channel: 1 or 2
            % buffer: 1 or 2
            channels = {'a', 'b'};
            string = sprintf('smu%s.nvbuffer%01d.clear()', channels{channel}, buffer);
            fprintf(Keithley.device, string);
        end
        
        function set_points_buffer(Keithley, channel, points)
            % channel: 1 or 2
            % points: number of points
            channels = {'a', 'b'};
            if points > 100000 ; points = 100000; disp('Maximum buffer capacity = 100000'); end
            string = sprintf('smu%s.measure.count = %01d', channels{channel}, points);
            fprintf(Keithley.device, string);
            Keithley.buffer_points = points;
        end
                
        %% Read buffer.
        function data = read_buffer(Keithley, channel, buffer )
            % channel: 1 or 2
            % buffer: 1 or 2
            % points: number of points
            warning('off')
            channels = {'a', 'b'};
            string = sprintf('printbuffer(1, %01d, smu%s.nvbuffer%01d )', Keithley.buffer_points, channels{channel}, buffer);
            fprintf(Keithley.device, string);
            string = '';
            while isempty(regexp(string,'\n','once'))
                string = [string fgets(Keithley.device)];
            end
            data = str2double(strsplit(strtrim(string),','))   ;
            warning('on')
        end
        
        function start_buffer_acquisition(Keithley, channel, PLC, buffer, range)
            % channel: 1 or 2
            % points: number of points
            % cycles:  number of power line cycles (0.001-25)
            % buffer: 1 or 2
            % range: AUTO of numeric for fixed range
            Keithley.clear_buffer(channel, buffer);
            Keithley.set_PLC(channel, PLC);
            Keithley.set_filter(channel, 'OFF');
            Keithley.set_autozero(channel, 'ONCE'); % 0:off, 1:once, 2:auto
            if ischar(range)
                Keithley.set_auto_range(channel, Keithley.output_mode{channel},'ON');
            end
            if isnumeric(range)
                Keithley.set_auto_range(channel, Keithley.output_mode{channel}, 'OFF');
                Keithley.set_upper_output_range(channel, range);
            end
            
            channels = {'a', 'b'};
            string = sprintf('smu%s.measure.%s(smu%s.nvbuffer%01d)',channels{channel}, Keithley.reading_mode{channel}, channels{channel}, buffer);
            fprintf(Keithley.device, string);
                       
        end

    end
    
end