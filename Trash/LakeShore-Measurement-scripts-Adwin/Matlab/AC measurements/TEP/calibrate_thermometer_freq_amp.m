% This script measures the resistance of the heater, thermometer 1, thermometer 2 at 1 omega for varying frequencies and amplitudes to
% find optimal freq and amplitude for AC conductance measurements vs bath
% amplitude.

%% clear
clear
close all hidden
clc

%% Settings
Settings.save_dir = 'E:\Samples\paal_sample_simulator\RT';
Settings.sample = 'Sample_simulator';
Settings.ADC_gain = [0 0 0 0 0 0 0 0]; % 2^N
Settings.auto = ''; %FEMTO
Settings.get_sample_T = 'Lakeshore325'; % {'', 'Lakeshore336', 'Lakeshore325', 'Oxford_ITC'}
%Settings.frequencies = [ 10.^linspace(1,4,11)];
Settings.frequencies = linspace(50,2000,11);
%Settings.currents = 10.^linspace(-5,-4,2);
Settings.currents = 1e-3:0.5e-3:2e-3;
Settings.ADwin = 'GoldII'; % GoldII or ProII

% Lockin 1 --> apply on heater, measure on heater
Lockin.dev1.sensitivity = 10;           % sensitivity (V). Use 10 for MFLI with no sensitivity set
Lockin.dev1.frequency = [11];           % Hz
Lockin.dev1.demod_oscillator = [1];           % select which oscillator input to use for each demodulator
Lockin.dev1.timeconstant = [0.1]; % seconds
Lockin.dev1.harmonic = 1;
Lockin.dev1.VI_gain = 1e-2;          % gain for V to I (source) conversion
Lockin.dev1.DC_current = 0; 
Lockin.dev1.ramp_rate_current = 1000e-6;       % A/s
Lockin.dev1.model = 'ZI_MFLI';
Lockin.dev1.input_diff = 'A';   %A; A-B; B
Lockin.dev1.input_range = 1;
Lockin.dev1.filter_order = [4];
Lockin.dev1.channels = {'x','y'};
Lockin.dev1.autoranging = 0;
Lockin.dev1.datarate = 5e3; % do not exceed 30e3!
Lockin.dev1.input_AC = 0;   % introduces large phase shift and amplitude reduction at frequencies < 5Hz
Lockin.dev1.Vgain = 1;      % to measure on thermometer
Lockin.dev1.osc_output = [1];
Lockin.dev1.accuracy = 90;

Lockin.dev2 = Lockin.dev1;
Lockin.dev2.Vgain = 1;
Lockin.dev2.VI_gain = 1e-3;

Lockin.dev3 = Lockin.dev2;

Timetrace.runtime_min = 0.8;
Timetrace.save_timetrace = 0;

% ZI MFLI
Timetrace.N_channels = numel(Lockin.dev1.channels);
Timetrace.channels = Lockin.dev1.channels;
Timetrace.device_list = cell(1);
Timetrace.clockbase = 60e6;
Timetrace.clim = [];
Timetrace.model = Lockin.dev1.model;
Timetrace.N_devices = 3;
Timetrace.datarate = Lockin.dev1.datarate;
Timetrace.get_T = 2;
Timetrace.high_speed = 1;
Timetrace.lowpass = 0;

% ADwin
Timetrace.scanrate = 10000;       % Hz
Timetrace.points_av = 1000;        % points
Timetrace.settling_time = 0;      % ms
Timetrace.settling_time_autoranging = 0;      % ms
Timetrace.process_number = 2;
Timetrace.clim = [];

Lockin.dev1.address = 'DEV6094'; % drive heater & measure heater
Lockin.dev2.address = 'DEV6056'; % drive thermometer 1 & measure thermometer 1
Lockin.dev3.address = 'DEV6676'; % drive thermometer 2 & measure thermometer 2

%% Initialize
Settings = Init(Settings);

