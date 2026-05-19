classdef ZI_MFLI 

    properties (SetAccess = private)
    end

    properties (Transient)
        props
        N_demods
        output
    end

    methods

        function MFLI = ZI_MFLI(address)
            MFLI.props.devicetype = 'MFLI';
            MFLI.props.deviceid = address;
            MFLI.props.serveraddress = 'localhost';
            % ziDAQ('connect', 'localhost', 8004, 6);
            ziDAQ('connectDevice', address, '1GbE');

            MFLI.N_demods = numel(ziDAQ('listNodes', sprintf('/%s/demods', address) , 0));
            MFLI.output = 1;
        end

        %% disconnect
        function disconnect(MFLI)
            ziDAQ('disconnectDevice', MFLI.props.deviceid)
        end

        %% output settings
        function set_output_offset(MFLI, offset)
            amplitude = 0;
            for i = 1:MFLI.N_demods
                try
                    amplitude = amplitude + MFLI.get_amplitude(i);
                end
            end
            range = max(0.01, 10^ceil(log10(abs(offset) + abs(amplitude) * sqrt(2))));
            ziDAQ('setDouble', sprintf('/%s/sigouts/%1.0f/range', MFLI.props.deviceid, MFLI.output - 1), range)
            ziDAQ('setDouble', sprintf('/%s/sigouts/%1.0f/offset', MFLI.props.deviceid, MFLI.output - 1), offset)
        end

        function set_output_channel(MFLI, state, channel)
            arguments
                MFLI
                state
                channel = 1
            end

            switch state
                case {0, 1}
                    if MFLI.N_demods == 2
                        ziDAQ('setInt', sprintf('/%s/sigouts/%1.0f/enables/%01d', MFLI.props.deviceid, MFLI.output - 1, channel), state)
                    else
                        ziDAQ('setInt', sprintf('/%s/sigouts/%1.0f/enables/%01d', MFLI.props.deviceid, MFLI.output - 1, channel- 1), state)
                    end
                otherwise
                    cprintf('red','Invalid output state. Valid states : 1\n')
            end

        end

        function set_main_output(MFLI, state)
            ziDAQ('setInt', sprintf('/%s/sigouts/%1.0f/on', MFLI.props.deviceid, MFLI.output - 1), state)
        end

        function set_output_50Ohm(MFLI, state)
            switch state
                case {0, 1}
                    ziDAQ('setInt', sprintf('/%s/sigouts/%1.0f/imp50', MFLI.props.deviceid, MFLI.output - 1), state)
                otherwise
                    cprintf('red','Invalid output state. Valid states : 1\n')
            end
        end

        function set_output_diff(MFLI, state)
            switch state
                case 'A'
                    ziDAQ('setInt', sprintf('/%s/sigouts/%1.0f/diff', MFLI.props.deviceid, MFLI.output - 1), 0)
                case 'A-B'
                    ziDAQ('setInt', sprintf('/%s/sigouts/%1.0f/diff', MFLI.props.deviceid, MFLI.output - 1), 1)
                otherwise
                    cprintf('red','Invalid output state. Valid states : A and A-B\n')
            end
        end

        function set_amplitude(MFLI, amplitude, channel)
            arguments
                MFLI
                amplitude
                channel = 1
            end
            offset = MFLI.get_offset;
            amplitude_array = zeros(MFLI.N_demods, 1);
            for i = 1:MFLI.N_demods
                try
                    amplitude_array(i) = MFLI.get_amplitude(i);
                end
            end
            amplitude_array(channel) = amplitude;

            range = max(0.01, 10^ceil(log10(abs(offset) + abs(sum(amplitude_array)) * sqrt(2))));
            ziDAQ('setDouble', sprintf('/%s/sigouts/%1.0f/range', MFLI.props.deviceid, MFLI.output - 1), range)
            if MFLI.N_demods == 2
                ziDAQ('setDouble', sprintf('/%s/sigouts/%1.0f/amplitudes/%01d', MFLI.props.deviceid, 0, 1), amplitude * sqrt(2))
            else
                ziDAQ('setDouble', sprintf('/%s/sigouts/%1.0f/amplitudes/%01d', MFLI.props.deviceid, MFLI.output - 1, channel - 1), amplitude * sqrt(2))
            end
        end

        function set_output_adder(MFLI, state)
            ziDAQ('setInt', sprintf('/%s/sigouts/%1.0f/add', MFLI.props.deviceid, MFLI.output - 1), state)
        end

        %% Input settings
        function set_input_range(MFLI, range)
            ziDAQ('setDouble', sprintf('/%s/sigins/%1.0f/range', MFLI.props.deviceid, 0), range)
        end

        function set_input_AC(MFLI, state)
            ziDAQ('setInt', sprintf('/%s/sigins/%1.0f/ac', MFLI.props.deviceid, MFLI.output - 1), state)
        end

        function set_input_diff(MFLI, state)
            switch state
                case 'A'
                    ziDAQ('setInt', sprintf('/%s/sigins/%1.0f/diff', MFLI.props.deviceid, MFLI.output - 1), 0)
                case 'A-B'
                    ziDAQ('setInt', sprintf('/%s/sigins/%1.0f/diff', MFLI.props.deviceid, MFLI.output - 1), 1)
                otherwise
                    cprintf('red','Invalid output state. Valid states : A and A-B\n')
            end
        end

        function set_input_50Ohm(MFLI, state)
            ziDAQ('setInt', sprintf('/%s/sigins/%1.0f/imp50', MFLI.props.deviceid, MFLI.output - 1), state)
        end

        function set_input_float(MFLI, state)
            ziDAQ('setInt', sprintf('/%s/sigins/%1.0f/float', MFLI.props.deviceid, MFLI.output - 1), state)
        end

        function set_sensitivity(MFLI, value)
            ziDAQ('setDouble', sprintf('/%s/sigins/%1.0f/scaling', MFLI.props.deviceid, MFLI.output - 1), 10/value)
        end

        function autorange(MFLI)
            ziDAQ('setInt', sprintf('/%s/sigins/0/autorange', MFLI.props.deviceid), 1);
        end

        %% get settings
        function offset = get_offset(MFLI)
            offset = ziDAQ('getDouble', sprintf('/%s/sigouts/%1.0f/offset', MFLI.props.deviceid, MFLI.output - 1));
        end

        function amplitude = get_amplitude(MFLI, channel)
            amplitude = ziDAQ('getDouble', sprintf('/%s/sigouts/%1.0f/amplitudes/%01d', MFLI.props.deviceid, MFLI.output - 1, channel - 1));
        end

        %% Oscillator settings
        function set_frequency(MFLI, frequency, osc)
            arguments
                MFLI
                frequency
                osc = 1
            end
            ziDAQ('setDouble', sprintf('/%s/oscs/%1.0f/freq', MFLI.props.deviceid, osc - 1), frequency)
        end

        function set_data_rate(MFLI, rate, demod)
            arguments
                MFLI
                rate
                demod = 1
            end
            ziDAQ('setDouble', sprintf('/%s/demods/%1.0f/rate', MFLI.props.deviceid, demod - 1), rate)
        end

        function rate = get_data_rate(MFLI, demod)
            rate = ziDAQ('getDouble', sprintf('/%s/demods/%1.0f/rate', MFLI.props.deviceid, demod - 1));
        end


        %% Demodulator settings
        function set_reference(MFLI, reference, demod)
            arguments
                MFLI
                reference
                demod = 1
            end
            switch reference
                case 'Internal'
                    ziDAQ('setInt', sprintf('/%s/extrefs/%1.0f/enable', MFLI.props.deviceid, demod - 1), 0)
                case 'External'
                    ziDAQ('setInt', sprintf('/%s/extrefs/%1.0f/enable', MFLI.props.deviceid, demod - 1), 1)
                otherwise
                    cprintf('red','Invalid reference. Valid reference : Internal and External\n')
            end
        end

        function set_harmonic(MFLI, harmonic, demod)
            arguments
                MFLI
                harmonic
                demod = 1
            end
            ziDAQ('setDouble', sprintf('/%s/demods/%1.0f/harmonic', MFLI.props.deviceid, demod - 1), harmonic)
        end

        function set_phase(MFLI, phase, demod)
            arguments
                MFLI
                phase
                demod = 1
            end
            ziDAQ('setDouble', sprintf('/%s/demods/%1.0f/phaseshift', MFLI.props.deviceid, demod - 1), phase)
        end

        function set_filter_order(MFLI, order, demod)
            arguments
                MFLI
                order
                demod = 1
            end
            ziDAQ('setInt', sprintf('/%s/demods/%1.0f/order', MFLI.props.deviceid, demod - 1), order)
        end

        function set_timeconstant(MFLI, timeconstant, demod)
            arguments
                MFLI
                timeconstant
                demod = 1
            end
            ziDAQ('setDouble', sprintf('/%s/demods/%1.0f/timeconstant', MFLI.props.deviceid, demod - 1), timeconstant)
        end

        function output =  get_timeconstant(MFLI, demod)
            arguments
                MFLI
                demod = 1
            end
            output = ziDAQ('getDouble', sprintf('/%s/demods/%1.0f/timeconstant', MFLI.props.deviceid, demod - 1));
        end

        function set_sinc(MFLI, state, demod)
            arguments
                MFLI
                state
                demod = 1
            end
            ziDAQ('setInt', sprintf('/%s/demods/%1.0f/sinc', MFLI.props.deviceid, demod - 1), state)
        end

        function set_demodulator_state(MFLI, state, demod)
            arguments
                MFLI
                state
                demod = 1
            end
            ziDAQ('setInt', sprintf('/%s/demods/%1.0f/enable', MFLI.props.deviceid, demod - 1), state)
        end

        function set_input_demod(MFLI, demod, input)
            arguments
                MFLI
                demod
                input
            end

            switch upper(input)
                case 'SIG IN 1'
                    state = 0 ;
                case 'CURR IN 1'
                    state = 1 ;
                case 'TRIGGER 1'
                    state = 2 ;
                case 'TRIGGER 2'
                    state = 3 ;
                case 'AUX OUT 1'
                    state = 4 ;
                case 'AUX OUT 2'
                    state = 5 ;
                case 'AUX OUT 3'
                    state = 6 ;
                case 'AUX OUT 4'
                    state = 7 ;
                case 'AUX IN 1'
                    state = 8 ;
                case 'AUX IN 2'
                    state = 9 ;
                case 'CONSTANT'
                    state = 174 ;
            end

            ziDAQ('setInt', sprintf('/%s/demods/%1.0f/adcselect', MFLI.props.deviceid, demod - 1), state)
        end

        function set_demodulator_oscillator(MFLI, demod, osc)
            arguments
                MFLI
                demod
                osc
            end
            ziDAQ('setInt', sprintf('/%s/demods/%1.0f/oscselect', MFLI.props.deviceid, demod - 1), osc - 1)
        end

        %% trigger settings
        function set_trigger_continuous(MFLI, demod)
            arguments
                MFLI
                demod
            end
            ziDAQ('setInt', sprintf('/%s/demods/%1.0f/trigger', MFLI.props.deviceid, demod - 1), 0)
        end

        %% set aux out
        function set_aux_out(MFLI, aux, state, scaling)
            ziDAQ('setInt', sprintf('/%s/auxouts/%1.0f/outputselect', MFLI.props.deviceid, aux - 1), state - 1)
            ziDAQ('setDouble', sprintf('/%s/auxouts/%1.0f/scale', MFLI.props.deviceid, aux - 1), scaling)
        end

        %% set AUX averaging
        function set_auxin_averaging(MFLI, aux, state)
                    ziDAQ('setInt', sprintf('/%s/raw/auxins/%1.0f/on', MFLI.props.deviceid, aux - 1), state)
        end

        function set_auxin_averaging_samples(MFLI, aux, samples)
            samples_log = log(samples)/log(2);
            array = 2:15;
            idx = min(abs(array - samples_log)) == abs(array - samples_log);
            ziDAQ('setInt', sprintf('/%s/auxins/%1.0f/averaging', MFLI.props.deviceid, aux - 1), array(idx));
        end

    end
end
