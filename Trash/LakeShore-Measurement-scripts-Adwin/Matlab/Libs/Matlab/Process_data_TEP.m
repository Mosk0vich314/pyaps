function Timetrace = Process_data_TEP(Settings, Timetrace, Lockin)

%% calculate mean and std data

switch lower(Settings.thermo)
    case 'current'

        % IV
        tmp = Timetrace.data.ADwin{1};
        tmp(isnan(tmp)) = [];
        Timetrace.mean.IV(Timetrace.index, Timetrace.index2) = mean(tmp);
        Timetrace.std.IV(Timetrace.index, Timetrace.index2) = std(tmp);

        % find demodulators
        demod_dev1 = sprintf('demod%01d', find(Lockin.dev1.harmonic == 2));
        demod_dev2 = sprintf('demod%01d', find(Lockin.dev2.harmonic == 1));
        demod_dev3 = sprintf('demod%01d', find(Lockin.dev3.harmonic == 1));

        % thermocurrent X
        thermocurrentX = Timetrace.data.(Lockin.(Lockin.device_names{1}).address).(demod_dev1).x / Lockin.dev1.IVgain;
        tmp = thermocurrentX;
        tmp(isnan(tmp)) = [];
        Timetrace.mean.thermocurrent.X(Timetrace.index, Timetrace.index2) = mean(tmp);
        Timetrace.std.thermocurrent.X(Timetrace.index, Timetrace.index2) = std(tmp);

        % thermocurrent Y
        thermocurrentY = Timetrace.data.(Lockin.(Lockin.device_names{1}).address).(demod_dev1).y / Lockin.dev1.IVgain;
        tmp = thermocurrentY;
        tmp(isnan(tmp)) = [];
        Timetrace.mean.thermocurrent.Y(Timetrace.index, Timetrace.index2) = mean(tmp);
        Timetrace.std.thermocurrent.Y(Timetrace.index, Timetrace.index2) = std(tmp);

        % thermocurrent R
        thermocurrentR = sqrt(thermocurrentX.^2 + thermocurrentY.^2);
        tmp = thermocurrentR;
        tmp(isnan(tmp)) = [];
        Timetrace.mean.thermocurrent.R(Timetrace.index, Timetrace.index2) = mean(tmp);
        Timetrace.std.thermocurrent.R(Timetrace.index, Timetrace.index2) = std(tmp);

        % dI/dV 2p X
        dI2p_X = Timetrace.data.(Lockin.(Lockin.device_names{2}).address).(demod_dev2).x / Lockin.dev1.IVgain;
        dIdV2p_X = dI2p_X / (1e-3*Lockin.dev2.amplitude_Vbias);
        tmp = dIdV2p_X;
        tmp(isnan(tmp)) = [];
        Timetrace.mean.dIdV2p.X(Timetrace.index, Timetrace.index2) = mean(tmp);
        Timetrace.std.dIdV2p.X(Timetrace.index, Timetrace.index2) = std(tmp);

        % dI/dV 2p Y
        dI2p_Y = Timetrace.data.(Lockin.(Lockin.device_names{2}).address).(demod_dev2).y / Lockin.dev1.IVgain;
        dIdV2p_Y = dI2p_Y / (1e-3*Lockin.dev2.amplitude_Vbias);
        tmp = dIdV2p_Y;
        tmp(isnan(tmp)) = [];
        Timetrace.mean.dIdV2p.Y(Timetrace.index, Timetrace.index2) = mean(tmp);
        Timetrace.std.dIdV2p.Y(Timetrace.index, Timetrace.index2) = std(tmp);

        % dI/dV 2p R
        dIdV2p_R = sqrt(dIdV2p_X.^2 + dIdV2p_Y.^2);
        dI2p_R = sqrt(dI2p_X.^2 + dI2p_Y.^2);
        tmp = dIdV2p_R;
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
            dV_X = Timetrace.data.(Lockin.(Lockin.device_names{3}).address).(demod_dev3).x / Lockin.dev3.Vgain;
            tmp = dV_X;
            tmp(isnan(tmp)) = [];
            Timetrace.mean.dV.X(Timetrace.index, Timetrace.index2) = mean(tmp);
            Timetrace.std.dV.X(Timetrace.index, Timetrace.index2) = std(tmp);

            % dV 4p Y
            dV_Y = Timetrace.data.(Lockin.(Lockin.device_names{3}).address).(demod_dev3).y / Lockin.dev3.Vgain;
            tmp = dV_Y;
            tmp(isnan(tmp)) = [];
            Timetrace.mean.dV.Y(Timetrace.index, Timetrace.index2) = mean(tmp);
            Timetrace.std.dV.Y(Timetrace.index, Timetrace.index2) = std(tmp);

            % dV 4p R
            dV_R = sqrt(dV_X.^2 + dV_Y.^2);
            tmp = dV_R;
            tmp(isnan(tmp)) = [];
            Timetrace.mean.dV.R(Timetrace.index, Timetrace.index2) = mean(tmp);
            Timetrace.std.dV.R(Timetrace.index, Timetrace.index2) = std(tmp);

            % dI/dV 4p X
            dIdV4p_X = dI2p_X ./ dV_X;
            tmp = dIdV4p_X;
            tmp(isnan(tmp)) = [];
            Timetrace.mean.dIdV4p.X(Timetrace.index, Timetrace.index2) = mean(tmp);
            Timetrace.std.dIdV4p.X(Timetrace.index, Timetrace.index2) = std(tmp);

            % dI/dV 4p Y
            dIdV4p_Y = dI2p_Y ./ dV_Y;
            tmp = dIdV4p_Y;
            tmp(isnan(tmp)) = [];
            Timetrace.mean.dIdV4p.Y(Timetrace.index, Timetrace.index2) = mean(tmp);
            Timetrace.std.dIdV4p.Y(Timetrace.index, Timetrace.index2) = std(tmp);

            % dI/dV 4p R
            dIdV4p_R = dI2p_R ./ dV_R;
            tmp = dIdV4p_R;
            tmp(isnan(tmp)) = [];
            Timetrace.mean.dIdV4p.R(Timetrace.index, Timetrace.index2) = mean(tmp);
            Timetrace.std.dIdV4p.R(Timetrace.index, Timetrace.index2) = std(tmp);
        end

        % thermovoltage 2p R
        tmp = thermocurrentR ./ dIdV2p_R;
        tmp(isnan(tmp)) = [];
        Timetrace.mean.thermovoltage2p.R(Timetrace.index, Timetrace.index2) = mean(tmp);
        Timetrace.std.thermovoltage2p.R(Timetrace.index, Timetrace.index2) = std(tmp);

        % thermovoltage 4p R
        if Settings.res4p == 1
            tmp = thermocurrentR ./ dIdV4p_R;
            tmp(isnan(tmp)) = [];
            Timetrace.mean.thermovoltage4p.R(Timetrace.index, Timetrace.index2) = mean(tmp);
            Timetrace.std.thermovoltage4p.R(Timetrace.index, Timetrace.index2) = std(tmp);
        end

    case 'voltage'

        % find demodulators
        demod_dev3 = sprintf('demod%01d', find(Lockin.dev3.harmonic == 2));

        % dV
        tmp = Timetrace.data.ADwin{2};
        tmp(isnan(tmp)) = [];
        Timetrace.mean.dV_thermo(Timetrace.index, Timetrace.index2) = mean(tmp);
        Timetrace.std.dV_thermo(Timetrace.index, Timetrace.index2) = std(tmp);

        % thermovoltage X
        tmp = Timetrace.data.(Lockin.(Lockin.device_names{3}).address).(demod_dev3).x / Lockin.dev3.Vgain;
        tmp(isnan(tmp)) = [];
        Timetrace.mean.thermovoltage.X(Timetrace.index, Timetrace.index2) = mean(tmp);
        Timetrace.std.thermovoltage.X(Timetrace.index, Timetrace.index2) = std(tmp);

        % thermovoltage Y
        tmp = Timetrace.data.(Lockin.(Lockin.device_names{3}).address).(demod_dev3).y / Lockin.dev3.Vgain;
        tmp(isnan(tmp)) = [];
        Timetrace.mean.thermovoltage.Y(Timetrace.index, Timetrace.index2) = mean(tmp);
        Timetrace.std.thermovoltage.Y(Timetrace.index, Timetrace.index2) = std(tmp);

        % thermovoltage R
        tmp = sqrt((Timetrace.data.(Lockin.(Lockin.device_names{3}).address).(demod_dev3).x / Lockin.dev3.Vgain).^2 ...
            + (Timetrace.data.(Lockin.(Lockin.device_names{3}).address).(demod_dev3).y / Lockin.dev3.Vgain).^2);
        tmp(isnan(tmp)) = [];
        Timetrace.mean.thermovoltage.R(Timetrace.index, Timetrace.index2) = mean(tmp);
        Timetrace.std.thermovoltage.R(Timetrace.index, Timetrace.index2) = std(tmp);
end

%% process raw data all harmonics
B = {'X','Y'};
for i = 1:Timetrace.N_devices
    dev = sprintf('dev%01d', i);
    for j = 1:Timetrace.N_demods(i)
        harm = sprintf('harm%01d', Timetrace.N_harmonics{i}(j));
        for k = 1:numel(B)

            tmp = Timetrace.data.(Lockin.(Lockin.device_names{i}).address).(sprintf('demod%01d',j)).(lower(B{k})) / Lockin.dev1.IVgain;
            tmp(isnan(tmp)) = [];

            Timetrace.mean.(dev).(harm).(B{k})(Timetrace.index, Timetrace.index2) = mean(tmp);
            Timetrace.std.(dev).(harm).(B{k})(Timetrace.index, Timetrace.index2) = std(tmp);
        end
    end
end