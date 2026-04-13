function data = Process_data_T_calibration_ADwin(Settings, Timetrace, data, save_timetrace, ADwin_gains)

if ~isfield(Timetrace,'index3')
    Timetrace.index3 = 1;
end

if ~isfield(Timetrace,'index4')
    Timetrace.index4 = 1;
end

%% sort data ADwin
for ii = 1:numel(Settings.contacts)
    for kk =  1:Timetrace.N_demods(ii)
        demod = sprintf('demod%01d',kk);
        tmp = Timetrace.data.ADwin{ii};

        if save_timetrace
            data.(Settings.contacts{ii}).(demod).DC.data{Timetrace.index,Timetrace.index2,Timetrace.index3,Timetrace.index4} = Timetrace.data.ADwin{ii};
            data.(Settings.contacts{ii}).(demod).DC.time{Timetrace.index,Timetrace.index2,Timetrace.index3,Timetrace.index4} = Timetrace.time.ADwin;
        end
        
        data.(Settings.contacts{ii}).(demod).DC.mean(Timetrace.index,Timetrace.index2,Timetrace.index3,Timetrace.index4) = mean(tmp) / ADwin_gains(ii);
        data.(Settings.contacts{ii}).(demod).DC.std(Timetrace.index,Timetrace.index2,Timetrace.index3,Timetrace.index4) = std(tmp) / ADwin_gains(ii);
    end
end
