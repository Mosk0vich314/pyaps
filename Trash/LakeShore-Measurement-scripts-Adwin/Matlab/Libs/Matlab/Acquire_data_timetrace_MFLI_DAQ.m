function Timetrace = Acquire_data_timetrace_MFLI_DAQ(Settings, Timetrace, Lockin)

Done = 0;
Attempts = 1;
Attempts_server = 1;

while Done == 0
    try

        %% start timetrace MFLI
        Timetrace = Run_timetrace(Settings, Timetrace);

        %% get data
        Timetrace = Get_data_timetrace(Settings, Timetrace);

        Done = 1;

    catch ME
        fprintf('%s - Data error, try %01d ... \n', datetime('now'), Attempts);

        %% increment attempt
        Attempts = Attempts + 1;

        if Attempts == 10

            fprintf('%s - Connection error, restarting server, try %01d ... ', datetime('now'), Attempts_server);
            fprintf('%s - %s ... \n', ME.message);

            %% clear connection and reconnect
            clear ziDAQ
            ziDAQ('connect', 'localhost', 8004, 6);

            %% Init DAQ
            Timetrace = Init_lockin_ZI_DAQ(Timetrace, Lockin);

            %% Init MDS
            [Timetrace.mds, Timetrace.devices_string] = Init_sync_ZI_lockins(Timetrace.device_list);

            Attempts_server = Attempts_server + 1;
            Attempts = 1;

            if Attempts_server == 5
                break
            end

        end
    end
end