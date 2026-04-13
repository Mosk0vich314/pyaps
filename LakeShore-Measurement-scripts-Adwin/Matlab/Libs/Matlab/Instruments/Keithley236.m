classdef Keithley236 < handle
    
    properties (SetAccess = private)
        serial_address
        device
    end
    
    properties (Transient)
        output_mode
        ID
        range
    end
    
    methods
        
        function Keithley = Keithley236(address)
            Keithley.serial_address = address;
            Keithley.device = visa('ni',address);
            set(Keithley.device,'Timeout',2)
            fopen(Keithley.device);
            
            Keithley.output_mode='v';
        end
                
        %% General 
      
        % custom command
        function send_command(Keithley, command)
            fprintf(Keithley.device, command);
        end
        
        % reset
        function reset(Keithley)
            fprintf(Keithley.device, 'J0X');
        end
        
        % close connection
        function close(Keithley)
            fclose(Keithley.device);
        end
        
        % set sensing
        function set_sensing_remote(Keithley)
            fprintf(Keithley.device, 'O1X');
        end
        
        % set sensing
        function set_sensing_local(Keithley)
            fprintf(Keithley.device, 'O0X');
        end
        
        % set filter
        function set_filter(Keithley, filter)
            string = sprintf('P%1.0fX', filter);
            fprintf(Keithley.device, string);
        end
        
        % set integration time
        function set_integration_time(Keithley, integration_time)
            string = sprintf('S%1.0fX', integration_time);
            fprintf(Keithley.device, string);
        end
                                                                  
        % set output voltage
        function set_output_voltage(Keithley, voltage)
            % voltage:  in V
            fprintf(Keithley.device, 'F0,0X');
            fprintf(Keithley.device, 'H0X');
            if voltage > 1
                string = sprintf('B%1.2f,2,100X', voltage);
            else
                string = sprintf('B%1.3f,1,100X', voltage);
            end
            fprintf(Keithley.device, string);
        end
                
        % set output current
        function set_output_current(Keithley, current)
            
            if current == 0
                current = 1e-9;
            end
            
            % voltage:  in V
            fprintf(Keithley.device, 'F1,0X');
            fprintf(Keithley.device, 'H0X');
            string = sprintf('B%1.6e,%01d,0X', current, 10 + ceil(log10(abs(current))));
            fprintf(Keithley.device, string);
        end
                        
        % apply V/I on output
        function start_output(Keithley)
            fprintf(Keithley.device, 'N1X');
        end
        
        % stop V/I on output
        function stop_output(Keithley)
            fprintf(Keithley.device, 'N0X');
        end
        
        % set output limit
        function set_limit(Keithley, channel, type, limit)
            % channel: 1 or 2
            % type:  I or V
            channels = {'a', 'b'};
            string = sprintf('smu%s.source.limit%s = %1.3f', channels{channel}, lower(type), limit);
            fprintf(Keithley.device, string);
        end
                
   
    end
    
end