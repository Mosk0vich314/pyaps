function Lockin = Init_lockin(Lockin)

if ~isfield(Lockin,'model')
    Lockin.model = 'ZI_MFLI';
end

Lockin.model = upper(Lockin.model);

func_lockin = str2func(Lockin.model);
Lockin.dev = func_lockin(Lockin.address);

%% check if all basic options are present

% switch to 50 Ohm output
if ~isfield(Lockin, '50Ohm')
    Lockin.output_50Ohm = 0;
end

% switch to diff output
if ~isfield(Lockin, 'output_diff')
    Lockin.output_diff = 'A';
end

% switch off output adders
if ~isfield(Lockin, 'output_add')
    Lockin.output_add = 0;
end

% switch to DC coupling
if ~isfield(Lockin, 'input_AC')
    Lockin.input_AC = 0;
end

% switch to single ended input
if ~isfield(Lockin, 'input_diff')
    Lockin.input_diff = 'A';
end

% switch to 50 Ohm input
if ~isfield(Lockin, 'input_50Ohm')
    Lockin.input_50Ohm = 0;
end

% switch to floating input
if ~isfield(Lockin, 'input_float')
    Lockin.input_float = 1;
end

% set sensitivity
if ~isfield(Lockin, 'sensitivity')
    Lockin.sensitivity = 10;
end

% set input range
if ~isfield(Lockin, 'input_range')
    Lockin.input_range = 1;
end

% set phaseshifts
if ~isfield(Lockin, 'phaseshift')
    Lockin.phaseshift = 0;
end

% set harmonics
if ~isfield(Lockin, 'harmonic')
    Lockin.harmonic = 1;
end

% set reference to internal
if ~isfield(Lockin, 'reference')
    Lockin.reference = {'Internal'};
end

% set filter order
if ~isfield(Lockin, 'filter_order')
    Lockin.filter_order = 4;
end

% set sinc
if ~isfield(Lockin, 'sinc')
    Lockin.sinc = 0;
end

% set line filter
if ~isfield(Lockin, 'line_filter')
    Lockin.line_filter = 0;
end

