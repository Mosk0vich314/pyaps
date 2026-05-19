function Timetrace = Acquire_data_timetrace_MFLI(Settings, Timetrace, Lockin)

Done = 0;
Attempts = 1;

while Done == 0
    try

        % start timetrace MFLI
        Timetrace = Run_timetrace_poll(Timetrace, Lockin);
        Timetrace.data;

        Done = 1;

    catch ME
        fprintf('%s - Connection error, restarting server, try %01d ... ', datetime('now'), Attempts);
        fprintf('%s - %s ... \n', ME.message);

        % clear connection and reconnect
        clear ziDAQ
        ziDAQ('connect', 'localhost', 8004, 6);

        % Init DAQ
        Timetrace = Init_lockin_ZI_DAQ(Timetrace, Lockin);

        % Init MDS
        [Timetrace.mds, Timetrace.devices_string] = Init_sync_ZI_lockins(Timetrace.device_list);

        % increment attempt
        Attempts = Attempts + 1;

        if Attempts > 5
            break
        end
    end
end