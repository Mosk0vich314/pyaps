function [Settings, Histo] = Init_MCBJ_breaking_trace(Settings, Histo, Bias)

process_delay = round(Settings.clockfrequency / Histo.scanrate);

bin_size = (Settings.output_max-Settings.output_min)/2^Settings.output_resolution;

wait_cycles_breaking1 = round(Histo.scanrate * Histo.V_per_V / (Histo.breaking_speed1 / bin_size)) ;  % get wait loop
wait_cycles_breaking2 = round(Histo.scanrate * Histo.V_per_V / (Histo.breaking_speed2 / bin_size)) ;  % get wait loop 
wait_cycles_making = round(Histo.scanrate * Histo.V_per_V / (Histo.making_speed / bin_size)) ;  % get wait loop

Histo.time_per_point = ( Histo.points_av / Histo.scanrate); % 1/sampling rate

Settings.N_ADC_pairs = 1;
Settings.N_ADC = 2;
Settings.ADC_idx = [1 2];

%% INITIALIZE %%

% set preamplifier gains
SetData_Double(11, Settings.ADC_gain', 1);

% set ADCs
Set_Par(10, Settings.input_resolution);

% set addresses
Set_Par(5, Settings.AI_address);
Set_Par(6, Settings.AO_address);
Set_Par(7, Settings.DIO_address);

% set output channel
Set_Par(50, Histo.output);

% set current amplifier settings
PARS = 27:34;
for i = 1:Settings.N_ADC
    if isnumeric(Settings.ADC{Settings.ADC_idx(i)})
        Set_FPar(PARS(Settings.ADC_idx(i)), log10(Settings.ADC{Settings.ADC_idx(i)}));
    end
end

% set starting voltage
if Histo.reset_drive_voltage == 1
    Set_Par(61, convert_V_to_bin(Histo.start_V, Settings.output_max, Settings.output_min, Settings.output_resolution));
else
    if Get_Par(61) == 0
        Set_Par(61, convert_V_to_bin(Histo.start_V, Settings.output_max, Settings.output_min, Settings.output_resolution));
    end
end

%
Set_Par(54, Histo.points_av);                % set points to average

% set current thresholds
high_I = Histo.high_G * Settings.G0 * Bias.targetV;
inter_I = Histo.inter_G * Settings.G0 * Bias.targetV;
low_I = Histo.low_G * Settings.G0 * Bias.targetV;

Set_FPar(50, high_I);                  % set high I
Set_FPar(51, inter_I);                  % set intermediate I
Set_FPar(52, low_I);                  % set low I

% set piezo speed
Set_Par(55, wait_cycles_breaking1);                 % set points to average
Set_Par(56, wait_cycles_breaking2);                 % set points to average
Set_Par(57, wait_cycles_making);              % set points to average

% set postbreaking counter
Set_Par(58, round(Histo.scanrate / Histo.points_av * Histo.post_breaking_voltage / Histo.breaking_speed2)); 
  
% set process delay
Set_Processdelay(7, process_delay);

return