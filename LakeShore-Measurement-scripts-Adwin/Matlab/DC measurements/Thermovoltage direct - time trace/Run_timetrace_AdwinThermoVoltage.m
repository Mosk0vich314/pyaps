function Timetrace = Run_timetrace_AdwinThermoVoltage(Settings, Timetrace, eSwitch)

%% check if acquisition method
if strcmpi(Timetrace.model, 'ZI_MFLI')

    switch Timetrace.high_speed
        case 0
            %% data points
            Timetrace.runtime_counts = floor(Timetrace.datarate * Timetrace.runtime);

            %% set timetrace settings
            ziDAQ('set', Timetrace.daq, 'grid/cols', Timetrace.runtime_counts);
            ziDAQ('set', Timetrace.daq, 'duration', Timetrace.runtime);

            %% run measurement
            ziDAQ('execute', Timetrace.daq);
            ziDAQ('set', Timetrace.daq, 'forcetrigger', 1);

        case 1

            %% settings
            clockbase = 60e6;
            poll_timeout = 0.01;

            %% run measurement
            done = 0;
            Attempts = 1;
            while done == 0

                %% run poll, with a minimum added time of 5ms and a maximum of 50ms.
                data = ziDAQ('poll', Timetrace.runtime + min([0.05 max([0.005 Timetrace.runtime*0.05])]) , poll_timeout);

                %% get device names
                Device_names = fieldnames(data);
                Channel_names = {'x','y'};

                %% sort data
                L = zeros(Timetrace.N_devices, 1);
                for i = 1:Timetrace.N_devices

                    dev = lower(Timetrace.device_list{i});

                    %% find large interuptions in time by looking for big jumps in diff(timestamps)
                    [B, I] = sort(double(diff(data.(dev).demods.sample.timestamp)));
                    B = fliplr(B);
                    I = fliplr(I);
                    if B(1) > 10*B(2)
                        start_idx = I(1) + 1;
                    else
                        start_idx = 1;
                    end

                    %% find end time
                    time = data.(dev).demods.sample.timestamp(1:end);
                    time(start_idx:end) = time(start_idx:end) - B(1) + B(end);

                    %% find time
                    time = (double(time) - double(time(1))) / clockbase;
                    start_time = max([0 time(end)-Timetrace.runtime]);

                    start_idx = find(min(abs(time - start_time)) == abs((time - start_time)));
                    time = time(start_idx:end);

                    %% shift time to zero
                    time = time - time(1);

                    %% cut data to timetrace length
                    for j = 1:Timetrace.N_channels
                        Data.(Device_names{i}).(Channel_names{j}) = data.(dev).demods.sample.(Channel_names{j})(start_idx:end);
                    end

                    Timetrace.time.(dev) = time';
                    Timetrace.data.(dev) = Data.(dev);

                    L(i) = numel(Timetrace.time.(dev));

                end

                %% check is time trace length is same for each device
                if numel(unique(L)) == 1
                    done = 1;
                else
                    fprintf('%s - Polling error, restarting timetrace, try %01d ... \n', datetime('now'), Attempts);
                end

                Attempts = Attempts + 1;
            end

    end

elseif strcmpi(Timetrace.model, 'SR830') || strcmpi(Timetrace.model, 'EGG7265') || strcmpi(Timetrace.model, 'ADwin')

    %% set parameters
    [Timetrace.process_delay, Timetrace.loops_waiting] = get_delays(Timetrace.scanrate, Timetrace.settling_time, Settings.clockfrequency);  % get_delays
    [~, Timetrace.loops_waiting_autoranging] = get_delays(Timetrace.scanrate, Timetrace.settling_time_autoranging, Settings.clockfrequency);  % get_delays
    Timetrace.time_per_point = (Timetrace.points_av / Timetrace.scanrate) + (Timetrace.settling_time / 1000); % 1/sampling rate
    Timetrace.sampling_rate = 1 / Timetrace.time_per_point;
    Timetrace.runtime_counts = ceil(Timetrace.sampling_rate * Timetrace.runtime);

    % create time vector
    Timetrace.time.ADwin = (0:Timetrace.time_per_point:(Timetrace.runtime_counts-1)*Timetrace.time_per_point)';

    % set ADCs
    Set_Par(10, Settings.input_resolution);

    % set addresses
    Set_Par(5,Settings.AI_address);
    Set_Par(6,Settings.AO_address);
    Set_Par(7,Settings.DIO_address);

    % set number of ADC pairs
    Set_Par(20, Settings.N_ADC_pairs);

    % set amplifier settings
    PARS = 27:34;
    for i = 1:Settings.N_ADC
        if isnumeric(Settings.ADC{i})
            Set_FPar(PARS(i), log10(Settings.ADC{i}));
        end
    end

    % Inputs timetrace
    Set_Par(14, Timetrace.runtime_counts);
    Set_Par(21, Timetrace.points_av);
    Set_Par(22, Timetrace.loops_waiting);  % loops waiting after each point
    Set_Par(26, Timetrace.loops_waiting_autoranging);                        % loops waiting after each autoranging switch

    %% set ADC gains
    SetData_Double(11, Settings.ADC_gain, 1);

    %% run measurement
    Set_Processdelay(2, Timetrace.process_delay);
    Start_Process(2);

    pause(5);

    eSwitch.startV = 0;          % V
    eSwitch.setV = 5;            % V
    eSwitch = Apply_fixed_voltage(Settings, eSwitch);



else
    errordlg('No suitable device selected')
end