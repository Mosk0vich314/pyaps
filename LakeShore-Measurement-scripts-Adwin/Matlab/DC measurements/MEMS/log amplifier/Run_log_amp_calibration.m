%% clear
clear
close all hidden
clc

%% Settings
Settings.save_dir = 'E:\Samples\Mickael\log_amp_calibration';

Settings.sample = 'Calibration_1.25V'; %A2-GatetoGate G0b
Settings.ADC = {1, 'off', 'off','off', 'off', 'off', 'off', 'off'};
Settings.auto = ''; % FEMTO
Settings.ADC_gain = [3 0 0 0 0 0 0 0]; % 2^N; use 3 to have maximum input range of 1.25V !
Settings.get_sample_T = ''; % {'', 'Lakeshore336', 'Lakeshore325', 'Oxford_ITC'}
Settings.type = 'IV';
Settings.ADwin = 'GoldII'; % GoldII or ProII
Settings.res4p = 0;     % 4 point measurement

IV.V_per_V = 1;          % V/V0
IV.startV = 0;            % V
IV.maxV = 10;
IV.minV = -IV.maxV;        % V
IV.points = 5001;           % what happens for >   4000 points?? IV.minV = -IV.maxV;         % V
IV.dV = IV.maxV / IV.points *2;    % V
IV.sweep_dir = 'up';
IV.maxI = 0;            % A

IV.scanrate = 450000;       % Hz
IV.points_av = 5 * IV.scanrate / 50;        % points
IV.settling_time = 0;      % ms
IV.settling_time_autoranging = 200;      % ms

IV.output = 1;              % AO channel
IV.process_number = 1;

Switchbox.address = 'COM4';

%% Initialize
Settings = Init(Settings);

%% Initialize ADwin
[Settings, IV] = get_sweep_process(Settings, IV);
Settings = Init_ADwin(Settings, IV);

%% Init switchbox
Switchbox.device = IVVI_USB_switch_box(Switchbox.address);
Switchbox.resistance_values = Switchbox.device.get_resistance_Ohm_list();
IV.repeat = numel(Switchbox.resistance_values);

%% run measurement
for i = 1:IV.repeat

    %% set resistor box
    Switchbox.device.set_resistance_Ohm(Switchbox.resistance_values(i));

    fprintf('%s - Resistor box set to %1.2e Ohm...', datetime('now'), Switchbox.resistance_values(i))
    pause(0.2)
    fprintf('done\n')

    %% run IV
    fprintf('%s - Running I(V) - %1.0f/%1.0f...', datetime('now'), i, IV.repeat)
    IV.index = i;
    IV = Run_sweep(Settings, IV);

    %% get current and show plot
    IV = Realtime_sweep(Settings, IV, Settings.type);
    fprintf('done\n')

end

%% save figure
fig = findobj('Name', Settings.type);
filename = sprintf('%s/%s_%s_%s_%1.0fK', Settings.save_dir, Settings.filename, Settings.sample, Settings.type);
saveas(fig, [filename '.png'])
saveas(fig, [filename '.fig'])

%% save data
Save_data(Settings, IV, Switchbox, [filename '.mat']);
