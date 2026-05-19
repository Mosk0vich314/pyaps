function Timetrace = Process_data_stability(Settings, Timetrace, Lockin)

%% calculate mean and std data
% IV
tmp = Timetrace.data.ADwin{1};
tmp(isnan(tmp)) = [];
Timetrace.mean.IV(Timetrace.index, Timetrace.index2) = mean(tmp);
Timetrace.std.IV(Timetrace.index, Timetrace.index2) = std(tmp);

% dI/dV 2p X
tmp = Timetrace.data.(Lockin.(Lockin.device_names{1}).address).x / Lockin.dev1.IVgain / (1e-3*Lockin.dev1.amplitude_Vbias);
tmp(isnan(tmp)) = [];
Timetrace.mean.dIdV2p.X(Timetrace.index, Timetrace.index2) = mean(tmp);
Timetrace.std.dIdV2p.X(Timetrace.index, Timetrace.index2) = std(tmp);

% dI/dV 2p Y
tmp = Timetrace.data.(Lockin.(Lockin.device_names{1}).address).y / Lockin.dev1.IVgain / (1e-3*Lockin.dev1.amplitude_Vbias);
tmp(isnan(tmp)) = [];
Timetrace.mean.dIdV2p.Y(Timetrace.index, Timetrace.index2) = mean(tmp);
Timetrace.std.dIdV2p.Y(Timetrace.index, Timetrace.index2) = std(tmp);

% dI/dV 2p R
tmp = sqrt((Timetrace.data.(Lockin.(Lockin.device_names{1}).address).x / Lockin.dev1.IVgain / (1e-3*Lockin.dev1.amplitude_Vbias)).^2 ...
    + (Timetrace.data.(Lockin.(Lockin.device_names{1}).address).y / Lockin.dev1.IVgain / (1e-3*Lockin.dev1.amplitude_Vbias)).^2);
tmp(isnan(tmp)) = [];
Timetrace.mean.dIdV2p.R(Timetrace.index, Timetrace.index2) = mean(tmp);
Timetrace.std.dIdV2p.R(Timetrace.index, Timetrace.index2) = std(tmp);

% dI/dV 4p
if Settings.res4p == 1

    % dV DC
    tmp = Timetrace.data.ADwin{2};
    tmp(isnan(tmp)) = [];
    Timetrace.mean.dV_DC(Timetrace.index, Timetrace.index2) = mean(tmp);
    Timetrace.std.dV_DC(Timetrace.index, Timetrace.index2) = std(tmp);

    % dV 4p X
    tmp = Timetrace.data.(Lockin.(Lockin.device_names{2}).address).x / Lockin.dev2.Vgain;
    tmp(isnan(tmp)) = [];
    Timetrace.mean.dV.X(Timetrace.index, Timetrace.index2) = mean(tmp);
    Timetrace.std.dV.X(Timetrace.index, Timetrace.index2) = std(tmp);

    % dV 4p Y
    tmp = Timetrace.data.(Lockin.(Lockin.device_names{2}).address).y / Lockin.dev2.Vgain;
    tmp(isnan(tmp)) = [];
    Timetrace.mean.dV.Y(Timetrace.index, Timetrace.index2) = mean(tmp);
    Timetrace.std.dV.Y(Timetrace.index, Timetrace.index2) = std(tmp);

    % dV 4p R
    tmp = sqrt((Timetrace.data.(Lockin.(Lockin.device_names{2}).address).x / Lockin.dev2.Vgain).^2 ...
        + (Timetrace.data.(Lockin.(Lockin.device_names{2}).address).y / Lockin.dev2.Vgain).^2);
    tmp(isnan(tmp)) = [];
    Timetrace.mean.dV.R(Timetrace.index, Timetrace.index2) = mean(tmp);
    Timetrace.std.dV.R(Timetrace.index, Timetrace.index2) = std(tmp);

    % dI/dV 4p X
    tmp = Timetrace.data.(Lockin.(Lockin.device_names{1}).address).x / Lockin.dev1.IVgain ./ (Timetrace.data.(Lockin.(Lockin.device_names{2}).address).x / Lockin.dev2.Vgain);
    tmp(isnan(tmp)) = [];
    Timetrace.mean.dIdV4p.X(Timetrace.index, Timetrace.index2) = mean(tmp);
    Timetrace.std.dIdV4p.X(Timetrace.index, Timetrace.index2) = std(tmp);

    % dI/dV 4p Y
    tmp = Timetrace.data.(Lockin.(Lockin.device_names{1}).address).y / Lockin.dev1.IVgain ./ (Timetrace.data.(Lockin.(Lockin.device_names{2}).address).y / Lockin.dev2.Vgain);
    tmp(isnan(tmp)) = [];
    Timetrace.mean.dIdV4p.Y(Timetrace.index, Timetrace.index2) = mean(tmp);
    Timetrace.std.dIdV4p.Y(Timetrace.index, Timetrace.index2) = std(tmp);

    % dI/dV 4p R
    tmp = sqrt(Timetrace.data.(Lockin.(Lockin.device_names{1}).address).x .^2 + Timetrace.data.(Lockin.(Lockin.device_names{1}).address).y .^2) / Lockin.dev1.IVgain  ...
        ./ sqrt(Timetrace.data.(Lockin.(Lockin.device_names{2}).address).y .^2 + Timetrace.data.(Lockin.(Lockin.device_names{2}).address).y .^2) / Lockin.dev2.Vgain;
    tmp(isnan(tmp)) = [];
    Timetrace.mean.dIdV4p.R(Timetrace.index, Timetrace.index2) = mean(tmp);
    Timetrace.std.dIdV4p.R(Timetrace.index, Timetrace.index2) = std(tmp);
