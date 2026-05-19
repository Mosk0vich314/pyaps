function Timetrace = Process_data_TEP_heat_engine(Settings, Timetrace, Lockin)

%% calculate mean and std data
% find demodulators
demod_dev1 = sprintf('demod%01d', find(Lockin.dev1.harmonic == 2));

% thermocurrent X
tmp = Timetrace.data.(Lockin.(Lockin.device_names{1}).address).(demod_dev1).x / Lockin.dev1.IVgain;
tmp(isnan(tmp)) = [];
Timetrace.mean.thermocurrent.X(Timetrace.index, Timetrace.index2) = mean(tmp);
Timetrace.std.thermocurrent.X(Timetrace.index, Timetrace.index2) = std(tmp);

% thermocurrent Y
tmp = Timetrace.data.(Lockin.(Lockin.device_names{1}).address).(demod_dev1).y / Lockin.dev1.IVgain;
tmp(isnan(tmp)) = [];
Timetrace.mean.thermocurrent.Y(Timetrace.index, Timetrace.index2) = mean(tmp);
Timetrace.std.thermocurrent.Y(Timetrace.index, Timetrace.index2) = std(tmp);

% thermocurrent R
tmp = sqrt((Timetrace.data.(Lockin.(Lockin.device_names{1}).address).(demod_dev1).x / Lockin.dev1.IVgain).^2 ...
    + (Timetrace.data.(Lockin.(Lockin.device_names{1}).address).(demod_dev1).y / Lockin.dev1.IVgain).^2);
tmp(isnan(tmp)) = [];
Timetrace.mean.thermocurrent.R(Timetrace.index, Timetrace.index2) = mean(tmp);
Timetrace.std.thermocurrent.R(Timetrace.index, Timetrace.index2) = std(tmp);

%% process raw data all harmonics
B = {'X','Y'};
for i = 1:Timetrace.N_devices
    dev = sprintf('dev%01d', i);
    for j = 1:Timetrace.N_demods(i)
        harm = sprintf('harm%01d', Timetrace.N_harmonics{i}(j));
        for k = 1:numel(B)

            tmp = Timetrace.data.(Lockin.(Lockin.device_names{i}).address).(sprintf('demod%01d',j)).x / Lockin.dev1.IVgain;
            tmp(isnan(tmp)) = [];

            Timetrace.mean.(dev).(harm).(B{k})(Timetrace.index, Timetrace.index2) = mean(tmp);
            Timetrace.std.(dev).(harm).(B{k})(Timetrace.index, Timetrace.index2) = std(tmp);
        end
    end
end