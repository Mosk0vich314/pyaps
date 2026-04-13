function sweep = Get_data_EB(Settings, sweep)

pause(0.1);
run = true;
while run
    run = Process_Status(sweep.process_number);
    pause(0.01);
end

%% get current data
array = 2:5;
for i = 1:Settings.N_ADC
    sweep.data{i}(:, sweep.index) = GetData_Double(array(Settings.ADC_idx(i)), 1, sweep.NumBias);
end






