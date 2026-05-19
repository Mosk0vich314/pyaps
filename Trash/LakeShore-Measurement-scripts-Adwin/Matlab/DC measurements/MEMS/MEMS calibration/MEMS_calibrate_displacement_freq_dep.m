%% clear
clear
close all hidden
clc
tic

%% Settings
Settings.save_dir = 'N:\Quantum-Devices\ARSCryo\Samples\lepe\MEMS_CNT\U4.1\Right movement\Freq_dep';
Settings.sample = 'C3 global gate - sides gates ground_BPI_02_full_BW_1e6'; %A2-GatetoGate G0b Test_100MOhm_50ohm_termination
Settings.get_sample_T = 'Lakeshore325'; % {'', 'Lakeshore336', 'Lakeshore325', 'Oxford_ITC'}
Settings.type = 'MEMS';
Settings.ADwin = 'GoldII'; % GoldII or ProII

Settings.Temperatures = 300;

% Lockin 1 --> apply on actuator and measure capacitance
Lockin.dev1.sensitivity = 10;           % sensitivity (V). Use 10 for MFLI with no sensitivity set
Lockin.dev1.frequency_array = 10.^linspace(1,5,11);
Lockin.dev1.harmonic = [1 2 3 4];           %
Lockin.dev1.demod_oscillator = 1;           %
Lockin.dev1.timeconstant = 0.2;           % seconds
Lockin.dev1.amplitude = 10; % mV
Lockin.dev1.ramp_rate = 10;            % heater amplitude ramp rate mV/s
Lockin.dev1.V_per_V = 5/100;
Lockin.dev1.model = 'ZI_MFLI';
Lockin.dev1.input_diff = 'A';
Lockin.dev1.input_range = 3;
Lockin.dev1.filter_order = 4;
Lockin.dev1.channels = {'x','y'};
Lockin.dev1.autoranging = 1;
Lockin.dev1.datarate = 3e3; % do not exceed 30e3!
Lockin.dev1.input_AC = 0;
Lockin.dev1.accuracy = 90;
Lockin.dev1.IVgain = 1e6;
Lockin.dev1.frequency_array

% Lockin 2 --> apply on opposite actuator
Lockin.dev2 = Lockin.dev1;
Lockin.dev2.harmonic = [1 2 3 4];           %
Lockin.dev2.frequency_array = Lockin.dev2.frequency_array + 10;
Lockin.dev2.V_per_V = 1;

Timetrace.wait_time = Get_lockin_waiting_period(Lockin.dev1.filter_order, Lockin.dev1.accuracy) * Lockin.dev1.timeconstant;      % s

% ZI MFLI
Timetrace.N_channels = numel(Lockin.dev1.channels);
Timetrace.channels = Lockin.dev1.channels;
Timetrace.clockbase = 60e6;
Timetrace.clim = [];
Timetrace.model = Lockin.dev1.model;
Timetrace.datarate = Lockin.dev1.datarate;
Timetrace.lowpass = 0;              % optional low pass filter (0.01Hz) for ADWin signal
Timetrace.high_speed = 1;
Timetrace.runtime = 1;

Drive.initV = 0;
Drive.maxV = 8;            % V
Drive.endV = 0;
Drive.points = 101;
Drive.ramp_rate = 0.5;       % V/s
Drive.waiting_time = 0;     % s after setting Gate.setV
Drive.V_per_V = 5;          % V/V0
Drive.fixed_voltage = 'ADwin';
Drive.output = 1;            % AO channel
Drive.process_number = 3;
Drive.process = 'Fixed_AO';
Drive.sweep_dir = 'up';

Lockin.dev1.address = 'DEV6056'; % drive voltage and capacitance measurement
Lockin.dev2.address = 'DEV6565'; % capacitance measurement on opposite comb

%% Initialize
Settings = Init(Settings);

%% Initialize ADwin
Settings = Init_ADwin(Settings, Drive);

%% Initialize Lockin
clear ziDAQ
ziDAQ('connect', 'localhost', 8004, 6);

