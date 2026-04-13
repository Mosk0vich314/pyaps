function [data, Settings] = Define_arrays_T_calibration(Settings, Timetrace, dim)

%% define empty arrays 
Settings.contacts = {'H','T1','T2'};
Settings.signal = {'X','Y','DC'};
for i = 1:numel(Settings.contacts)
    for j = 1:numel(Settings.signal)
        for k =  1:Timetrace.N_demods(i)
            demod = sprintf('demod%01d',k);

            data.(Settings.contacts{i}).(demod).(Settings.signal{j}).data = cell(dim);
            data.(Settings.contacts{i}).(demod).(Settings.signal{j}).time = cell(dim);
            data.(Settings.contacts{i}).(demod).(Settings.signal{j}).mean = zeros(dim);
            data.(Settings.contacts{i}).(demod).(Settings.signal{j}).std = zeros(dim);
        end
    end
end
