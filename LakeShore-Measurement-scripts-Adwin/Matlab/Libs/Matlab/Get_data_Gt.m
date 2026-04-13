function Gt = Get_data_Gt(Settings, Gt)

% pause(0.1);

run = true;
while run
    run = Process_Status(Gt.process_number);
%     if Settings.Temp_over_time == 1
%             
%             %             for k = 1:4
%             Lakeshore = Temperature_controller('GPIB0::8::INSTR');
%             try Gt.temperature{1}(Gt.temperature_counter, Gt.index) = Lakeshore.get_temp(1);
%             end
%             try Gt.temperature{2}(Gt.temperature_counter, Gt.index) = Lakeshore.get_temp(2);
%             end
%             try Gt.temperature{3}(Gt.temperature_counter, Gt.index) = Lakeshore.get_temp(3);
%             end
%             
%             try Gt.temperature{4}(Gt.temperature_counter, Gt.index) = Lakeshore.get_temp(4);
%             end
%             %             end
%             Gt.temperature_counter = Gt.temperature_counter + 1;
%         end
%     pause(0.01);
end

%% get voltage data
array = 2:9;
for i = 1:Settings.N_ADC
    Gt.voltage{i}(:, Gt.index) = GetData_Double(array(Settings.ADC_idx(i)), 1, Gt.runtime_counts)';
end

%% define time array
Gt.time = (0:Gt.time_per_point:Gt.time_per_point*(Gt.runtime_counts-1))';
% Gt.time_corr = GetData_Double(7, 1, Gt.runtime_counts)*(Gt.process_delay/Settings.clockfrequency);