Timetrace.N_devices = 2;
Lockin.dev1.frequency = Lockin.dev1.frequency_array(1);
Lockin.dev2.frequency = Lockin.dev2.frequency_array(1);

Lockin.device_names = fieldnames(Lockin);
for i = 1:Timetrace.N_devices
    Lockin.(Lockin.device_names{i}) = Init_lockin(Lockin.(Lockin.device_names{i}));
end

%% initialize DAQ
Timetrace = Init_lockin_ZI_DAQ(Timetrace, Lockin);

%% convert drive voltage lockin voltage
Lockin.dev1.amplitude_rescaled = Lockin.dev1.amplitude * 1e-3 / Lockin.dev1.V_per_V;
Lockin.dev1.ramp_rate_rescaled = Lockin.dev1.ramp_rate * 1e-3 / Lockin.dev1.V_per_V;

Lockin.dev2.amplitude_rescaled = Lockin.dev2.amplitude * 1e-3 / Lockin.dev2.V_per_V;
Lockin.dev2.ramp_rate_rescaled = Lockin.dev2.ramp_rate * 1e-3 / Lockin.dev2.V_per_V;

%% define drive voltage vector
Drive.startV = Drive.initV;          % V
Drive.voltage = linspace(Drive.initV, Drive.maxV, Drive.points);
Drive.minV = Drive.initV;
Drive = Generate_voltage_array(Settings, Drive);

%% set lockin amplitude drive voltage
fprintf('Ramping up AC drive voltage 1 ...')
ramp_lockin(Lockin.dev1, 0, Lockin.dev1.amplitude_rescaled, Lockin.dev1.ramp_rate_rescaled);
fprintf('done\n')

fprintf('Ramping up AC drive voltage 2 ...')
ramp_lockin(Lockin.dev2, 0, Lockin.dev2.amplitude_rescaled, Lockin.dev2.ramp_rate_rescaled);
fprintf('done\n')

%% Initialize arrays
N_freq = numel(Lockin.dev1.frequency_array);
N_drive = numel(Drive.voltage);

Timetrace.data_all_1.X.mean = zeros(N_freq, N_drive);
Timetrace.data_all_1.X.std = zeros(N_freq, N_drive);
Timetrace.data_all_1.Y.mean = zeros(N_freq, N_drive);
Timetrace.data_all_1.Y.std = zeros(N_freq, N_drive);
Timetrace.data_all_1.R.mean = zeros(N_freq, N_drive);
Timetrace.data_all_1.R.std = zeros(N_freq, N_drive);
Timetrace.data_all_1.Theta.mean = zeros(N_freq, N_drive);
Timetrace.data_all_1.Theta.std = zeros(N_freq, N_drive);

Timetrace.data_all_2.X.mean = zeros(N_freq, N_drive);
Timetrace.data_all_2.X.std = zeros(N_freq, N_drive);
Timetrace.data_all_2.Y.mean = zeros(N_freq, N_drive);
Timetrace.data_all_2.Y.std = zeros(N_freq, N_drive);
Timetrace.data_all_2.R.mean = zeros(N_freq, N_drive);
Timetrace.data_all_2.R.std = zeros(N_freq, N_drive);
Timetrace.data_all_2.Theta.mean = zeros(N_freq, N_drive);
Timetrace.data_all_2.Theta.std = zeros(N_freq, N_drive);

%% Init figure 1
fig1 = figure('Name','MEMS calibration - frequency dep','Units','normalized');
fig1.Position = Settings.plot_position;
set(gcf,'color','white')

subplot('position',[0.13 0.58 0.31 0.35]); hold on;
set(gca,'Box','on','LineWidth',2,'FontSize',16)
ax1 = gca;
xlabel('Drive voltage (V)');
ylabel('X - component');

set(gcf,'color','white')
subplot('position',[0.5 0.58 0.31 0.35]); hold on;
set(gca,'Box','on','LineWidth',2,'FontSize',16)
ax2 = gca;
xlabel('Drive voltage (V)');
ylabel('Y - component');

