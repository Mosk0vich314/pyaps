function Structure = Apply_fixed_voltage(Settings, Structure)

%% check electronics to apply fixed_voltage voltage
if isfield(Structure, 'fixed_voltage')
    fixed_voltage = Structure.fixed_voltage;
else
    fixed_voltage = 'ADwin';
end

%% check if wait for finish is defined
if ~isfield(Structure, 'wait_for_finish')
    Structure.wait_for_finish = 1;
end

%% check if scanrate is defined
if ~isfield(Structure, 'scanrate')
    Structure.scanrate = 30000;
end

if startsWith(fixed_voltage, 'ADwin')

    % check if 24 bit to be used

    if isfield(Structure,'dV') && isscalar(Structure.output)
        if Structure.dV < 1 * (2*Settings.input_range / 2 ^ Settings.output_resolution)  % check for 24 bit output
            Structure.bit24 = 1;

            % check if last measurement
            if ~Process_Status(4)
                Set_Par(33, 0);
            end

            if isfield(Settings,'timestamp_stop')
                Stop_Process(4)
                Set_Par(33, 0);
                Structure.bit24 = 0;
            end
        end
    end
    
    Structure.bit24 = 0;

    %% check if 24 bit is used
    if Structure.bit24 == 0
        for idx = 1:length(Structure.output)

            %% set parameters
            % set addresses
            Set_Par(6,Settings.AO_address);
            % set output channel
            Set_Par(9,Structure.output(idx));
            % set voltages
            [Structure.startV_bin(idx), Structure.startV_new(idx)] = convert_V_to_bin(Structure.startV(idx) / Structure.V_per_V(idx), Settings.output_min, Settings.output_max, Settings.output_resolution);
            Structure.startV_new(idx) = Structure.startV_new(idx) * Structure.V_per_V(idx);
            Structure.startV_bin(idx) = Structure.startV_bin(idx) - 1;
            Set_Par(41, Structure.startV_bin(idx));

            [Structure.setV_bin(idx), Structure.setV_new(idx)] = convert_V_to_bin(Structure.setV(idx) / Structure.V_per_V(idx), Settings.output_min, Settings.output_max, Settings.output_resolution);
            Structure.setV_new(idx) = Structure.setV_new(idx) * Structure.V_per_V(idx);
            Structure.setV_bin(idx) = Structure.setV_bin(idx) - 1;
            Set_Par(42, Structure.setV_bin(idx));

            % set ramp rate by adjusting process delay
            Structure.max_frequency(idx) =  Structure.ramp_rate(idx) / ((Settings.output_max - Settings.output_min) / (2^Settings.output_resolution)) / Structure.V_per_V(idx);
            Structure.time_per_point(idx) = 1 / Structure.max_frequency(idx);
            [Structure.process_delay, ~]  =  get_delays(Structure.max_frequency(idx), 0, Settings.clockfrequency);
            Set_Processdelay(3, Structure.process_delay);

            %% run measurement
            run = true;
            Start_Process(3);
            while run && Structure.wait_for_finish
                run = Process_Status(3);
            end
        end

    else
        % first time setting gate
        gate24.process_number = 4;
        gate24.bitIncrease = 8;
        gate24.signalLength = 4^gate24.bitIncrease; % 4
        gate24.settling_time = 0;
        gate24.scanrate = 300000;
        gate24.SignalWidth = 12;
        gate24.signalLengthBlock = 256;

        if Get_Par(33) == 0
            Stop_Process(4);
            if isscalar(Structure.output)

                % intial ramping
                [Structure.startV_bin, Structure.startV_new] = convert_V_to_bin(Structure.startV / Structure.V_per_V, Settings.output_min, Settings.output_max, Settings.output_resolution);
                Structure.startV_new = Structure.startV_new * Structure.V_per_V;
                Structure.startV_bin = Structure.startV_bin - 1 ;
                Set_Par(41, Structure.startV_bin);
                [Structure.setV_bin, Structure.setV_new] = convert_V_to_bin(Structure.setV / Structure.V_per_V, Settings.output_min, Settings.output_max, Settings.output_resolution);
                Structure.setV_new = Structure.setV_new * Structure.V_per_V;
                Structure.setV_bin = Structure.setV_bin - 1;
                Set_Par(42, Structure.setV_bin);

                % oversampled randomized signal
                gate24.Vout = Structure.setV / Structure.V_per_V;
                gate24 = construct_24bit_signal(Settings, gate24);
                [gate24.process_delay, ~] = get_delays(gate24.scanrate, gate24.settling_time, Settings.clockfrequency);  % get_delays
                Set_Par(6, Settings.AO_address);
                Set_Par(9, Structure.output);
                Set_Par(31, gate24.signalLength);
                SetData_Double(5, gate24.signalSent, 1);
                Set_Processdelay(gate24.process_number, gate24.process_delay);
                Start_Process(gate24.process_number);
                Structure.gate24 = gate24;
                Structure.type = Settings.fixed_voltage;
            end
        end

        % Only updating the gate signal
        if Get_Par(33) == 1
            gate24.Vout = Structure.setV / Structure.V_per_V;
            gate24 = construct_24bit_signal(Settings, gate24);
            if Get_Par(32) == 0
                SetData_Double(6, gate24.signalSent, 1);
                Set_Par(32, 1);
            end
            if Get_Par(32) == 1
                SetData_Double(5, gate24.signalSent, 1);
                Set_Par(32, 0);
            end
            Structure.gate24 = gate24;
            Structure.type = Settings.fixed_voltage;
        end
    end

    %% OptoDAC
