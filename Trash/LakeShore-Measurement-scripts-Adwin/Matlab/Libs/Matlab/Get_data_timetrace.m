function Timetrace = Get_data_timetrace(Settings, Timetrace)

%% check data acquisition
tic;
if strcmpi(Timetrace.model, 'ZI_MFLI')

    switch Timetrace.high_speed
        case 0

            %% run loop
            counter = 1;
            while ~ziDAQ('finished', Timetrace.daq)
                pause(0.001);

                if Timetrace.get_T > 0
                    for i = 1:Timetrace.get_T
                        Timetrace.T(counter, i) = Settings.T_controller.get_temp(i);
                    end
                    Timetrace.T_time(counter, 1) = toc;
                    counter = counter + 1;
                end
            end

            %% get final current
            result = ziDAQ('read', Timetrace.daq);

            %% get device names
            names = fieldnames(result);
            func =  @(x) regexp(x, 'dev\d+');
            tmp = cellfun(func, names,'UniformOutput', false);

            Channel_names =  fieldnames(result.(Timetrace.device_list{1}).demods);
            func = @(x)  strsplit(x, '_'); 
            Channel_names_short = cellfun(func, Channel_names,'UniformOutput', false);
            func = @(x)  x{2}; 
            Channel_names_short = cellfun(func, Channel_names_short,'UniformOutput', false);

            %% sort data
            for i = 1:Timetrace.N_devices
                    for k =  1:Timetrace.N_demods(i)
                        for j = 1:Timetrace.N_channels
                            Timetrace.data.(Timetrace.device_list{i}).(sprintf('demod%01d',k)).(Channel_names_short{j}) = result.(Timetrace.device_list{i}).demods(k).(Channel_names{j}){1}.value';
                        end
                    end
                    
                    for k =  1:Timetrace.N_demods(i)
                        demod = sprintf('demod%01d',k);
                        Timetrace.time.(Timetrace.device_list{i}).(demod) = double(result.(Timetrace.device_list{i}).demods(k).(Channel_names{1}){1}.timestamp)' / Timetrace.clockbase ;
                        Timetrace.time.(Timetrace.device_list{i}).(demod) = Timetrace.time.(Timetrace.device_list{i}).(demod) - Timetrace.time.(Timetrace.device_list{i}).(demod)(1);

                        %% cut to proper time
                        % find time
                        time = Timetrace.time.(Timetrace.device_list{i}).(demod);
                        start_time = max([0 time(end)-Timetrace.runtime]);

                        start_idx = find(min(abs(time - start_time)) == abs((time - start_time)));
                        time = time(start_idx:end);

                        % shift time to zero
                        time = time - time(1);

                        % cut data to timetrace length
                        for j = 1:Timetrace.N_channels
                            Timetrace.data.(Timetrace.device_list{i}).(demod).(Channel_names_short{j}) = Timetrace.data.(Timetrace.device_list{i}).(demod).(Channel_names_short{j})(start_idx:end);
                        end

                        Timetrace.time.(Timetrace.device_list{i}).(demod) = time;
                    end

            end

        case 1

    end

elseif strcmpi(Timetrace.model, 'SRS830') || strcmpi(Timetrace.model, 'EGG7265') || strcmpi(Timetrace.model, 'ADwin')

    pause(0.001);
    run = true;
    counter = 1;
    while run && Get_Par(25) >= 0
        run = Process_Status(Timetrace.process_number);
        pause(0.001);

        if Timetrace.get_T > 0
            for i = 1:Timetrace.get_T
                Timetrace.T(counter, i) = Settings.T_controller.get_temp(i);
            end
            Timetrace.T_time(counter, 1) = toc;
            counter = counter + 1;
        end
    end

    %% get final current
    array = 2:9;
    for i = 1:Settings.N_ADC
        Timetrace.data.ADwin{i} = GetData_Double(array(Settings.ADC_idx(i)), 1, Timetrace.runtime_counts)';
    end
end