subplot('position',[0.13 0.11 0.31 0.35]); hold on;
set(gca,'Box','on','LineWidth',2,'FontSize',16)
ax3 = gca;
xlabel('Drive voltage (V)');
ylabel('R - component');

set(gcf,'color','white')
subplot('position',[0.5 0.11 0.31 0.35]); hold on;
set(gca,'Box','on','LineWidth',2,'FontSize',16)
ax4 = gca;
xlabel('Drive voltage (V)');
ylabel('\Theta');

colors = inferno(N_freq);

if N_freq > 1
    cbar = colorbar(ax4,'Position',...
        [0.83 0.11 0.012 0.82]);

    colormap(colors);
    clim(log10([min(Lockin.dev1.frequency_array) max(Lockin.dev1.frequency_array)]))
    cbar.Ticks = linspace(log10(min(Lockin.dev1.frequency_array)), log10(max(Lockin.dev1.frequency_array)), 5);
end

%% Init figure 2
fig2 = figure('Name','MEMS calibration - frequency dep','Units','normalized');
fig2.Position = Settings.plot_position;
set(gcf,'color','white')

subplot('position',[0.13 0.58 0.31 0.35]); hold on;
set(gca,'Box','on','LineWidth',2,'FontSize',16)
ax5 = gca;
xlabel('Drive voltage (V)');
ylabel('X - component');

set(gcf,'color','white')
subplot('position',[0.5 0.58 0.31 0.35]); hold on;
set(gca,'Box','on','LineWidth',2,'FontSize',16)
ax6 = gca;
xlabel('Drive voltage (V)');
ylabel('Y - component');

subplot('position',[0.13 0.11 0.31 0.35]); hold on;
set(gca,'Box','on','LineWidth',2,'FontSize',16)
ax7 = gca;
xlabel('Drive voltage (V)');
ylabel('R - component');

set(gcf,'color','white')
subplot('position',[0.5 0.11 0.31 0.35]); hold on;
set(gca,'Box','on','LineWidth',2,'FontSize',16)
ax8 = gca;
xlabel('Drive voltage (V)');
ylabel('\Theta');

colors = inferno(N_freq);

if N_freq > 1
     cbar = colorbar(ax8,'Position',...
        [0.83 0.11 0.012 0.82]);

    colormap(colors);
    clim(log10([min(Lockin.dev1.frequency_array) max(Lockin.dev1.frequency_array)]))
    cbar.Ticks = linspace(log10(min(Lockin.dev1.frequency_array)), log10(max(Lockin.dev1.frequency_array)), 5);
end

