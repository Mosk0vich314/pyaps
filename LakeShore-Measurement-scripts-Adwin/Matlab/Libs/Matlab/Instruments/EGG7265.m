classdef EGG7265 < handle
    
    properties (SetAccess = private)
        serial_address
    end
    
    properties (Transient)
        device
    end
    
    methods
        
        function EG_G7265 = EGG7265(address)
            EG_G7265.serial_address = address;
            EG_G7265.device = visa('ni',address);
            set(EG_G7265.device,'Timeout',2)
            fopen(EG_G7265.device);
        end
        
        
        %% identify
        function output = identify(EG_G7265)
            try;fclose(EG_G7265.device);end
            fopen(EG_G7265.device);
            fprintf(EG_G7265.device,"ID");
            output = strtrim(fscanf(EG_G7265.device));
            fclose(EG_G7265.device);
        end
        
        %% reset
        function reset(EG_G7265)
            try;fclose(EG_G7265.device);end
            fopen(EG_G7265.device);
            fprintf(EG_G7265.device,"ADF 0");
            fclose(EG_G7265.device);
        end
        
        %% Set output interface to GPiB
        function set_interface(EG_G7265)
            try;fclose(EG_G7265.device);end
            fopen(EG_G7265.device);
            fprintf(EG_G7265.device, sprintf("OutX 1"));
            fclose(EG_G7265.device);
        end
        
        %% set sensitivity
        function set_sensitivity(EG_G7265, sensitivity)
            try;fclose(EG_G7265.device);end
            
            S = [2e-9 5e-9 1e-8 2e-8 5e-8 1e-7 2e-7 5e-7 1e-6 2e-6 5e-6 1e-5 2e-5 5e-5 1e-4 2e-4 5e-4...
                1e-3 2e-3 5e-3  1e-2 2e-2 5e-2  1e-1 2e-1 5e-1 1];
            sense = 1:27;
            idx = find((sensitivity > S) ==0, 1, 'first');
            
            fopen(EG_G7265.device);
            fprintf(EG_G7265.device,"SEN %1.0f", sense(idx));
            fclose(EG_G7265.device);
        end
        
        %% set time constant
        function set_timeconstant(EG_G7265, timeconstant)
            try;fclose(EG_G7265.device);end
            S = [10e-6 20e-6 40e-6 80e-6 160e-6 320e-6 640e-6 ...
                5e-3 10e-3 20e-3 50e-3 100e-3 200e-3 500e-3 ...
                1 2 5 10 20 50 100 200 500 ...
                1e3 2e3 5e3 10e3 20e3 50e3 100e3];
            time = 0:29;
            idx = find((timeconstant > S) ==0, 1, 'first');
            
            fopen(EG_G7265.device);
            fprintf(EG_G7265.device,"TC %1.0f", time(idx));
            fclose(EG_G7265.device);
        end
        
        function set_filter_order(EG_G7265, slope)
            try;fclose(EG_G7265.device);end
            fopen(EG_G7265.device);
            fprintf(EG_G7265.device, sprintf("SLOPE %1.0f", slope));
            fclose(EG_G7265.device);
        end
        
        
        %% signal input
        function set_input_AC(EG_G7265, couple)
            try;fclose(EG_G7265.device);end
            fopen(EG_G7265.device);
            fprintf(EG_G7265.device, sprintf("CP %1.0f", 1 - couple));
            fclose(EG_G7265.device);
        end
        
        function set_input_float(EG_G7265, float)
            
            try;fclose(EG_G7265.device);end
            fopen(EG_G7265.device);
            fprintf(EG_G7265.device, sprintf("FLOAT %1.0f", float));
            fclose(EG_G7265.device);
        end
        
        function set_input_diff(EG_G7265, input)
            switch input
                case 'A'
                    input_value = 1;
                case 'B'
                    input_value = 2;
                case 'A-B'
                    input_value = 3;
                otherwise
                    input_value = 0;
            end
            
            try;fclose(EG_G7265.device);end
            fopen(EG_G7265.device);
            fprintf(EG_G7265.device, sprintf("VMODE %1.0f", input_value));
            fclose(EG_G7265.device);
        end
        
        %% Filter
        function set_line_filter(EG_G7265, filter)
            try;fclose(EG_G7265.device);end
            fopen(EG_G7265.device);
            fprintf(EG_G7265.device, sprintf("LF %1.0f 1", filter));
            fclose(EG_G7265.device);
        end
        
        %% set auto
        function set_autophase(EG_G7265)
            try;fclose(EG_G7265.device);end
            fopen(EG_G7265.device);
            fprintf(EG_G7265.device,"APHS");
            fclose(EG_G7265.device);
        end
        
        function set_autogain(EG_G7265)
            try;fclose(EG_G7265.device);end
            fopen(EG_G7265.device);
            fprintf(EG_G7265.device,"AGAN");
            fclose(EG_G7265.device);
        end
        
        function set_autoreserver(EG_G7265)
            try;fclose(EG_G7265.device);end
            fopen(EG_G7265.device);
            fprintf(EG_G7265.device,"ARSV");
            fclose(EG_G7265.device);
        end
        
        function set_zerooffset(EG_G7265, offset)
            try;fclose(EG_G7265.device);end
            fopen(EG_G7265.device);
            fprintf(EG_G7265.device,"AOFF %1.0f", offset);
            fclose(EG_G7265.device);
        end
        
        %% set reference
        function set_reference(EG_G7265, reference)
            switch reference
                case 'Internal'
                    reference_value = 0;
                case 'External'
                    reference_value = 2;
                otherwise
                    reference_value = 0;
            end
            
            try
                fclose(EG_G7265.device);
            fopen(EG_G7265.device);
            fprintf(EG_G7265.device,"IE %1.0f", reference_value);
            fclose(EG_G7265.device);
            end
            try
                fclose(EG_G7265.device);
                fopen(EG_G7265.device);
            fprintf(EG_G7265.device,"IE %1.0f", reference_value);
            fclose(EG_G7265.device);
            end
        end
        
        function set_phase(EG_G7265, phase)
            try;fclose(EG_G7265.device);end
            fopen(EG_G7265.device);
            fprintf(EG_G7265.device, sprintf("PHA. %3.3f", phase));
            fclose(EG_G7265.device);
        end
        
        function set_frequency(EG_G7265, frequency)
            try;fclose(EG_G7265.device);end
            fopen(EG_G7265.device);
            fprintf(EG_G7265.device,sprintf("OF. %1.5f", frequency));
            fclose(EG_G7265.device);
        end
        
        function set_harmonic(EG_G7265, harmonic)
            try;fclose(EG_G7265.device);end
            fopen(EG_G7265.device);
            fprintf(EG_G7265.device, sprintf("REFN%1.0f", harmonic));
            fclose(EG_G7265.device);
        end
        
        function output = get_harmonic(EG_G7265)
            try;fclose(EG_G7265.device);end
            fopen(EG_G7265.device);
            fprintf(EG_G7265.device, "REFN.");
            output = str2double(fscanf(EG_G7265.device));
            fclose(EG_G7265.device);
        end
        
        function set_amplitude(EG_G7265, amplitude)
            try;fclose(EG_G7265.device);end
            fopen(EG_G7265.device);
            fprintf(EG_G7265.device, sprintf("OA. %1.5f", amplitude));
            fclose(EG_G7265.device);
        end
        
        function set_trigger(EG_G7265, trigger)
            try;fclose(EG_G7265.device);end
            fopen(EG_G7265.device);
            fprintf(EG_G7265.device, sprintf("RSLP %1.3f", trigger));
            fclose(EG_G7265.device);
        end
        
        %% set output value
        function set_output_channel (EG_G7265, channel, display)
            
            switch display
                case 'X'
                    display_value = 0;
                case 'Y'
                    display_value = 1;
                case 'R'
                    display_value = 2;
                case 'Theta'
                    display_value = 3;
                otherwise
                    display_value = 0;
            end
            
            try;fclose(EG_G7265.device);end
            fopen(EG_G7265.device);
            fprintf(EG_G7265.device, sprintf("CH %1.0f %1.0f", channel, display_value));
            fclose(EG_G7265.device);
        end
        %%read value of lockin x channel
        function data = read_ch_x(EG_G7265) 
             try;fclose(EG_G7265.device);end
            fopen(EG_G7265.device);
            fprintf(EG_G7265.device, sprintf("X."));
            data=str2double(fscanf(EG_G7265.device));
            fclose(EG_G7265.device);
        end
        %%read value of lockin y channel
        function data = read_ch_y(EG_G7265) 
             try;fclose(EG_G7265.device);end
            fopen(EG_G7265.device);
            fprintf(EG_G7265.device, sprintf("Y."));
            data=str2double(fscanf(EG_G7265.device));
            fclose(EG_G7265.device);
        end
    end
    
end