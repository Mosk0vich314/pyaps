function Timetrace = Process_data_TEP_Ibias(Settings, Timetrace, Lockin)

  % find demodulators
  demod_dev1 = sprintf('demod%01d', find(Lockin.dev1.harmonic == 2));
  demod_dev2 = sprintf('demod%01d', find(Lockin.dev2.harmonic == 1));

%% calculate mean and std data
% dV
tmp = Timetrace.data.ADwin{1};
tmp(isnan(tmp)) = [];
Timetrace.mean.dV(Timetrace.index, Timetrace.index2) = mean(tmp);
Timetrace.std.dV(Timetrace.index, Timetrace.index2) = std(tmp);

% Resistance X
tmp = Timetrace.data.(Lockin.(Lockin.device_names{2}).address).(demod_dev2).x / Lockin.dev2.V_gain / Lockin.dev2.amplitude_Ibias;
tmp(isnan(tmp)) = [];
Timetrace.mean.resistance.X(Timetrace.index, Timetrace.index2) = mean(tmp);
Timetrace.std.resistance.X(Timetrace.index, Timetrace.index2) = std(tmp);

% Resistance Y
tmp = Timetrace.data.(Lockin.(Lockin.device_names{2}).address).(demod_dev2).y / Lockin.dev2.V_gain / Lockin.dev2.amplitude_Ibias;
tmp(isnan(tmp)) = [];
Timetrace.mean.resistance.Y(Timetrace.index, Timetrace.index2) = mean(tmp);
Timetrace.std.resistance.Y(Timetrace.index, Timetrace.index2) = std(tmp);

% Resistance R
tmp = sqrt((Timetrace.data.(Lockin.(Lockin.device_names{2}).address).(demod_dev2).x).^2 ...
    + (Timetrace.data.(Lockin.(Lockin.device_names{2}).address).(demod_dev2).y).^2) / Lockin.dev2.V_gain / Lockin.dev2.amplitude_Ibias;
tmp(isnan(tmp)) = [];
Timetrace.mean.resistance.R(Timetrace.index, Timetrace.index2) = mean(tmp);
Timetrace.std.resistance.R(Timetrace.index, Timetrace.index2) = std(tmp);


% Conductance X
tmp = Lockin.dev2.amplitude_Ibias ./ (Timetrace.data.(Lockin.(Lockin.device_names{2}).address).(demod_dev2).x / Lockin.dev2.V_gain);
tmp(isnan(tmp)) = [];
Timetrace.mean.conductance.X(Timetrace.index, Timetrace.index2) = mean(tmp);
Timetrace.std.conductance.X(Timetrace.index, Timetrace.index2) = std(tmp);

% Conductance Y
tmp = Lockin.dev2.amplitude_Ibias ./ (Timetrace.data.(Lockin.(Lockin.device_names{2}).address).(demod_dev2).y / Lockin.dev2.V_gain);
tmp(isnan(tmp)) = [];
Timetrace.mean.conductance.Y(Timetrace.index, Timetrace.index2) = mean(tmp);
Timetrace.std.conductance.Y(Timetrace.index, Timetrace.index2) = std(tmp);

% Conductance R
tmp = sqrt((Lockin.dev2.amplitude_Ibias ./ (Timetrace.data.(Lockin.(Lockin.device_names{2}).address).(demod_dev2).x / Lockin.dev2.V_gain)).^2 ...
    + (Lockin.dev2.amplitude_Ibias ./ (Timetrace.data.(Lockin.(Lockin.device_names{2}).address).(demod_dev2).y / Lockin.dev2.V_gain)).^2);
tmp(isnan(tmp)) = [];
Timetrace.mean.conductance.R(Timetrace.index, Timetrace.index2) = mean(tmp);
Timetrace.std.conductance.R(Timetrace.index, Timetrace.index2) = std(tmp);

% Thermovoltage X
tmp = Timetrace.data.(Lockin.(Lockin.device_names{1}).address).(demod_dev1).x / Lockin.dev1.V_gain;
tmp(isnan(tmp)) = [];
Timetrace.mean.thermovoltage.X(Timetrace.index, Timetrace.index2) = mean(tmp);
Timetrace.std.thermovoltage.X(Timetrace.index, Timetrace.index2) = std(tmp);

% Thermovoltage Y
tmp = Timetrace.data.(Lockin.(Lockin.device_names{1}).address).(demod_dev1).y / Lockin.dev1.V_gain;
tmp(isnan(tmp)) = [];
Timetrace.mean.thermovoltage.Y(Timetrace.index, Timetrace.index2) = mean(tmp);
Timetrace.std.thermovoltage.Y(Timetrace.index, Timetrace.index2) = std(tmp);

% Thermovoltage R
tmp = sqrt((Timetrace.data.(Lockin.(Lockin.device_names{1}).address).(demod_dev1).x / Lockin.dev1.V_gain).^2 ...
    + (Timetrace.data.(Lockin.(Lockin.device_names{1}).address).(demod_dev1).y / Lockin.dev1.V_gain).^2);
tmp(isnan(tmp)) = [];
Timetrace.mean.thermovoltage.R(Timetrace.index, Timetrace.index2) = mean(tmp);
Timetrace.std.thermovoltage.R(Timetrace.index, Timetrace.index2) = std(tmp);

%% process raw data all harmonics
B = {'X','Y'};
for i = 1:Timetrace.N_devices
    dev = sprintf('dev%01d', i);
    for j = 1:Timetrace.N_demods(i)
        harm = sprintf('harm%01d', Timetrace.N_harmonics{i}(j));
        for k = 1:numel(B)

            tmp = Timetrace.data.(Lockin.(Lockin.device_names{i}).address).(sprintf('demod%01d',j)).x / Lockin.dev1.V_gain;
            tmp(isnan(tmp)) = [];

            Timetrace.mean.(dev).(harm).(B{k})(Timetrace.index, Timetrace.index2) = mean(tmp);
            Timetrace.std.(dev).(harm).(B{k})(Timetrace.index, Timetrace.index2) = std(tmp);
        end
    end
end