%% freq dependence
for index = 1:N_freq

    %% create animated lines
    if Settings.Temperatures(1) > Settings.Temperatures(end)
        animated_line_X_1  = animatedline('LineWidth',1.5,'Parent',ax1,'color',colors(end-index+1,:));
        animated_line_Y_1  = animatedline('LineWidth',1.5,'Parent',ax2,'color',colors(end-index+1,:));
        animated_line_R_1  = animatedline('LineWidth',1.5,'Parent',ax3,'color',colors(end-index+1,:));
        animated_line_Theta_1  = animatedline('LineWidth',1.5,'Parent',ax4,'color',colors(end-index+1,:));

        animated_line_X_2  = animatedline('LineWidth',1.5,'Parent',ax5,'color',colors(end-index+1,:));
        animated_line_Y_2  = animatedline('LineWidth',1.5,'Parent',ax6,'color',colors(end-index+1,:));
        animated_line_R_2  = animatedline('LineWidth',1.5,'Parent',ax7,'color',colors(end-index+1,:));
        animated_line_Theta_2  = animatedline('LineWidth',1.5,'Parent',ax8,'color',colors(end-index+1,:));
    else
        animated_line_X_1  = animatedline('LineWidth',1.5,'Parent',ax1,'color',colors(index,:));
        animated_line_Y_1  = animatedline('LineWidth',1.5,'Parent',ax2,'color',colors(index,:));
        animated_line_R_1  = animatedline('LineWidth',1.5,'Parent',ax3,'color',colors(index,:));
        animated_line_Theta_1  = animatedline('LineWidth',1.5,'Parent',ax4,'color',colors(index,:));

        animated_line_X_2  = animatedline('LineWidth',1.5,'Parent',ax5,'color',colors(index,:));
        animated_line_Y_2  = animatedline('LineWidth',1.5,'Parent',ax6,'color',colors(index,:));
        animated_line_R_2  = animatedline('LineWidth',1.5,'Parent',ax7,'color',colors(index,:));
        animated_line_Theta_2  = animatedline('LineWidth',1.5,'Parent',ax8,'color',colors(index,:));
    end

    %% set frequency
    fprintf('%s - Setting frequency 1 = %1.2f Hz...', datetime('now'), Lockin.dev1.frequency_array(index) )
    Lockin.dev1.dev.set_frequency(Lockin.dev1.frequency_array(index));
    fprintf('done\n')

    fprintf('%s - Setting frequency 2 = %1.2f Hz...', datetime('now'), Lockin.dev2.frequency_array(index) )
    Lockin.dev2.dev.set_frequency(Lockin.dev2.frequency_array(index));
    fprintf('done\n')

    %% reset start voltage
    Drive.startV = Drive.initV;          % V

    %% Init voltages
    for index2 = 1:N_drive

        %% set drive voltage
        fprintf('%s - Setting Vdrive = %1.2f...', datetime('now'), Drive.voltage(index2) )

        Drive.setV = Drive.voltage(index2);
        Drive = Apply_fixed_voltage(Settings, Drive);
        fprintf('done\n')

        %% autorange input
        if Lockin.dev1.autoranging
            MFLI_autorange(Lockin, Timetrace.N_devices);
        end

        %% wait for lockin
        pause(Timetrace.wait_time);

        %% run Timetrace
        fprintf('%s - Running Timetrace : %01d /%01d...', datetime('now'), index2, N_drive)
        Timetrace = Acquire_data_timetrace_MFLI(Settings, Timetrace, Lockin);
        fprintf('done \n');

        %% process data
        Timetrace.data_all_1.X.mean(index, index2) = mean(Timetrace.data.(Lockin.dev1.address).demod1.x);
        Timetrace.data_all_1.Y.mean(index, index2) = mean(Timetrace.data.(Lockin.dev1.address).demod1.y);
        Timetrace.data_all_1.R.mean(index, index2) = mean(sqrt(Timetrace.data.(Lockin.dev1.address).demod1.x .^2 + Timetrace.data.(Lockin.dev1.address).demod1.y .^2));
        Timetrace.data_all_1.Theta.mean(index, index2) = rad2deg(mean(atan2(Timetrace.data.(Lockin.dev1.address).demod1.y,Timetrace.data.(Lockin.dev1.address).demod1.x)));

        Timetrace.data_all_1.X.std(index, index2) = std(Timetrace.data.(Lockin.dev1.address).demod1.x);
        Timetrace.data_all_1.Y.std(index, index2) = std(Timetrace.data.(Lockin.dev1.address).demod1.y);
        Timetrace.data_all_1.R.std(index, index2) = std(sqrt(Timetrace.data.(Lockin.dev1.address).demod1.x .^2 + Timetrace.data.(Lockin.dev1.address).demod1.y .^2));
        Timetrace.data_all_1.Theta.std(index, index2) = rad2deg(std(atan2(Timetrace.data.(Lockin.dev1.address).demod1.y,Timetrace.data.(Lockin.dev1.address).demod1.x)));

        Timetrace.data_all_2.X.mean(index, index2) = mean(Timetrace.data.(Lockin.dev2.address).demod1.x);
        Timetrace.data_all_2.Y.mean(index, index2) = mean(Timetrace.data.(Lockin.dev2.address).demod1.y);
        Timetrace.data_all_2.R.mean(index, index2) = mean(sqrt(Timetrace.data.(Lockin.dev2.address).demod1.x .^2 + Timetrace.data.(Lockin.dev2.address).demod1.y .^2));
        Timetrace.data_all_2.Theta.mean(index, index2) = rad2deg(mean(atan2(Timetrace.data.(Lockin.dev2.address).demod1.y,Timetrace.data.(Lockin.dev2.address).demod1.x)));

        Timetrace.data_all_2.X.std(index, index2) = std(Timetrace.data.(Lockin.dev2.address).demod1.x);
        Timetrace.data_all_2.Y.std(index, index2) = std(Timetrace.data.(Lockin.dev2.address).demod1.y);
        Timetrace.data_all_2.R.std(index, index2) = std(sqrt(Timetrace.data.(Lockin.dev2.address).demod1.x .^2 + Timetrace.data.(Lockin.dev2.address).demod1.y .^2));
        Timetrace.data_all_2.Theta.std(index, index2) = rad2deg(std(atan2(Timetrace.data.(Lockin.dev2.address).demod1.y,Timetrace.data.(Lockin.dev2.address).demod1.x)));

        %% make plot 1
        addpoints(animated_line_X_1, Drive.voltage(index2), Timetrace.data_all_1.X.mean(index, index2));
        addpoints(animated_line_Y_1, Drive.voltage(index2), Timetrace.data_all_1.Y.mean(index, index2));
        addpoints(animated_line_R_1, Drive.voltage(index2), Timetrace.data_all_1.R.mean(index, index2));
        addpoints(animated_line_Theta_1, Drive.voltage(index2), Timetrace.data_all_1.Theta.mean(index, index2));

        %% make plot 2
        addpoints(animated_line_X_2, Drive.voltage(index2), Timetrace.data_all_2.X.mean(index, index2));
        addpoints(animated_line_Y_2, Drive.voltage(index2), Timetrace.data_all_2.Y.mean(index, index2));
        addpoints(animated_line_R_2, Drive.voltage(index2), Timetrace.data_all_2.R.mean(index, index2));
        addpoints(animated_line_Theta_2, Drive.voltage(index2), Timetrace.data_all_2.Theta.mean(index, index2));

        %% prepare new loop
        Drive.startV = Drive.setV;

    end

    %% ramp down drive voltage
    Drive.setV = Drive.endV;
    Drive = Apply_fixed_voltage(Settings, Drive);

