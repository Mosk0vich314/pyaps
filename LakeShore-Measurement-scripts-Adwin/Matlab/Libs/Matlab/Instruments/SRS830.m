classdef SRS830 < handle
    
    properties (SetAccess = private)
        serial_address
    end
    
    properties (Transient)
        device
    end
    
    methods
        
        function SRS_830 = SRS830(address)
            SRS_830.serial_address = address;
            SRS_830.device = visa('ni',address);
            set(SRS_830.device,'Timeout',2)
            fopen(SRS_830.device);
        end
        
                
        %% identify
        function output = identify(SRS_830)
            try;fclose(SRS_830.device);end
            fopen(SRS_830.device);
            fprintf(SRS_830.device,"*IDN?");
            output = strtrim(fscanf(SRS_830.device));
            fclose(SRS_830.device);
        end
                        
        %% reset
        function reset(SRS_830)
            try;fclose(SRS_830.device);end
            fopen(SRS_830.device);
            fprintf(SRS_830.device,"*RST");
            fclose(SRS_830.device);
        end
        
        %% Set output interface to GPiB
        function set_interface(SRS_830)
            try;fclose(SRS_830.device);end
            fopen(SRS_830.device);
            fprintf(SRS_830.device, sprintf("OutX 1"));
            fclose(SRS_830.device);
        end
         
        %% set sensitivity
        function output = set_sensitivity(SRS_830, sensitivity)
            try;fclose(SRS_830.device);end
            
            S = [2e-9 5e-9 1e-8 2e-8 5e-8 1e-7 2e-7 5e-7 1e-6 2e-6 5e-6 1e-5 2e-5 5e-5  1e-4 2e-4 5e-4...
                1e-3 2e-3 5e-3  1e-2 2e-2 5e-2  1e-1 2e-1 5e-1 1];
            sense = 0:26;
            idx = find((sensitivity > S) ==0, 1, 'first');
            
            fopen(SRS_830.device);
            fprintf(SRS_830.device,"SENS %1.0f", sense(idx));
            fclose(SRS_830.device);
            output = S(idx);
        end
        
         %% set time constant 
        function set_timeconstant(SRS_830, timeconstant)
            try;fclose(SRS_830.device);end
            S = [1e-5 3e-5 1e-4 3e-4 1e-3 3e-3 1e-2 3e-2 1e-1 3e-1 1 3 1e1 3e1 1e2 3e2  1e3 3e3 1e4 3e4];
            time = 0:19;
            idx = find((timeconstant > S) ==0, 1, 'first');
            
            fopen(SRS_830.device);
            fprintf(SRS_830.device,"OFLT %1.0f", time(idx));
            fclose(SRS_830.device);
        end
        
         function set_filter_order(SRS_830, slope)
            try;fclose(SRS_830.device);end
            fopen(SRS_830.device);
            fprintf(SRS_830.device, sprintf("OFSL %1.0f", slope));
            fclose(SRS_830.device);
         end
        
          function set_sinc(SRS_830, sync)
            try;fclose(SRS_830.device);end
            fopen(SRS_830.device);
            fprintf(SRS_830.device, sprintf("SYNC %1.0f", sync));
            fclose(SRS_830.device);
          end
        
          
        %% signal input
        function set_input_AC(SRS_830, value)
            try;fclose(SRS_830.device);end
            fopen(SRS_830.device);
            fprintf(SRS_830.device, sprintf("ICPL %1.0f", 1 - value));
            fclose(SRS_830.device);
        end
        
        function set_input_float(SRS_830, value)
            try;fclose(SRS_830.device);end
            fopen(SRS_830.device);
            fprintf(SRS_830.device, sprintf("IGND %1.0f", 1 - value));
            fclose(SRS_830.device);
        end
        
        function set_input_diff(SRS_830, input)

            switch input
                case 'A'
                    input_value = 0;
                case 'A-B'
                    input_value = 1;
                otherwise
                    input_value = 0;
            end
            
            try;fclose(SRS_830.device);end
            fopen(SRS_830.device);
            fprintf(SRS_830.device, sprintf("ISRC %1.0f", input_value));
            fclose(SRS_830.device);
        end
        
        %% Filter
        function set_line_filter(SRS_830, filter)
            try;fclose(SRS_830.device);end
            fopen(SRS_830.device);
            fprintf(SRS_830.device, sprintf("ILIN %1.0f", filter));
            fclose(SRS_830.device);
        end
        
        %% display 
        function set_output_channel(SRS_830, channel, display)
            
            switch display
                case 'X'
                    display_value = 0;         
                case 'Y'
                    display_value = 0;
                case 'R'
                    display_value = 1;
                case 'Theta'
                    display_value = 1;
                otherwise
                    display_value = 0;
            end
            
            try;fclose(SRS_830.device);end
            fopen(SRS_830.device);
            fprintf(SRS_830.device, sprintf("DDEF %1.0f, %1.0f, 0", channel, display_value));
            fprintf(SRS_830.device, sprintf("FPOP %1.0f, 0", channel));
            fclose(SRS_830.device);
        end
        
        %% reserve
         function set_reserve(SRS_830, reserve)
            try;fclose(SRS_830.device);end
            fopen(SRS_830.device);
            fprintf(SRS_830.device,"RMOD %1.0f", reserve);
            fclose(SRS_830.device);
         end
        
      
        %% set auto
        function set_autophase(SRS_830)
            try;fclose(SRS_830.device);end
            fopen(SRS_830.device);
            fprintf(SRS_830.device,"APHS");
            fclose(SRS_830.device);
        end
        
        function set_autogain(SRS_830)
            try;fclose(SRS_830.device);end
            fopen(SRS_830.device);
            fprintf(SRS_830.device,"AGAN");
            fclose(SRS_830.device);
        end
        
        function set_autoreserver(SRS_830)
            try;fclose(SRS_830.device);end
            fopen(SRS_830.device);
            fprintf(SRS_830.device,"ARSV");
            fclose(SRS_830.device);
        end
        
        function set_zerooffset(SRS_830, offset)
            try;fclose(SRS_830.device);end
           fopen(SRS_830.device);
            fprintf(SRS_830.device,"AOFF %1.0f", offset);
            fclose(SRS_830.device);
        end
        
        
        %% set reference
        function set_reference(SRS_830, reference)
             switch reference
                case 'Internal'
                    reference_value = 1;
                case 'External'
                    reference_value = 0;
             end
            
            try;fclose(SRS_830.device);end
            fopen(SRS_830.device);
            fprintf(SRS_830.device,"FMOD %1.0f", reference_value);
            fclose(SRS_830.device);
        end
        
        function set_phase(SRS_830, phase)
            try;fclose(SRS_830.device);end
            fopen(SRS_830.device);
            fprintf(SRS_830.device, sprintf("PHAS %3.2f", phase));
            fclose(SRS_830.device);
        end        
        
        function set_frequency(SRS_830, frequency)
            try;fclose(SRS_830.device);end
            fopen(SRS_830.device);
            fprintf(SRS_830.device,sprintf("FREQ %6.5f", frequency));
            fclose(SRS_830.device);
        end        
        
        function set_harmonic(SRS_830, harmonic)
            try;fclose(SRS_830.device);end
            fopen(SRS_830.device);
            fprintf(SRS_830.device, sprintf("HARM %1.0f", harmonic));
            fclose(SRS_830.device);
        end
        
                
        function output = get_harmonic(SRS_830)
            try;fclose(SRS_830.device);end
            fopen(SRS_830.device);
            fprintf(SRS_830.device, "HARM ?");
            output = str2double(fscanf(SRS_830.device));
            fclose(SRS_830.device);
        end
                
        function set_amplitude(SRS_830, amplitude)
            if amplitude < 0.004
               amplitude = 0.004; 
            end
            try;fclose(SRS_830.device);end
            fopen(SRS_830.device);
            fprintf(SRS_830.device, sprintf("SLVL %1.3f", amplitude));
            fclose(SRS_830.device);
        end
        
        function set_trigger(SRS_830, trigger)
            try;fclose(SRS_830.device);end
            fopen(SRS_830.device);
            fprintf(SRS_830.device, sprintf("RSLP %1.3f", trigger));
            fclose(SRS_830.device);
        end
        
        %% set output value
        function set_output_value(SRS_830, channel, output)
            try;fclose(SRS_830.device);end
            fopen(SRS_830.device);
            fprintf(SRS_830.device, sprintf("FPOP %1.0f, %1.0f", channel, output));
            fclose(SRS_830.device);
        end
        
         function set_offset_expand(SRS_830, channel, offset, expand)
            try;fclose(SRS_830.device);end
            fopen(SRS_830.device);
            fprintf(SRS_830.device, sprintf("OEXP %1.0f, %3.2f, %1.0f", channel, offset, expand));
            fclose(SRS_830.device);
         end
         
        %% Data storage
        %sample rate
        function set_sample_rate(SRS_830, sample_rate)
            try;fclose(SRS_830.device);end
            fopen(SRS_830.device);
            fprintf(SRS_830.device, sprintf("SRAT %1.0f", sample_rate));
            fclose(SRS_830.device);
        end
        
        %buffer mode       
       function set_buffer_mode(SRS_830, buffer)
            try;fclose(SRS_830.device);end
            fopen(SRS_830.device);
            fprintf(SRS_830.device, sprintf("SEND %1.0f", buffer));
            fclose(SRS_830.device);
       end
        
        %Trigger command       
       function set_trigger_command(SRS_830)
            try;fclose(SRS_830.device);end
            fopen(SRS_830.device);
            fprintf(SRS_830.device, sprintf("TRIG"));
            fclose(SRS_830.device);
       end
       
       %Switch trigger       
       function set_trigger_switch(SRS_830, trigger_switch)
            try;fclose(SRS_830.device);end
            fopen(SRS_830.device);
            fprintf(SRS_830.device, sprintf("TSTR %1.0f", trigger_switch));
            fclose(SRS_830.device);
       end
        
        %start data storage       
       function set_startstorage(SRS_830)
            try;fclose(SRS_830.device);end
            fopen(SRS_830.device);
            fprintf(SRS_830.device, sprintf("STRT"));
            fclose(SRS_830.device);
       end
        
        %pause data storage       
       function set_pausestorage(SRS_830)
            try;fclose(SRS_830.device);end
            fopen(SRS_830.device);
            fprintf(SRS_830.device, sprintf("PAUS"));
            fclose(SRS_830.device);
       end
        
        %reset data storage       
       function set_resetstorage(SRS_830)
            try;fclose(SRS_830.device);end
            fopen(SRS_830.device);
            fprintf(SRS_830.device, sprintf("REST"));
            fclose(SRS_830.device);
       end
        
        %% Transfer data
        %read value
        function output = read_value(SRS_830, value)
            try;fclose(SRS_830.device);end
            fopen(SRS_830.device);
            fprintf(SRS_830.device, sprintf("OUTP? %1.0f", value));
            output = strtrim(fscanf(SRS_830.device));
            fclose(SRS_830.device);
        end
        
        %read channel
        function output = read_channel(SRS_830, read_ch)
            try;fclose(SRS_830.device);end
            fopen(SRS_830.device);
            fprintf(SRS_830.device, sprintf("OUTR? %1.0f", read_ch));
            output = strtrim(fscanf(SRS_830.device));
            fclose(SRS_830.device);
        end
        
        %read multiple values
        function output = read_multiple(SRS_830, value1, value2, value3, value4, value5, value6)
            try;fclose(SRS_830.device);end
            fopen(SRS_830.device);
            fprintf(SRS_830.device, sprintf("SNAP? %1.0f, %1.0f, %1.0f, %1.0f, %1.0f, %1.0f", value1, value2, value3, value4, value5, value6));
            output = strtrim(fscanf(SRS_830.device));
            fclose(SRS_830.device);
        end
        
        %read auxiliary
        function output = read_aux(SRS_830, aux)
            try;fclose(SRS_830.device);end
            fopen(SRS_830.device);
            fprintf(SRS_830.device, sprintf("OAUX? %1.0f", aux));
            output = strtrim(fscanf(SRS_830.device));
            fclose(SRS_830.device);
        end
        
        %read number of points
        function output = read_number_points(SRS_830)
            try;fclose(SRS_830.device);end
            fopen(SRS_830.device);
            fprintf(SRS_830.device, sprintf("SPTS?"));
            output = strtrim(fscanf(SRS_830.device));
            fclose(SRS_830.device);
        end
        
        %Set bin number A
        function output = get_bin_numberA(SRS_830, buffer1, starting_bin1, total_bins1)
            try;fclose(SRS_830.device);end
            fopen(SRS_830.device);
            fprintf(SRS_830.device, sprintf("TRCA? %1.0f, %3.0f, %3.0f", buffer1, starting_bin1, total_bins1));
            output = strtrim(fscanf(SRS_830.device));
            fclose(SRS_830.device);
        end
        
        %Set bin number B
        function output = get_bin_numberB(SRS_830, buffer2, starting_bin2, total_bins2)
            try;fclose(SRS_830.device);end
            fopen(SRS_830.device);
            fprintf(SRS_830.device, sprintf("TRCB? %1.0f, %3.0f, %3.0f", buffer2, starting_bin2, total_bins2));
            output = strtrim(fscanf(SRS_830.device));
            fclose(SRS_830.device);
        end
        
         %Set bin number non-normalized float
        function output = get_bin_numberL(SRS_830, buffer3, starting_bin3, total_bins3)
            try;fclose(SRS_830.device);end
            fopen(SRS_830.device);
            fprintf(SRS_830.device, sprintf("TRCL? %1.0f, %3.0f, %3.0f", buffer3, starting_bin3, total_bins3));
            output = strtrim(fscanf(SRS_830.device));
            fclose(SRS_830.device);
        end
        
        %Switch data transfer
        function set_read_aux(SRS_830, data)
            try;fclose(SRS_830.device);end
            fopen(SRS_830.device);
            fprintf(SRS_830.device, sprintf("Fast %1.0f", data));
            fclose(SRS_830.device);
        end
        
        %Start after switch data transfer
        function start_measurement(SRS_830)
            try;fclose(SRS_830.device);end
            fopen(SRS_830.device);
            fprintf(SRS_830.device, sprintf("STRD"));
            fclose(SRS_830.device);
        end
    end
    
end