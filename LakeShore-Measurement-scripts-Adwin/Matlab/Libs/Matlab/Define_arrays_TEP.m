function Timetrace = Define_arrays_TEP(Settings, Timetrace)

%% define empty arrays
switch lower(Settings.thermo)
    case 'current'

        Timetrace.mean.IV = zeros(Timetrace.repeat, Timetrace.repeat2);
        if Settings.res4p == 1
            Timetrace.mean.dV_DC = zeros(Timetrace.repeat, Timetrace.repeat2);
        end

        Timetrace.mean.thermovoltage2p.R = zeros(Timetrace.repeat, Timetrace.repeat2);
        Timetrace.std.thermovoltage2p.R = zeros(Timetrace.repeat, Timetrace.repeat2);
        if Settings.res4p == 1
            Timetrace.mean.thermovoltage4p.R = zeros(Timetrace.repeat, Timetrace.repeat2);
            Timetrace.std.thermovoltage4p.R = zeros(Timetrace.repeat, Timetrace.repeat2);
        end

        A = {'mean','std'};
        B = {'X','Y','R'};
        for i = 1:numel(A)
            for j = 1:numel(B)
                Timetrace.(A{i}).dIdV2p.(B{j}) = zeros(Timetrace.repeat, Timetrace.repeat2);
                Timetrace.(A{i}).thermocurrent.(B{j}) = zeros(Timetrace.repeat, Timetrace.repeat2);
                if Settings.res4p == 1
                    Timetrace.(A{i}).dIdV4p.(B{j}) = zeros(Timetrace.repeat, Timetrace.repeat2);
                    Timetrace.(A{i}).dV.(B{j}) = zeros(Timetrace.repeat, Timetrace.repeat2);
                end
            end
        end

        %% define empty array all demods
        B = {'X','Y'};
        for i = 1:Timetrace.N_devices
            dev = sprintf('dev%01d', i);
            for j = 1:Timetrace.N_demods(i)
                harm = sprintf('harm%01d', Timetrace.N_harmonics{i}(j));
                for k = 1:numel(B)
                    for l = 1:numel(A)
                        Timetrace.(A{l}).(dev).(harm).(B{k}) = zeros(Timetrace.repeat, Timetrace.repeat2);
                    end
                end
            end
        end

    case 'voltage'

        Timetrace.mean.dV_thermo = zeros(Timetrace.repeat, Timetrace.repeat2);

        A = {'mean','std'};
        B = {'X','Y','R'};
        for i = 1:numel(A)
            for j = 1:numel(B)
                Timetrace.(A{i}).thermovoltage.(B{j}) = zeros(Timetrace.repeat, Timetrace.repeat2);
            end
        end

        %% define empty array all demods
        B = {'X','Y'};
        for i = 1:Timetrace.N_devices
            dev = sprintf('dev%01d', i);
            for j = 1:Timetrace.N_demods(i)
                harm = sprintf('harm%01d', Timetrace.N_harmonics{i}(j));
                for k = 1:numel(B)
                    for l = 1:numel(A)
                        Timetrace.(A{l}).(dev).(harm).(B{k}) = zeros(Timetrace.repeat, Timetrace.repeat2);
                    end
                end
            end
        end

end