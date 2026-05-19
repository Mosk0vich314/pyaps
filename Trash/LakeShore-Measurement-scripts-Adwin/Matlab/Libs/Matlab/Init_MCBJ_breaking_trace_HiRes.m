function [Settings, Histo] = Init_MCBJ_breaking_trace_HiRes(Settings, Histo, Bias)

%% upload calibration curve
[~,name,~] = fileparts(Settings.log_calibration_file);
data = load(sprintf('Calibration_curves/%s.mat',name),'Voltages','Calibration','bin_array');

Settings.calibration.current = data.Calibration;
Settings.calibration.voltage = data.Voltages;
Settings.calibration.bins = data.bin_array;

SetData_Double(1, Settings.calibration.current, 1);

%% Acquisition %%
% set averaging
Set_Par(54, Histo.points_av);                % set points to average
Histo.time_per_point = ( Histo.points_av / Histo.scanrate); % 1/sampling rate

% set ADCs
Set_Par(10, Settings.input_resolution);

% set addresses
Set_Par(5, Settings.AI_address);
Set_Par(6, Settings.AO_address);
Set_Par(7, Settings.DIO_address);

%% Voltage output
% set output channel
Set_Par(50, Histo.output);

% set starting voltage, PAR_61 is average voltage
if Histo.reset_drive_voltage == 1
    Set_Par(61, convert_V_to_bin(Histo.start_V, Settings.output_max, Settings.output_min, Settings.output_resolution));
else
    if Get_Par(61) == 0
        Set_Par(61, convert_V_to_bin(Histo.start_V, Settings.output_max, Settings.output_min, Settings.output_resolution));
    end
end

% bin size
bin_size = (Settings.output_max-Settings.output_min) / 2 ^ Settings.output_resolution;

% generate HiRes signal array
Histo.HiRes_Array = zeros(Histo.SignalLength, 1);
Histo.HiRes_Array(:) = Get_Par(61);

Histo.SignalWidth_bins = round(Histo.SignalWidth/1000 / bin_size);
VpairCount = floor(Histo.SignalLength/2);
randomIntegersSignalWidth = randi([-Histo.SignalWidth_bins Histo.SignalWidth_bins], 1, VpairCount);

for i = 1:VpairCount
        Histo.HiRes_Array((i-1)*2 + 1) = Histo.HiRes_Array((i-1)*2 + 1) + randomIntegersSignalWidth(i);
        Histo.HiRes_Array((i-1)*2 + 2) = Histo.HiRes_Array((i-1)*2 + 2) - randomIntegersSignalWidth(i);
end

Set_Data(6, Histo.HiRes_Array, 1);
Set_Par(64, Histo.SignalLength)

%% set ramping speed
red_bin_size = bin_size / Histo.SignalLength;

wait_cycles_breaking1 = round(Histo.scanrate * Histo.V_per_V / (Histo.breaking_speed1 / red_bin_size)) ;  % get wait loop
wait_cycles_breaking2 = round(Histo.scanrate * Histo.V_per_V / (Histo.breaking_speed2 / red_bin_size)) ;  % get wait loop 
wait_cycles_making = round(Histo.scanrate * Histo.V_per_V / (Histo.making_speed / red_bin_size)) ;  % get wait loop

Set_Par(55, wait_cycles_breaking1);                 % set points to average
Set_Par(56, wait_cycles_breaking2);                 % set points to average
Set_Par(57, wait_cycles_making);              % set points to average

%% set current thresholds
high_I = Histo.high_G * Settings.G0 * Bias.targetV;
inter_I = Histo.inter_G * Settings.G0 * Bias.targetV;
low_I = Histo.low_G * Settings.G0 * Bias.targetV;

Set_FPar(50, high_I);                  % set high I
Set_FPar(51, inter_I);                  % set intermediate I
Set_FPar(52, low_I);                  % set low I

% set postbreaking counter
Set_Par(58, round(Histo.scanrate / Histo.points_av * Histo.post_breaking_voltage / Histo.breaking_speed2)); 
  
%% set process delay
process_delay = round(Settings.clockfrequency / Histo.scanrate);
Set_Processdelay(7, process_delay);

return