switch Lockin.model
    case 'SRS830'

        %% set output
        % switch output to zero
        Lockin.dev.set_amplitude(0);   %V

        % switch to 50 Ohm output
        Lockin.dev.set_output_50Ohm(Lockin.output_50Ohm);

        % switch to diff output
        Lockin.dev.set_output_diff(Lockin.output_diff);

        % switch off output adders
        Lockin.dev.set_output_adder(Lockin.output_add);

        %% set input
        % switch to DC coupling
        Lockin.dev.set_input_AC(Lockin.input_AC);

        % switch to single ended input
        Lockin.dev.set_input_diff(Lockin.input_diff);

        % switch to 50 Ohm input
        Lockin.dev.set_input_50Ohm(Lockin.input_50Ohm);

        % switch to floating input
        Lockin.dev.set_input_float(Lockin.input_float);

        % set sensitivity
        Lockin.dev.set_sensitivity(Lockin.sensitivity);      %V

        %% set modulator and demodulator

        % set frequency
        Lockin.dev.set_frequency(Lockin.frequency(1));

        % set phaseshifts
        Lockin.dev.set_phase(Lockin.phaseshift);

        % set harmonics
        Lockin.dev.set_harmonic(Lockin.harmonic);

        % set reference to internal
        Lockin.dev.set_reference(Lockin.reference{1});

        % set filter order
        Lockin.dev.set_filter_order(Lockin.filter_order);

        % set timconstant
        Lockin.dev.set_timeconstant(Lockin.timeconstant);

        % set sinc
        Lockin.dev.set_sinc(Lockin.sinc);

        % set line filter
        Lockin.dev.set_line_filter(Lockin.line_filter);

    case 'ZI_MFLI'

        %% get oscillators and demodulators
        if ~isfield(Lockin, 'oscillator')
            Lockin.oscillator = 1;
        end

        Lockin.N_demods_max = numel(ziDAQ('listNodes', sprintf('/%s/demods', Lockin.address) , 0));
        Lockin.N_demods = max([numel(Lockin.frequency) numel(Lockin.harmonic) numel(Lockin.timeconstant) numel(Lockin.oscillator)]);

        Lockin.N_osc = numel(Lockin.frequency);

        %% set output to default
        % switch output to zero
        for i = 1:Lockin.N_demods_max
            try
                Lockin.dev.set_amplitude(0, i);
                Lockin.dev.set_output_channel(0, i); % disable output
            end
        end

        % set output offset to zero
        Lockin.dev.set_output_offset(0);

        % switch on main output
        Lockin.dev.set_main_output(1);

        %% disable demodulators
        for i = 1:Lockin.N_demods_max
            try
                Lockin.dev.set_demodulator_state(0, i); % disable demodulator
            end
        end

        %% set output
        % switch to 50 Ohm output
        Lockin.dev.set_output_50Ohm(Lockin.output_50Ohm);

        % switch to diff output
        Lockin.dev.set_output_diff(Lockin.output_diff);

        % switch off output adders
        Lockin.dev.set_output_adder(Lockin.output_add);

        % switch on output of oscillator
        if ~isfield(Lockin, 'osc_output')
            Lockin.osc_output = 1;
        end

        for i = 1:numel(Lockin.osc_output)
            Lockin.dev.set_output_channel(Lockin.osc_output(i), i);
        end

        %% set input
        % switch to DC coupling
        Lockin.dev.set_input_AC(Lockin.input_AC);

        % switch to single ended input
        Lockin.dev.set_input_diff(Lockin.input_diff);

        % switch to 50 Ohm input
        Lockin.dev.set_input_50Ohm(Lockin.input_50Ohm);

        % switch to floating input
        Lockin.dev.set_input_float(Lockin.input_float);

        % set sensitivity
        Lockin.dev.set_sensitivity(Lockin.sensitivity);      %V

        % set input range
        Lockin.dev.set_input_range(Lockin.input_range);

        %% set oscillator
        % set frequency
        for i = 1:Lockin.N_osc
            Lockin.dev.set_frequency(Lockin.frequency(i), i);
        end

        %% reset all harmonic to avoid demodulator bug
        for i = 1:4
            try
                Lockin.dev.set_harmonic(1, i);
            end
        end

        %% set demodulator
        if ~isfield(Lockin, 'datarate')
            Lockin.datarate = 10e3;
        end

        if ~isfield(Lockin, 'input_demod')
            Lockin.input_demod = {'Sig In 1'};
        end

        for i = 1:Lockin.N_demods

            % set oscillators input
            if numel(Lockin.demod_oscillator) == 1
                Lockin.dev.set_demodulator_oscillator(i, Lockin.demod_oscillator);
            else
                Lockin.dev.set_demodulator_oscillator(i, Lockin.demod_oscillator(i));
            end

            % set harmonics
            if numel(Lockin.harmonic) == 1
                Lockin.dev.set_harmonic(Lockin.harmonic, i);
            else
                Lockin.dev.set_harmonic(Lockin.harmonic(i), i);
            end

            % set filter order
            if numel(Lockin.filter_order) == 1
                Lockin.dev.set_filter_order(Lockin.filter_order, i);
            else
                Lockin.dev.set_filter_order(Lockin.filter_order(i), i);
            end

            % set phaseshifts
            if numel(Lockin.phaseshift) == 1
                Lockin.dev.set_phase(Lockin.phaseshift, i);
            else
                Lockin.dev.set_phase(Lockin.phaseshift(i), i);
            end

            % set timeconstant
            if numel(Lockin.timeconstant) == 1
                Lockin.dev.set_timeconstant(Lockin.timeconstant, i);
            else
                Lockin.dev.set_timeconstant(Lockin.timeconstant(i), i);
            end

            % enable demodulator
            Lockin.dev.set_demodulator_state(1, i);

            % set datarate
            if numel(Lockin.datarate) == 1
                Lockin.dev.set_data_rate(Lockin.datarate, i);
                Lockin.datarate = round(Lockin.dev.get_data_rate(1));
            else
                Lockin.dev.set_data_rate(Lockin.datarate(i), i);
                Lockin.datarate(i) = round(Lockin.dev.get_data_rate(i));
            end
        end

        % set reference to internal
        Lockin.dev.set_reference(Lockin.reference{1}, 1);

        % set input for demodulators
        if numel(Lockin.input_demod) == 1
            Lockin.dev.set_input_demod(i, Lockin.input_demod{1});
        else
            Lockin.dev.set_input_demod(i, Lockin.input_demod{i});
        end

        % set continuous data acquisition
        Lockin.dev.set_trigger_continuous(i);
end

%% lowercase device address
Lockin.address = lower(Lockin.address);

%% set AUX out for data output
% set AUX OUT to X/Y/R/Theta
Lockin.dev.set_aux_out(1,1,1);
Lockin.dev.set_aux_out(2,2,1);
Lockin.dev.set_aux_out(3,3,1);
Lockin.dev.set_aux_out(4,4,1/18);

%% sync all settings
ziDAQ('sync');

return