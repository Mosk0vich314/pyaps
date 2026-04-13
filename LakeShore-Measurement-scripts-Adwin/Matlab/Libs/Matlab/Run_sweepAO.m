function Structure = Run_sweepAO(Settings, Structure)

%% create bias vector
Structure.NumBias = length(Structure.bias);
Structure.minV = min(Structure.bias);
Structure.maxV = max(Structure.bias);

% set addresses
Set_Par(5,Settings.AI_address);
Set_Par(6,Settings.AO_address);
Set_Par(7,Settings.DIO_address);

% set output channel
Set_Par(8, Structure.output);

% bias
[Structure.bias_bins, Structure.bias_new] = convert_V_to_bin(Structure.bias / Structure.V_per_V, Settings.output_min, Settings.output_max, Settings.output_resolution);
Structure.bias_new = Structure.bias_new * Structure.V_per_V;
Structure.bias_bins = Structure.bias_bins - 1;
SetData_Double(1, Structure.bias_bins, 1);

% get process delay
[Structure.process_delay, ~] = get_delays(Structure.scanrate, 0, Settings.clockfrequency);  % get_delays

% set vector length
Set_Par(23, Structure.NumBias);

%% run measurement
Set_Processdelay(6, Structure.process_delay);
Start_Process(6);

