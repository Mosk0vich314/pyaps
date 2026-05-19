classdef ZI_HF2_LI < handle
    
    properties (SetAccess = private)
        address
        port
        device_id
    end
    
    properties (Transient)
    end
    
    methods
        
        function ZI_HF2 = ZI_HF2_LI(device_id, address, port)
            ZI_HF2.address = address;
            ZI_HF2.port = port;
            ZI_HF2.device_id = device_id;
            ziDAQ('connect', ZI_HF2.address, ZI_HF2.port);
        end
        
        %% disconnect
        function connect(ZI_HF2)
            ziDAQ('connect', ZI_HF2.address, ZI_HF2.port)
        end
        
        %% connect
        function disconnect(ZI_HF2)
            ziDAQ('disconnectDevice', ZI_HF2.device_id)
        end
        
        %% Input settings
        function set_sensitivity(ZI_HF2, input, sensitivity)
            input = input - 1;
            if input == 1 || input == 0
                ziDAQ('setDouble', sprintf('/%s/sigins/%1.0f/range', ZI_HF2.device_id, input), sensitivity)
            else
                cprintf('red','Invalid input. Valid inputs : 1 and 2\n')
            end
        end
        
        function set_input_AC(ZI_HF2, input, state)
            input = input - 1;
            if input == 1 || input == 0
                ziDAQ('setInt', sprintf('/%s/sigins/%1.0f/ac', ZI_HF2.device_id, input), state)
            else
                cprintf('red','Invalid input. Valid inputs : 1 and 2\n')
            end
        end
        
        function set_input_diff(ZI_HF2, input, state)
            input = input - 1;
            if input == 1 || input == 0
                ziDAQ('setInt', sprintf('/%s/sigins/%1.0f/diff', ZI_HF2.device_id, input), state)
            else
                cprintf('red','Invalid input. Valid inputs : 1 and 2\n')
            end
        end
        
        function set_input_50ohm(ZI_HF2, input, state)
            input = input - 1;
            if input == 1 || input == 0
                ziDAQ('setInt', sprintf('/%s/sigins/%1.0f/imp50', ZI_HF2.device_id, input), state)
            else
                cprintf('red','Invalid input. Valid inputs : 1 and 2\n')
            end
        end
        
        %% output settings
        function set_output_state(ZI_HF2, output, state)
            output = output - 1;
            if output == 1 || output == 0
                switch state
                    case 0
                        ziDAQ('setInt', sprintf('/%s/sigouts/%1.0f/on', ZI_HF2.device_id, output), 0)
                    case 1
                        ziDAQ('setInt', sprintf('/%s/sigouts/%1.0f/on', ZI_HF2.device_id, output), 1)
                    otherwise
                        cprintf('red','Invalid output state. Valid states : 0 and 1\n')
                end
            else
                cprintf('red','Invalid output. Valid inputs : 1 and 2\n')
            end
        end
        
        function set_amplitude(ZI_HF2, output, amplitude)
            output = output - 1;
            if amplitude ~= 0
                range = max(0.01, 10^ceil(log10(amplitude)));
            else
                range = 0.01;
            end
            
            if output == 1 || output == 0
                ziDAQ('setDouble', sprintf('/%s/sigouts/%1.0f/range', ZI_HF2.device_id, output), range)
                ziDAQ('setDouble', sprintf('/%s/sigouts/%1.0f/amplitudes/*', ZI_HF2.device_id, output), amplitude / range)
            else
                cprintf('red','Invalid output. Valid inputs : 1 and 2\n')
            end
        end
        
        function set_output_range(ZI_HF2, output, range)
            output = output - 1;
            if range ~= 0
                range = 10^ceil(log10(range*1.5));
            end
            
            if output == 1 || output == 0
                ziDAQ('setInt', sprintf('/%s/sigouts/%1.0f/range', ZI_HF2.device_id, output), range)
            else
                cprintf('red','Invalid output. Valid inputs : 1 and 2\n')
            end
        end
        
        function set_output_enable(ZI_HF2, output, state)
            output = output - 1;
            if output == 1 || output == 0
                ziDAQ('setInt', sprintf('/%s/sigouts/%1.0f/enables/*', ZI_HF2.device_id, output), state)
            else
                cprintf('red','Invalid output. Valid inputs : 1 and 2\n')
            end
        end
        
        function set_output_adder(ZI_HF2, output, state)
            output = output - 1;
            if output == 1 || output == 0
                ziDAQ('setInt', sprintf('/%s/sigouts/%1.0f/add', ZI_HF2.device_id, output), state)
            else
                cprintf('red','Invalid output. Valid inputs : 1 and 2\n')
            end
        end
        
        %% Oscillator settings
        function set_oscillator_frequency(ZI_HF2, output, frequency)
            output = output - 1;
            if output == 1 || output == 0
                ziDAQ('setDouble', sprintf('/%s/oscs/%1.0f/freq', ZI_HF2.device_id, output), frequency)
            else
                cprintf('red','Invalid output. Valid inputs : 1 and 2\n')
            end
        end
        
        %% Demodulator settings
        function set_oscillator_reference(ZI_HF2, input, reference)
            input = input - 1;
            if input == 1 || input == 0
                ziDAQ('setInt', sprintf('/%s/plls/%1.0f/enable', ZI_HF2.device_id, input), reference)
            else
                cprintf('red','Invalid input. Valid inputs : 1 and 2\n')
            end
        end
        
        function set_harmonic(ZI_HF2, demodulator, harmonic)
            demodulator = demodulator - 1;
            if demodulator >= 0 && demodulator <= 5
                ziDAQ('setInt', sprintf('/%s/demods/%1.0f/harmonic', ZI_HF2.device_id, demodulator), harmonic)
            else
                cprintf('red','Invalid demodulator. Valid demodulator : 1 - 6\n')
            end
        end
        
        function set_phaseshift(ZI_HF2, demodulator, phaseshift)
            demodulator = demodulator - 1;
            if demodulator >= 0 && demodulator <= 5
                ziDAQ('setDouble', sprintf('/%s/demods/%1.0f/phaseshift', ZI_HF2.device_id, demodulator), phaseshift)
            else
                cprintf('red','Invalid demodulator. Valid demodulator : 1 - 6\n')
            end
        end     
        
        function set_filter_rolloff(ZI_HF2, demodulator, rolloff)
            demodulator = demodulator - 1;
            if demodulator >= 0 && demodulator <= 5
                ziDAQ('setInt', sprintf('/%s/demods/%1.0f/order', ZI_HF2.device_id, demodulator), rolloff)
            else
                cprintf('red','Invalid demodulator. Valid demodulator : 1 - 6\n')
            end
        end
                         
        function set_timeconstant(ZI_HF2, demodulator, timeconstant)
            demodulator = demodulator - 1;
            if demodulator >= 0 && demodulator <= 5
                ziDAQ('setDouble', sprintf('/%s/demods/%1.0f/timeconstant', ZI_HF2.device_id, demodulator), timeconstant)
            else
                cprintf('red','Invalid demodulator. Valid demodulator : 1 - 6\n')
            end
        end
              
        function set_sinc(ZI_HF2, demodulator, state)
            demodulator = demodulator - 1;
            if demodulator >= 0 && demodulator <= 5
                ziDAQ('setInt', sprintf('/%s/demods/%1.0f/sinc', ZI_HF2.device_id, demodulator), state)
            else
                cprintf('red','Invalid demodulator. Valid demodulator : 1 - 6\n')
            end
        end
        
        function set_demodulator_state(ZI_HF2, demodulator, state)
            demodulator = demodulator - 1;
            if demodulator >= 0 && demodulator <= 5
                ziDAQ('setInt', sprintf('/%s/demods/%1.0f/enable', ZI_HF2.device_id, demodulator), state)
            else
                cprintf('red','Invalid demodulator. Valid demodulator : 1 - 6\n')
            end
        end
        
        function set_demod_reference(ZI_HF2, demodulator, state)
            demodulator = demodulator - 1;
            if demodulator >= 0 && demodulator <= 5
                ziDAQ('setInt', sprintf('/%s/demods/%1.0f/oscselect', ZI_HF2.device_id, demodulator), state)
            else
                cprintf('red','Invalid demodulator. Valid demodulator : 1 - 6\n')
            end
        end
             
        %% trigger settings
                        
        function set_trigger_continuous(ZI_HF2, input)
            input = input - 1;
            if input >= 0 && input <= 1
                ziDAQ('setInt', sprintf('/%s/demods/%1.0f/trigger', ZI_HF2.device_id, input * 3), 0)
            else
                cprintf('red','Invalid input. Valid inputs : 1 and 2\n')
            end
        end
        
        function set_trigger_rate(ZI_HF2, input, rate)
            input = input - 1;
            if input >= 0 && input <= 1
                ziDAQ('setDouble', sprintf('/%s/demods/%1.0f/rate', ZI_HF2.device_id, input * 3), rate)
            else
                cprintf('red','Invalid input. Valid inputs : 1 and 2\n')
            end
        end
             
        %% get data
        function output = get_data(ZI_HF2, input)
            
            poll_flag = 0; % Flags specifying data polling properties
            poll_timeout = 100; %ms
            
            done = 0;
            while done == 0
                try
                    ziDAQ('unsubscribe', '*');
                    ziDAQ('sync');
                    ziDAQ('subscribe',sprintf('/%s/demods/*/sample', ZI_HF2.device_id))
                    data = ziDAQ('poll', input.acquisition_time, poll_timeout, poll_flag);
                    data = data.(ZI_HF2.device_id).demods;
                    
                    N_demods = numel(data);
                    clockbase = double(ziDAQ('getInt', '/DEV39/clockbase'));
                    
                    for i = 1:N_demods
                        time = (double(data(i).sample.timestamp) - double(data(i).sample.timestamp))/clockbase;
                        output(i).time = time';
                        output(i).x = data(i).sample.x';
                        output(i).y = data(i).sample.y';
                        output(i).r = abs(output(i).x + 1j*output(i).y);
                        output(i).theta = rad2deg(angle(output(i).x + 1j*output(i).y));
                    end
                    output = output(input.harmonic~=0);
                    done = 1;
                catch
                    disp('measurement error... retrying')
                end
            end
        end
        
         %% get data inputs
        function output = get_data_inputs(ZI_HF2, input)
            
            poll_flag = 0; % Flags specifying data polling properties
            poll_timeout = 100; %ms
            
            done = 0;
            while done == 0
                try
                    ziDAQ('unsubscribe', '*');
                    ziDAQ('sync');
                    ziDAQ('subscribe',sprintf('/%s/sigins/*/sample', ZI_HF2.device_id))
                    data = ziDAQ('poll', input.acquisition_time, poll_timeout, poll_flag);
                    data = data.(ZI_HF2.device_id).demods;
                    
                    N_demods = numel(data);
                    clockbase = double(ziDAQ('getInt', '/DEV39/clockbase'));
                    
                    for i = 1:N_demods
                        time = (double(data(i).sample.timestamp) - double(data(i).sample.timestamp))/clockbase;
                        output(i).time = time';
                        output(i).x = data(i).sample.x';
                        output(i).y = data(i).sample.y';
                        output(i).r = abs(output(i).x + 1j*output(i).y);
                        output(i).theta = rad2deg(angle(output(i).x + 1j*output(i).y));
                    end
                    output = output(input.harmonic~=0);
                    done = 1;
                catch
                    disp('measurement error... retrying')
                end
            end
        end
        
        %% get data inputs
        function set_aux_output_signal(ZI_HF2, aux_channel, signal )
            if strcmp(signal, 'X'); signal_number = 0; end
            if strcmp(signal, 'Y'); signal_number = 1; end
            if strcmp(signal, 'R'); signal_number = 2; end
            if strcmp(signal, 'Theta'); signal_number = 3; end
            ziDAQ('setInt', sprintf('/%s/auxouts/%1.0f/outputselect', ZI_HF2.device_id, aux_channel-1), signal_number)
        end
        function set_aux_output_demod(ZI_HF2, aux_channel, demod_number)
            ziDAQ('setInt', sprintf('/%s/auxouts/%1.0f/demodselect', ZI_HF2.device_id, aux_channel-1), demod_number - 1)
        end
        function set_aux_output_scale(ZI_HF2, aux_channel, scale)
            ziDAQ('setDouble', sprintf('/%s/auxouts/%1.0f/scale', ZI_HF2.device_id, aux_channel-1), scale)
        end
        function scale = get_aux_output_scale(ZI_HF2, aux_channel)
            scale = ziDAQ('getDouble', sprintf('/%s/auxouts/%1.0f/scale', ZI_HF2.device_id, aux_channel-1));
        end
    end
    
end