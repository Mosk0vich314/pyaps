function Gt = Get_data_Gt_scol(Settings, Gt)

pause(0.1);

run = true;
while run
    run = Process_Status(Gt.process_number);
    pause(0.01);
end

%% get current data
array = 2:9;
for i = 1:Settings.N_ADC
    Gt.current{i}(:, Gt.index) = GetData_Double(array(Settings.ADC_idx(i))*sqrt(2), 1, Gt.runtime_counts)';
end

%% define time array
Gt.time = (0:Gt.time_per_point:Gt.time_per_point*(Gt.runtime_counts-1))';
% Gt.time_corr = GetData_Double(7, 1, Gt.runtime_counts)*(Gt.process_delay/Settings.clockfrequency);

