function Timetrace = Define_arrays_stability_Ibias(Settings, Timetrace)

%% define empty arrays
Timetrace.mean.dV = zeros(Timetrace.repeat, Timetrace.repeat2);

A = {'mean','std'};
B = {'X','Y','R'};
for i = 1:numel(A)
    for j = 1:numel(B)
        Timetrace.(A{i}).conductance.(B{j}) = zeros(Timetrace.repeat, Timetrace.repeat2);
        Timetrace.(A{i}).resistance.(B{j}) = zeros(Timetrace.repeat, Timetrace.repeat2);
    end
end