function Timetrace = Define_arrays_stability(Settings, Timetrace)

%% define empty arrays
Timetrace.mean.IV = zeros(Timetrace.repeat, Timetrace.repeat2);
if Settings.res4p == 1
    Timetrace.mean.dV_DC = zeros(Timetrace.repeat, Timetrace.repeat2);
end
A = {'mean','std'};
B = {'X','Y','R'};
for i = 1:numel(A)
    for j = 1:numel(B)
        Timetrace.(A{i}).dIdV2p.(B{j}) = zeros(Timetrace.repeat, Timetrace.repeat2);
        if Settings.res4p == 1
            Timetrace.(A{i}).dIdV4p.(B{j}) = zeros(Timetrace.repeat, Timetrace.repeat2);
            Timetrace.(A{i}).dV.(B{j}) = zeros(Timetrace.repeat, Timetrace.repeat2);
        end
        if Settings.second_der == 1
            Timetrace.(A{i}).dI2d2V2p.(B{j}) = zeros(Timetrace.repeat, Timetrace.repeat2);
        end
    end
end