%% get ADC gains
Settings.ADC = {Lockin.dev1.DC_current / Lockin.dev1.Vgain, Lockin.dev2.DC_current / Lockin.dev2.Vgain, Lockin.dev3.DC_current / Lockin.dev3.Vgain};

%% Initialize ADwin
[Settings, Timetrace] = get_readAI_process(Settings, Timetrace);
Settings = Init_ADwin(Settings, Timetrace);

%% Initialize Lockin
clear ziDAQ
ziDAQ('connect', 'localhost', 8004, 6);

Lockin.device_names = fieldnames(Lockin);
for i = 1:Timetrace.N_devices
    Lockin.(Lockin.device_names{i}) = Init_lockin(Lockin.(Lockin.device_names{i}));
end

%% initialize DAQ
Timetrace.datarate = Lockin.dev1.datarate;
Timetrace = Init_lockin_ZI_DAQ(Timetrace, Lockin);

%% synchronize lockins
[mds, Timetrace.devices_string] = Init_sync_ZI_lockins(Timetrace.device_list);
Run_sync_ZI_lockins(mds, Timetrace.devices_string);

%% Initialize data array
Settings.N_freq = length(Settings.frequencies);
Settings.N_currents = length(Settings.currents);

[Timetrace.data_all, Settings] = Define_arrays_T_calibration(Settings, Timetrace, [Settings.N_freq Settings.N_currents]);

%% init figure
fig = figure('Color','white');
set(gcf,'units','normalized')
set(fig, 'Position', Settings.plot_position)
ax = cell(numel(Settings.contacts) * 2);

LEG = cell(Settings.N_currents, 1);
for i = 1 : Settings.N_currents
    LEG{i} = sprintf('%1.2e A', Settings.currents(i));
end

counter = 1;
for jj = 1:2
    for ii = 1:numel(Settings.contacts)
        ax{counter} = subplot(2,3,counter);
        set(gca,'box','on','fontsize',16)
        set(gca,'xlim',[Settings.frequencies(1) Settings.frequencies(end)])
        set(gca, 'XScale', 'log')
        xlabel('Frequency (Hz)')
        ylabel([sprintf('Resistance - %s - %s', Settings.contacts{ii} , Settings.signal{jj}) '(\Omega)'])

        if counter == 1
            leg = legend;
            set(leg,'FontSize', 12,'Box','off')
        end

        counter = counter + 1;
    end
end

lineplot = cell(Settings.N_currents, numel(Settings.contacts) * 2);

