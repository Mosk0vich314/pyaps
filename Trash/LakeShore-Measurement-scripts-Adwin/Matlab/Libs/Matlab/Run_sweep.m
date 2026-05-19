function Structure = Run_sweep(Settings, Structure)

%% create bias vector
if ~isfield(Structure,'bias') && Structure.index == 1

    if Structure.minV < Structure.startV
        ramp_up = Structure.startV:Structure.dV:Structure.maxV;
        ramp_down = ramp_up(end):-Structure.dV:Structure.minV;
        ramp_up2 = ramp_down(end):Structure.dV:Structure.startV;

        Structure.bias = [ramp_up ramp_down ramp_up2]';
        Structure.NumBias = length(Structure.bias);

        if strcmp(Structure.sweep_dir, 'down')
            Structure.bias = -Structure.bias;
        end

    else
        ramp_up = Structure.minV:Structure.dV:Structure.maxV;
        ramp_down = ramp_up(end):-Structure.dV:Structure.minV;
        Structure.bias = [ramp_up ramp_down]';
        Structure.NumBias = length(Structure.bias);
    end

else
    Structure.NumBias = length(Structure.bias);
    Structure.minV = min(Structure.bias);
    Structure.maxV = max(Structure.bias);
end

[Structure.process_delay, Structure.loops_waiting] = get_delays(Structure.scanrate, Structure.settling_time, Settings.clockfrequency);  % get_delays
[~, Structure.loops_waiting_autoranging] = get_delays(Structure.scanrate, Structure.settling_time_autoranging, Settings.clockfrequency);  % get_delays

% set ADCs
Set_Par(10, Settings.input_resolution);

% set addresses
Set_Par(5,Settings.AI_address);
Set_Par(6,Settings.AO_address);
Set_Par(7,Settings.DIO_address);

% set output channel
Set_Par(8,Structure.output);

% set number of ADC pairs
Set_Par(20, Settings.N_ADC_pairs);

% set current amplifier settings
PARS = 27:34;
for i = 1:Settings.N_ADC
    if isnumeric(Settings.ADC{Settings.ADC_idx(i)})
        Set_FPar(PARS(Settings.ADC_idx(i)), log10(Settings.ADC{Settings.ADC_idx(i)}));
    end
end

% Inputs IV
Set_Par(21, Structure.points_av);
Set_Par(22, Structure.loops_waiting);  % loops waiting after each point
Set_Par(26, Structure.loops_waiting_autoranging);                        % loops waiting after each autoranging switch
if isfield(Structure,'maxI')
    Set_FPar(9, Structure.maxI);                    % set maximum voltage for bias reversal
end

% bias
[Structure.bias_bins, Structure.bias_new] = convert_V_to_bin(Structure.bias / Structure.V_per_V, Settings.output_min, Settings.output_max, Settings.output_resolution);
Structure.bias_new = Structure.bias_new * Structure.V_per_V;
Structure.bias_bins = Structure.bias_bins - 1;
SetData_Double(1, Structure.bias_bins, 1);

Set_Par(23, Structure.NumBias);
Set_Par(25, 0);             % reset sweep counter

% get timing
Structure.time_per_point = [(Structure.points_av / Structure.scanrate) + (Structure.settling_time / 1000); (Structure.points_av / Structure.scanrate) + (Structure.settling_time / 1000) +  diff(Structure.bias_bins) * Structure.process_delay / Settings.clockfrequency ] ; % 1/sampling rate
Structure.sampling_rate = 1 ./ Structure.time_per_point;

%% set ADC gains
SetData_Double(11, Settings.ADC_gain', 1);

%% create data structure for first IV
if ~isfield(Structure,'repeat2')
    Structure.repeat2 = 1;
end

if ~isfield(Structure,'current')
    for i = 1:Settings.N_ADC
        Structure.current{i} = zeros(Structure.NumBias, Structure.repeat, Structure.repeat2);
    end
end

%% run measurement
Set_Processdelay(1, Structure.process_delay);
Start_Process(1);

