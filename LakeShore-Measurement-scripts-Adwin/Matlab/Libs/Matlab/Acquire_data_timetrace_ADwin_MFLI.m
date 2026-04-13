function Timetrace = Acquire_data_timetrace_ADwin_MFLI(Settings, Timetrace, Lockin)

Done = 0;
Attempts = 1;

while Done == 0
    try
        %% Start timetrace ADwin
        Start_Process(2);

        %% start timetrace MFLI
        Timetrace = Run_timetrace_poll(Timetrace, Lockin);
        Timetrace.data;

        %% get data ADwin
        Stop_Process(2);
        time_idx = Get_Par(19);
        runtime_counts = ceil(Timetrace.sampling_rate * Timetrace.runtime);

        array = 2:4;
        for l = 1:Settings.N_ADC
            Timetrace.data.ADwin{l} = GetData_Double(array(Settings.ADC_idx(l)), 1, time_idx)';
            Timetrace.data.ADwin{l} = Timetrace.data.ADwin{l}(end-runtime_counts+ 1: runtime_counts);
            if Timetrace.lowpass % low pass filter if needed
                Timetrace.data.ADwin{l} = lowpass(Timetrace.data.ADwin{l},0.01,Timetrace.sampling_rate,ImpulseResponse="fir",Steepness=0.9);
            end
        end
        Done = 1;

    catch ME
        fprintf('%s - Connection error, restarting server, try %01d ... ', datetime('now'), Attempts);
        fprintf('%s - %s ... \n', ME.message);

        %% clear connection and reconnect
        clear ziDAQ
        ziDAQ('connect', 'localhost', 8004, 6);

        %% Init DAQ
        Timetrace = Init_lockin_ZI_DAQ(Timetrace, Lockin);
        
        %% Init MDS
        [Timetrace.mds, Timetrace.devices_string] = Init_sync_ZI_lockins(Timetrace.device_list);

        %% increment attempt
        Attempts = Attempts + 1;

        if Attempts > 5
            break
        end
    end
end