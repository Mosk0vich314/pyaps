function data = Process_data_T_calibration_Temperature(Timetrace, data)

data.T.data = Timetrace.T;
data.T.time = Timetrace.T_time;

data.T.mean = mean(Timetrace.T);
data.T.std = std(Timetrace.T);