elseif startsWith(fixed_voltage, 'OptoDAC')
    for idx = 1:length(Structure.output)

        dV_tot = abs(Structure.setV(idx) - Structure.startV(idx));
        dt_tot = dV_tot / Structure.ramp_rate(idx);

        Structure.max_frequency = 10; % max 10 point per second
        N_points = ceil(dt_tot * Structure.max_frequency);

        dV = dV_tot / N_points;      % 1 mV
        dV = max(dV, 0.0001);
        Structure.time_per_point(idx) = 1 / Structure.max_frequency;

        if Structure.startV(idx) < Structure.setV(idx)
            amps = Structure.startV(idx):dV:Structure.setV(idx);
        else
            amps = Structure.startV(idx):-dV:Structure.setV(idx);
        end

        clear OptoDAC
        OptoDAC = OptoDAC_D5('COM4');
        if OptoDAC.error ~= 1
            for i = 1:length(amps)
                OptoDAC.set_DAC(Structure.output(idx), amps(i) / Structure.V_per_V(idx));
                pause(Structure.time_per_point(idx))
            end
            OptoDAC.set_DAC(Structure.output(idx), Structure.setV(idx) / Structure.V_per_V(idx));
        else
            break
        end
    end

    %% ZI MFLI with offset
elseif startsWith(upper(fixed_voltage), 'DEV') && isempty(regexp(upper(fixed_voltage), 'AUX','once')) % ZI_MFLI offset
    dV_tot = abs(Structure.setV - Structure.startV);
    dt_tot = dV_tot / Structure.ramp_rate;

    Structure.max_frequency = 5; % max 10 point per second
    N_points = ceil(dt_tot * Structure.max_frequency);

    dV = dV_tot / N_points;      % 1 mV
    %     dV = max(dV, 0.00001);
    Structure.time_per_point = 1 / Structure.max_frequency;

    if Structure.startV < Structure.setV
        amps = Structure.startV:dV:Structure.setV;
    else
        amps = Structure.startV:-dV:Structure.setV;
    end

    amps = amps / Structure.V_per_V;

    for i = 1:length(amps)
        range = max(0.01, 10^ceil(log10(abs(amps(i)) * sqrt(2))));
        ziDAQ('setDouble', sprintf('/%s/sigouts/0/range', Structure.fixed_voltage), range)
        ziDAQ('setDouble', sprintf('/%s/sigouts/0/offset', Structure.fixed_voltage), amps(i));
        pause(Structure.time_per_point)
    end

    %% ZI MFLI with AUX
elseif startsWith(upper(fixed_voltage), 'DEV') && ~isempty(regexp(upper(fixed_voltage), 'AUX','once')) % ZI_MFLI aux out

    tmp = regexp(upper(fixed_voltage), '(DEV\d+)_AUX(\d*)','tokens');
    address = tmp{1}{1};
    output = str2double(tmp{1}{2});

    dV_tot = abs(Structure.setV - Structure.startV);
    dt_tot = dV_tot / Structure.ramp_rate;

    Structure.max_frequency = 5; % max 10 point per second
    N_points = ceil(dt_tot * Structure.max_frequency);

    dV = dV_tot / N_points;      % 1 mV
    %     dV = max(dV, 0.00001);
    Structure.time_per_point = 1 / Structure.max_frequency;

    if Structure.startV < Structure.setV
        amps = Structure.startV:dV:Structure.setV;
    else
        amps = Structure.startV:-dV:Structure.setV;
    end

    ziDAQ('setInt', sprintf('/%s/auxouts/%01d/outputselect', address, output-1), -1); % set output to manual

    for i = 1:length(amps)
        ziDAQ('setDouble', sprintf('/%s/auxouts/0/offset', address), amps(i));
        pause(Structure.time_per_point)
    end

else
    errordlg('No suitable voltage source selected')
end