%% Run measurements
actualV = 0;
for i = 1 : Settings.N_currents

    %% init line plot
    colors = colormap(inferno(Settings.N_currents));
    counter = 1;
    for ii = 1:numel(Settings.contacts)
        for jj = 1:2
            lineplot{i, counter} = animatedline('Color',colors(i,:), 'parent', ax{counter}, 'LineWidth', 2);
            counter = counter + 1;
        end
    end

    leg.String{i} = LEG{i};

    %% Calculate currents
    for ii = 1 : Timetrace.N_devices
        Lockin.(Lockin.device_names{ii}).amplitude_Ibias = Settings.currents(i);     % AC current for resistance measurement (A) and used as DC current value for heater dependence
        Lockin.(Lockin.device_names{ii}).amplitude_Ibias_rescaled = Lockin.(Lockin.device_names{ii}).amplitude_Ibias / Lockin.(Lockin.device_names{ii}).VI_gain;
        Lockin.(Lockin.device_names{ii}).ramp_rate_rescaled = Lockin.(Lockin.device_names{ii}).ramp_rate_current / Lockin.(Lockin.device_names{ii}).VI_gain;
    end

    %% ramp up lockin 1 and 2 and 3 for conductance measurement
    fprintf('%s - Conductance measurement - Setting AC amplitude to %1.3e A...', datetime('now'), Lockin.dev2.amplitude_Ibias)
    for ii = 1 : Timetrace.N_devices
        ramp_lockin(Lockin.(Lockin.device_names{ii}), actualV, Lockin.(Lockin.device_names{ii}).amplitude_Ibias_rescaled, Lockin.(Lockin.device_names{ii}).ramp_rate_rescaled);
    end
    fprintf(' done \n')

    actualV = Lockin.(Lockin.device_names{1}).amplitude_Ibias_rescaled;

    %% run frequency dependence
    for j = 1 : Settings.N_freq

        %% set frequency
        for ii = 1 : Timetrace.N_devices
            Lockin.(Lockin.device_names{ii}).dev.set_frequency(Settings.frequencies(j));
        end

        %% update timeconstant and run time
        timeconstant = 1./Settings.frequencies(j) * 10;
        for ii = 1 : Timetrace.N_devices
            Lockin.(Lockin.device_names{ii}).timeconstant = timeconstant;
            Lockin.(Lockin.device_names{ii}).dev.set_timeconstant(timeconstant);
        end

        %% update runtime
        Timetrace.actual_runtime = 1/Settings.frequencies(j) * ceil(Timetrace.runtime_min / (1/Settings.frequencies(j)));

        %% Init Adwin timetrace
        Timetrace.runtime = Timetrace.actual_runtime + 100;
        Timetrace = Init_timetrace_ADwin(Settings, Timetrace);
        Timetrace.runtime = Timetrace.actual_runtime;

        %% autorange input
        if Lockin.dev1.autoranging
            MFLI_autorange(Lockin, Timetrace.N_devices);
        end

        %% wait
        Timetrace.wait_time = Get_lockin_waiting_period(Lockin.dev1.filter_order, Lockin.dev1.accuracy) * Lockin.dev1.timeconstant;      % s
        pause(Timetrace.wait_time*2);

        %% Run measurement      
        fprintf('%s - Running time trace... ', datetime('now'));
        Timetrace = Acquire_data_timetrace_ADwin_MFLI(Settings, Timetrace, Lockin);
        fprintf('done \n');

        %% sort data measurement lockin
        Timetrace.index = i;        
        Timetrace.index2 = j;
        gains = {Settings.currents(i) * Lockin.(Lockin.device_names{1}).Vgain, Settings.currents(i) * Lockin.(Lockin.device_names{2}).Vgain, Settings.currents(i) * Lockin.(Lockin.device_names{3}).Vgain};
        ADwin_gains = ones(3,1);

        Timetrace.data_all = Process_data_T_calibration(Settings, Timetrace, Lockin, Timetrace.data_all, Timetrace.save_timetrace , gains);
        Timetrace.data_all = Process_data_T_calibration_ADwin(Settings, Timetrace, Timetrace.data_all, Timetrace.save_timetrace , ADwin_gains);

        Timetrace = rmfield(Timetrace, 'time');
        Timetrace = rmfield(Timetrace, 'data');

        %% make plot
        counter = 1;
        for jj = 1:2
            for ii = 1:numel(Settings.contacts)
                demod = sprintf('demod%01d', 1);
                addpoints(lineplot{i, counter}, Settings.frequencies(j), Timetrace.data_all.(Settings.contacts{ii}).(demod).(Settings.signal{jj}).mean(i,j))
                counter = counter + 1;
            end
        end
        drawnow
    end

end

%% ramp down lockin 1 and 2 and 3 for conductance measurement
fprintf('%s - Conductance measurement - Setting AC amplitude to %1.3e A...', datetime('now'), 0)
for ii = 1 : Timetrace.N_devices
    ramp_lockin(Lockin.(Lockin.device_names{ii}), actualV, 0, Lockin.(Lockin.device_names{ii}).ramp_rate_rescaled);
end
fprintf(' done\n')

%% save data
filename = sprintf('%s/%s_%s_freq_current_calibration', Settings.save_dir, Settings.filename, Settings.sample);
Save_data(Settings, Lockin, Timetrace, [filename '.mat']);

%% save figures time dep
saveas(fig, [filename '_freq_current_dep.png'])
saveas(fig, [filename '_freq_current_dep.fig'])
