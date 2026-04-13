    function Timetrace = Process_data_stability_Ibias(Settings, Timetrace, Lockin)
    
    %% calculate mean and std data
    % dV
    tmp = Timetrace.data.ADwin{1};
    tmp(isnan(tmp)) = [];
    Timetrace.mean.dV(Timetrace.index, Timetrace.index2) = mean(tmp);
    Timetrace.std.dV(Timetrace.index, Timetrace.index2) = std(tmp);
    
    % Resistance X
    tmp = Timetrace.data.(Lockin.(Lockin.device_names{1}).address).x / Lockin.dev1.V_gain / Lockin.dev1.amplitude_Ibias;
    tmp(isnan(tmp)) = [];
    Timetrace.mean.resistance.X(Timetrace.index, Timetrace.index2) = mean(tmp);
    Timetrace.std.resistance.X(Timetrace.index, Timetrace.index2) = std(tmp);
    
    % Resistance Y
    tmp = Timetrace.data.(Lockin.(Lockin.device_names{1}).address).y / Lockin.dev1.V_gain / Lockin.dev1.amplitude_Ibias;
    tmp(isnan(tmp)) = [];
    Timetrace.mean.resistance.Y(Timetrace.index, Timetrace.index2) = mean(tmp);
    Timetrace.std.resistance.Y(Timetrace.index, Timetrace.index2) = std(tmp);
    
    % Resistance R
    tmp = sqrt((Timetrace.data.(Lockin.(Lockin.device_names{1}).address).x).^2 ...
        + (Timetrace.data.(Lockin.(Lockin.device_names{1}).address).y).^2) / Lockin.dev1.V_gain / Lockin.dev1.amplitude_Ibias;
    tmp(isnan(tmp)) = [];
    Timetrace.mean.resistance.R(Timetrace.index, Timetrace.index2) = mean(tmp);
    Timetrace.std.resistance.R(Timetrace.index, Timetrace.index2) = std(tmp);
    
    
    % Conductance X
    tmp = Lockin.dev1.amplitude_Ibias ./ (Timetrace.data.(Lockin.(Lockin.device_names{1}).address).x / Lockin.dev1.V_gain);
    tmp(isnan(tmp)) = [];
    Timetrace.mean.conductance.X(Timetrace.index, Timetrace.index2) = mean(tmp);
    Timetrace.std.conductance.X(Timetrace.index, Timetrace.index2) = std(tmp);
    
    % Conductance Y
    tmp = Lockin.dev1.amplitude_Ibias ./ (Timetrace.data.(Lockin.(Lockin.device_names{1}).address).y / Lockin.dev1.V_gain);
    tmp(isnan(tmp)) = [];
    Timetrace.mean.conductance.Y(Timetrace.index, Timetrace.index2) = mean(tmp);
    Timetrace.std.conductance.Y(Timetrace.index, Timetrace.index2) = std(tmp);
    
    % Conductance R
    tmp = sqrt((Lockin.dev1.amplitude_Ibias ./ (Timetrace.data.(Lockin.(Lockin.device_names{1}).address).x / Lockin.dev1.V_gain)).^2 ...
        + (Lockin.dev1.amplitude_Ibias ./ (Timetrace.data.(Lockin.(Lockin.device_names{1}).address).y / Lockin.dev1.V_gain)).^2);
    tmp(isnan(tmp)) = [];
    Timetrace.mean.conductance.R(Timetrace.index, Timetrace.index2) = mean(tmp);
    Timetrace.std.conductance.R(Timetrace.index, Timetrace.index2) = std(tmp);