end

%% set back frequency
fprintf('%s - Setting frequency = %1.2f Hz...', datetime('now'), Lockin.dev1.frequency_array(1) )
Lockin.dev1.dev.set_frequency(Lockin.dev1.frequency_array(1));
fprintf('done\n')

%% ramp down lockin bias
fprintf('Ramping drive AC voltage ...')
ramp_lockin(Lockin.dev1, Lockin.dev1.amplitude_rescaled, 0, Lockin.dev1.ramp_rate_rescaled);
fprintf('done\n')

%% clean workpace
Timetrace = rmfield(Timetrace, 'data');
Timetrace = rmfield(Timetrace, 'time');

%% save data
filename = sprintf('%s/%s_%s_%s', Settings.save_dir, Settings.filename, Settings.sample , Settings.type);
Save_data(Settings, Timetrace, Drive, Lockin, [filename '.mat']);

%% save figure
saveas(fig1, [filename '.png'])
saveas(fig1, [filename '.fig'])

%load train, sound(y,Fs)
%% reset gate if needed via reset_gate(Settings,Gate)


%% make surface plot
fig1 = figure('Name','MEMS calibration - T dep','Units','normalized');
fig1.Position = Settings.plot_position;
set(gcf,'color','white')
set(gca,'Box','on','LineWidth',2,'FontSize',24)
xlabel('Drive voltage (V)');
ylabel('Frequency');

surf(Lockin.dev1.frequency_array, Drive.voltage, Timetrace.data_all.R.mean')
view([0 90])
set(gca,'xscale','log')