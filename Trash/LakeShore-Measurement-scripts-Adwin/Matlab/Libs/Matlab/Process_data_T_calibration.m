function data = Process_data_T_calibration(Settings, Timetrace, Lockin, data, save_timetrace, MFLI_gains)

if ~isfield(Timetrace,'index3')
    Timetrace.index3 = 1;
end

if ~isfield(Timetrace,'index4')
    Timetrace.index4 = 1;
end

%% sort data short measurement
for i = 1:numel(Settings.contacts)
    for j = 1:numel(Lockin.dev1.channels)
        for k =  1:Timetrace.N_demods(i)
            demod = sprintf('demod%01d',k);

            if save_timetrace
                data.(Settings.contacts{i}).(demod).(Settings.signal{j}).data{Timetrace.index,Timetrace.index2,Timetrace.index3,Timetrace.index4} = Timetrace.data.(Lockin.(Lockin.device_names{i}).address).(demod).(Lockin.dev1.channels{j}) ...
                    / MFLI_gains{i}(k);
                if Timetrace.high_speed
                    data.(Settings.contacts{i}).(demod).(Settings.signal{j}).time{Timetrace.index,Timetrace.index2,Timetrace.index3,Timetrace.index4} = Timetrace.time.(Lockin.(Lockin.device_names{i}).address);
                else
                    data.(Settings.contacts{i}).(demod).(Settings.signal{j}).time{Timetrace.index,Timetrace.index2,Timetrace.index3,Timetrace.index4} = Timetrace.time.(Lockin.(Lockin.device_names{i}).address).(demod);
                end
            end

            tmp = Timetrace.data.(Lockin.(Lockin.device_names{i}).address).(demod).(Lockin.dev1.channels{j});
            tmp(isnan(tmp)) = [];

            data.(Settings.contacts{i}).(demod).(Settings.signal{j}).mean(Timetrace.index,Timetrace.index2,Timetrace.index3,Timetrace.index4) = mean(tmp) / MFLI_gains{i}(k);
            data.(Settings.contacts{i}).(demod).(Settings.signal{j}).std(Timetrace.index,Timetrace.index2,Timetrace.index3,Timetrace.index4) = std(tmp) / MFLI_gains{i}(k);

        end
    end
end