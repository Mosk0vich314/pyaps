% this script is to loop through the resistance of the resistor switch and make and IV for each of them to determine their value. 
% make sure that the swtichbox is properly connected and that autoranging
% is enabled on the FEMTO (including cable).

%% clear
clear
close all hidden
clc

%% Settings
Settings.save_dir = 'E:\Samples\Mickael\Switchbox_calibration';
Settings.sample = 'SwitchBox1'; %A2-GatetoGate G0b
Settings.ADC = {1e9, 'off', 'off','off', 'off', 'off', 'off', 'off'};
Settings.auto = 'FEMTO'; % FEMTO
Settings.ADC_gain = [0 0 0 0 0 0 0 0]; % 2^N
Settings.get_sample_T = ''; % {'', 'Lakeshore336', 'Lakeshore325', 'Oxford_ITC'}
Settings.type = 'IV';
Settings.ADwin = 'GoldII'; % GoldII or ProII
Settings.res4p = 0;     % 4 point measurement

IV.V_per_V = 1;          % V/V0
IV.startV = 0;            % V
IV.maxV = 0.2;
IV.minV = -IV.maxV;        % V
IV.points = 301;           % what happens for >   4000 points?? IV.minV = -IV.maxV;         % V
IV.dV = IV.maxV / IV.points *2;    % V
IV.sweep_dir = 'up';
IV.maxI = 0;            % A

IV.scanrate = 450000;       % Hz
IV.points_av = 1* IV.scanrate / 50;        % points
IV.settling_time = 0;      % ms
IV.settling_time_autoranging = 200;      % ms

IV.output = 1;              % AO channel
IV.process_number = 1;

Switchbox.address = 'COM4';
Switchbox.N_resistors = 42;

%% Initialize
Settings = Init(Settings);

%% Initialize ADwin
[Settings, IV] = get_sweep_process(Settings, IV);
Settings = Init_ADwin(Settings, IV);

%% Initialize switchbox
Switchbox.device = IVVI_USB_switch_box(Switchbox.address);
Switchbox.resistance_values = zeros(Switchbox.N_resistors, 1);

%% run measurement
IV.repeat = Switchbox.N_resistors;

for i = 1:IV.repeat

    %% change switchbox
    Switchbox.device.set_resistance_pos(i-1);

    %% run IV

    fprintf('%s - Running I(V) - %1.0f/%1.0f...', datetime('now'), i, IV.repeat)
    IV.index = i;
    IV = Run_sweep(Settings, IV);

    %% get current and show plot
    IV = Realtime_sweep(Settings, IV, Settings.type);

    fprintf('done\n')

    %% get resistance value
    [a, b] = min(IV.bias_new);
    idx1 = find(IV.bias_new == a);
    [c, d] = max(IV.bias_new);
    idx2 = find(IV.bias_new == c);
    idx = sort([idx1;idx2]);

    coeffs = polyfit(IV.bias_new(idx(2):idx(3)), IV.current{1}(idx(2):idx(3),i), 1);
    Switchbox.resistance_values(i) = abs(1 / coeffs(1));

    fprintf('%s - Resistance - %1.6e Ohm\n', datetime('now'), Switchbox.resistance_values(i))

end

%% save figure
filename = sprintf('%s/%s_%s_%s', Settings.save_dir, Settings.filename, Settings.sample, Settings.type);

%% save data
Save_data(Settings, IV, Switchbox, [filename '.mat']);

writematrix(Switchbox.resistance_values, filename)

% close all
load train, sound(y,Fs)