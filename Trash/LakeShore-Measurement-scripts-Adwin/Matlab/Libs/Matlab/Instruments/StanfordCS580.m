classdef StanfordCS580 < handle
    
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
        
        function Stanford = StanfordCS580(address)
            Stanford.serial_address = address;
            Stanford.device = visa('ni',address);
            set(Stanford.device,'Timeout',2)
            fopen(Stanford.device);
            
            Stanford.output_mode='v';
        end
                
        %% General 
      
        % custom command
        function send_command(Stanford, command)
            fprintf(Stanford.device, command);
        end
        
        % reset
        function reset(Stanford)
            fprintf(Stanford.device, '*RST');
        end
        
        % close connection
        function close(Stanford)
            fclose(Stanford.device);
        end
        
        % set gain
        function set_gain(Stanford, gain)
            string = sprintf('GAIN%1.0f', gain);
            fprintf(Stanford.device, string);
        end
        
        % set shield
        function set_shield(Stanford, shield)
            string = sprintf('SHLD%1.0f', shield);
            fprintf(Stanford.device, string);
        end
        
        % set input
        function set_input(Stanford, input)
            string = sprintf('INPT%1.0f', input);
            fprintf(Stanford.device, string);
        end
        
        % set speed
        function set_speed(Stanford, speed)
            string = sprintf('RESP%1.0f', speed);
            fprintf(Stanford.device, string);
        end
        
        % set isolation
        function set_isolation(Stanford, iso)
            string = sprintf('ISOL%1.0f', iso);
            fprintf(Stanford.device, string);
        end
        
        % set output
        function set_output(Stanford, out)
            string = sprintf('SOUT%1.0f', out);
            fprintf(Stanford.device, string);
        end
        
        % set current
        function set_current(Stanford, curr)
            string = sprintf('CURR%1.3f', curr);
            fprintf(Stanford.device, string);
        end
        
        % set voltage
        function set_voltage(Stanford, volt)
            string = sprintf('VOLT%1.3f', volt);
            fprintf(Stanford.device, string);
        end
                                                                              
        
                
       
   
    end
    
end