end

% second derivative
if Settings.second_der == 1

    % dI2dV2 X
    tmp = Timetrace.data.(Lockin.(Lockin.device_names{2}).address).x;
    tmp(isnan(tmp)) = [];
    Timetrace.mean.dI2d2V2p.X(Timetrace.index, Timetrace.index2) = mean(tmp) / Lockin.dev1.IVgain / (1e-3*Lockin.dev1.amplitude_Vbias) / (1e-3*Lockin.dev1.amplitude_Vbias);
    Timetrace.std.dI2d2V2p.X(Timetrace.index, Timetrace.index2) = std(tmp) / Lockin.dev1.IVgain / (1e-3*Lockin.dev1.amplitude_Vbias) / (1e-3*Lockin.dev1.amplitude_Vbias);

    % dI2dV2 Y
    tmp = Timetrace.data.(Lockin.(Lockin.device_names{2}).address).y;
    tmp(isnan(tmp)) = [];
    Timetrace.mean.dI2d2V2p.Y(Timetrace.index, Timetrace.index2) = mean(tmp) / Lockin.dev1.IVgain / (1e-3*Lockin.dev1.amplitude_Vbias) / (1e-3*Lockin.dev1.amplitude_Vbias);
    Timetrace.std.dI2d2V2p.Y(Timetrace.index, Timetrace.index2) = std(tmp) / Lockin.dev1.IVgain /(1e-3*Lockin.dev1.amplitude_Vbias) / (1e-3*Lockin.dev1.amplitude_Vbias);

    % dI2dV2 R
    tmp = sqrt((Timetrace.data.(Lockin.(Lockin.device_names{2}).address).x ).^2 ...
        + (Timetrace.data.(Lockin.(Lockin.device_names{2}).address).y ).^2);
    tmp(isnan(tmp)) = [];
    Timetrace.mean.dI2d2V2p.R(Timetrace.index, Timetrace.index2) = mean(tmp) / Lockin.dev1.IVgain / (1e-3*Lockin.dev1.amplitude_Vbias) / (1e-3*Lockin.dev1.amplitude_Vbias);
    Timetrace.std.dI2d2V2p.R(Timetrace.index, Timetrace.index2) = std(tmp) / Lockin.dev1.IVgain / (1e-3*Lockin.dev1.amplitude_Vbias) / (1e-3*Lockin.dev1.amplitude_Vbias);

end