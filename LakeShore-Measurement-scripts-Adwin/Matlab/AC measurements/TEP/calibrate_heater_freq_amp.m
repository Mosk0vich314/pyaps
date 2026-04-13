% This script measures the resistance of the heater, thermometer 1, thermometer 2 at 2 omega for varying heater frequencies and amplitudes

%% clear
clear
close all hidden
clc

%% Settings
Settings.save_dir = 'E:\Samples\paal_sample_simulator\RT';
Settings.sample = 'TEP_Sample_simulator';
Settings.ADC_gain = [0 0 0 0 0 0 0 0]; % 2^N
Settings.get_sample_T = 'Lakeshore325'; % {'', 'Lakeshore336', 'Lakeshore325', 'Oxford_ITC'}
%Settings.frequencies = [10.^linspace(1,2,3)];
%Settings.frequencies = [1 2 3 4 4.5 5 5.5 6 6.5 7 8 9 10 13 15 17 19 26 33 47 67 83 99];
%Settings.frequencies = [134];
Settings.frequencies = [10.^linspace(2.2,3,3)];
% Settings.currents = 0.001*ones(11,1);
Settings.currents = 1e-3:0.1e-3:2e-3;
Settings.ADwin = 'GoldII'; % GoldII or ProII

% Lockin 1 --> apply on heater, measure on heater 
Lockin.dev1.sensitivity = 10;           % sensitivity (V). Use 10 for MFLI with no sensitivity set
Lockin.dev1.frequency = Settings.frequencies(1);       % Hz
Lockin.dev1.demod_oscillator = 1;           % select which oscillator input to use for each demodulator
Lockin.dev1.harmonic = 2;           % Hz first entry should be 1, otherwise output frequency is changed!!!!
Lockin.dev1.timeconstant = [0.3];           % seconds
Lockin.dev1.VI_gain = 1e-2;          % gain for V to I (source) conversion
Lockin.dev1.ramp_rate_current = 1000e-6;       % A/s heater current
Lockin.dev1.DC_current = 50e-6;       % A/s
Lockin.dev1.DC_current_ramp_rate = 50e-6;       % A/s
Lockin.dev1.model = 'ZI_MFLI';
Lockin.dev1.input_diff = 'A';
Lockin.dev1.input_range = 1;
Lockin.dev1.filter_order = [4];
Lockin.dev1.channels = {'x','y'};
Lockin.dev1.autoranging = 0;            % delays data acquisition           
Lockin.dev1.resync = 1;
Lockin.dev1.datarate = 10e3; % do not exceed 30e3!
Lockin.dev1.input_AC = 0;
Lockin.dev1.Vgain = 1;      % to measure on thermometer
Lockin.dev1.accuracy = 90;      % measurement accuracy of lockin filter

% Lockin 1 --> apply on thermometer 1, measure on thermometer 1, require MD
% option for 2/4/6 harmonics and additional AC conductance measurement
Lockin.dev2 = Lockin.dev1;
Lockin.dev2.Vgain = 1;
Lockin.dev2.VI_gain = 1e-3;
Lockin.dev2.conductance_frequency = 77;
Lockin.dev2.AC_current = 50e-6;
Lockin.dev2.demod_oscillator = [1 1 1 2];
Lockin.dev2.harmonic = [2 4 6 1]; 

Lockin.dev3 = Lockin.dev1;
Lockin.dev3.Vgain = 1;
Lockin.dev3.VI_gain = 1e-3;
Lockin.dev3.harmonic = 2;

Timetrace.runtime_min = 1;

% ZI MFLI
Timetrace.N_channels = numel(Lockin.dev1.channels);
Timetrace.channels = Lockin.dev1.channels;
Timetrace.device_list = cell(1);
Timetrace.clockbase = 60e6;
Timetrace.clim = [];
Timetrace.model = Lockin.dev1.model;
Timetrace.N_devices = 3;
Timetrace.get_T = 2;
Timetrace.high_speed = 1;
Timetrace.lowpass = 0;
Timetrace.save_timetrace = 0;

% ADwin
Timetrace.scanrate = 75000;       % Hz
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

Lockin.dev2.frequency = [Lockin.dev1.frequency Lockin.dev2.conductance_frequency];

Lockin.device_names = fieldnames(Lockin);
for i = 1:Timetrace.N_devices
    Lockin.(Lockin.device_names{i}) = Init_lockin(Lockin.(Lockin.device_names{i}));
end

%% initialize DAQ
Timetrace.datarate = Lockin.dev1.datarate;
Timetrace = Init_lockin_ZI_DAQ(Timetrace, Lockin);

%% synchronize lockins
mydlg = warndlg('Go to LabOne and stop any existing MDS');
waitfor(mydlg);

[mds, Timetrace.devices_string] = Init_sync_ZI_lockins(Timetrace.device_list);
Run_sync_ZI_lockins(mds, Timetrace.devices_string);

% run phase sync for third lockin, instead of external reference
Run_phasesync_ZI_lockins(mds, Timetrace.devices_string);

%% Initialize data array
Settings.N_freq = length(Settings.frequencies);
Settings.N_currents = length(Settings.currents);

[Timetrace.data_all, Settings] = Define_arrays_T_calibration(Settings, Timetrace, [Settings.N_freq Settings.N_currents]);

%% init figure
fig = figure('Color','white');
set(gcf,'units','normalized')
set(fig, 'Position', Settings.plot_position)
ax = cell(numel(Settings.contacts) * 2);

LEG = cell(Settings.N_freq, 1);
for i = 1 : Settings.N_freq
    LEG{i} = sprintf('%1.2e Hz', Settings.frequencies(i));
end

counter = 1;
for jj = 1:numel(Settings.signal)
    for ii = 1:numel(Settings.contacts)
        ax{counter} = subplot(numel(Settings.signal),3,counter);
        set(gca,'box','on','fontsize',16)
        % set(gca,'xlim',[Settings.currents(1) Settings.currents(end)] *1e3 )
        set(gca, 'XScale', 'log')
        xlabel('Heater current (mA)')
        ylabel([sprintf('Resistance - %s - %s', Settings.contacts{ii} , Settings.signal{jj}) '(\Omega)'])

        if counter == 1
            leg = legend;
            set(leg,'FontSize', 12,'Box','off')
        end

        counter = counter + 1;
    end
end

lineplot = cell(Settings.N_freq, numel(Settings.contacts) * numel(Settings.signal));

%% get ramp rate heater current
for ii = 1 : Timetrace.N_devices
    Lockin.(Lockin.device_names{ii}).ramp_rate_rescaled = Lockin.(Lockin.device_names{ii}).ramp_rate_current / Lockin.(Lockin.device_names{ii}).VI_gain;
end

%% Ramp up DC current on thermometers and heater
fprintf('%s - Setting DC offset to %1.2f uA...', datetime('now'), Lockin.dev1.DC_current * 1e6)
for ii = 1 : Timetrace.N_devices
    Lockin.(Lockin.device_names{ii}).DC_current_rescaled = Lockin.(Lockin.device_names{ii}).DC_current / Lockin.(Lockin.device_names{ii}).VI_gain;
    Lockin.(Lockin.device_names{ii}).DC_current_ramp_rate_rescaled = Lockin.(Lockin.device_names{ii}).DC_current_ramp_rate / Lockin.(Lockin.device_names{ii}).VI_gain;
    ramp_lockin_offset(Lockin.(Lockin.device_names{ii}), 0, Lockin.(Lockin.device_names{ii}).DC_current_rescaled, Lockin.(Lockin.device_names{ii}).DC_current_ramp_rate_rescaled);
end
fprintf(' done \n')

%% Ramp up AC current on output 4 of thermometer 1 for conductance measurement
Lockin.dev2.dev.set_output_channel(0, 1); % switch off channel 1
Lockin.dev2.dev.set_output_channel(1, 4); % switch on channel 4

fprintf('%s - Setting AC current on T1 to %1.2f uA...', datetime('now'), Lockin.dev2.AC_current * 1e6)
for ii = 2
    Lockin.(Lockin.device_names{ii}).AC_current_rescaled = Lockin.(Lockin.device_names{ii}).AC_current / Lockin.(Lockin.device_names{ii}).VI_gain;
    ramp_lockin(Lockin.(Lockin.device_names{ii}), 0, Lockin.(Lockin.device_names{ii}).AC_current_rescaled, Lockin.(Lockin.device_names{ii}).ramp_rate_rescaled, 4);
end
fprintf(' done \n')

%% Run measurements
actualV = 0;
for i = 1 : Settings.N_freq

    %% init line plot
    colors = colormap(inferno(Settings.N_freq));
    counter = 1;
    for ii = 1:numel(Settings.contacts)
        for jj = 1:numel(Settings.signal)
            lineplot{i, counter} = animatedline('Color',colors(i,:), 'parent', ax{counter}, 'LineWidth', 2);
            counter = counter + 1;
        end
    end

    leg.String{i} = LEG{i};

    %% set heater frequency - for all as reference
    for ii = 1 : Timetrace.N_devices
        Lockin.(Lockin.device_names{ii}).dev.set_frequency(Settings.frequencies(i), 1);
    end

    %% update timeconstant
    timeconstant = 1./Settings.frequencies(i) * 10;
    % timeconstant = 1;
    for ii = 1 : Timetrace.N_devices
        Lockin.(Lockin.device_names{ii}).timeconstant = timeconstant;
        Lockin.(Lockin.device_names{ii}).dev.set_timeconstant(timeconstant);
    end

    %% update runtime
    Timetrace.actual_runtime  = 1/Settings.frequencies(i) * ceil(Timetrace.runtime_min / (1/Settings.frequencies(i)));

    %% Init ADwin timetrace
    Timetrace.runtime = Timetrace.actual_runtime + 100;
    Timetrace = Init_timetrace_ADwin(Settings, Timetrace);
    Timetrace.runtime = Timetrace.actual_runtime;

    %% resync
    if Lockin.dev1.resync == 1

        % run phase sync for third lockin, instead of external reference
        % Run_sync_ZI_lockins(mds, Timetrace.devices_string);
        Run = true;
        while Run
            try
                Run_phasesync_ZI_lockins(mds, Timetrace.devices_string);

                Run = false;
            catch
                clear mds
                [mds, Timetrace.devices_string] = Init_sync_ZI_lockins(Timetrace.device_list);
                Run_sync_ZI_lockins(mds, Timetrace.devices_string);

                % run phase sync for third lockin, instead of external reference
                Run_phasesync_ZI_lockins(mds, Timetrace.devices_string);
            end
        end
    end

    %% Wait thermalization
     % pause(30);

    %% run current dependence
    for j = 1 : Settings.N_currents

        %% Calculate heater current
        for ii = 1 : 1
            Lockin.(Lockin.device_names{ii}).amplitude_Ibias = Settings.currents(j);     % AC current for resistance measurement (A) and used as DC current value for heater dependence
            Lockin.(Lockin.device_names{ii}).amplitude_Ibias_rescaled = Lockin.(Lockin.device_names{ii}).amplitude_Ibias / Lockin.(Lockin.device_names{ii}).VI_gain;
        end

        %% ramp up lockin 1 heater
        Lockin.dev1.amplitude_Ibias = Settings.currents(j);
        fprintf('%s - Heater measurement - Setting amplitude to %1.3e A...', datetime('now'), Lockin.dev1.amplitude_Ibias)
        ramp_lockin(Lockin.(Lockin.device_names{1}), actualV, Lockin.(Lockin.device_names{1}).amplitude_Ibias_rescaled, Lockin.(Lockin.device_names{1}).ramp_rate_rescaled);
        fprintf(' done \n')

        actualV = Lockin.(Lockin.device_names{1}).amplitude_Ibias_rescaled;

        %% autorange input
        if Lockin.dev1.autoranging
            MFLI_autorange(Lockin, Timetrace.N_devices);
        end

        %% wait
        Timetrace.wait_time = Get_lockin_waiting_period(Lockin.dev1.filter_order, Lockin.dev1.accuracy) * Lockin.dev1.timeconstant;      % s
        pause(Timetrace.wait_time*2);

        %% Wait thermalization
        % pause(30);

        %% Run measurement
        fprintf('%s - Running time trace... ', datetime('now'));
        Timetrace = Acquire_data_timetrace_ADwin_MFLI(Settings, Timetrace, Lockin);
        fprintf('done \n');

        %% sort data measurement lockin
        Timetrace.index = i;
        Timetrace.index2 = j;
        gains = {Lockin.dev1.DC_current * Lockin.dev1.Vgain, ...
            [ Lockin.dev2.DC_current * Lockin.dev2.Vgain; Lockin.dev2.DC_current * Lockin.dev2.Vgain; Lockin.dev2.DC_current * Lockin.dev2.Vgain; Lockin.dev2.AC_current * Lockin.dev2.Vgain; ],...
            Lockin.dev3.DC_current * Lockin.dev3.Vgain};
        ADwin_gains = ones(3,1);
        Timetrace.data_all = Process_data_T_calibration(Settings, Timetrace, Lockin, Timetrace.data_all, Timetrace.save_timetrace, gains);
        Timetrace.data_all = Process_data_T_calibration_ADwin(Settings, Timetrace, Timetrace.data_all, Timetrace.save_timetrace, ADwin_gains);

        Timetrace = rmfield(Timetrace, 'time');
        Timetrace = rmfield(Timetrace, 'data');

        %% make plot of second harmonic
        counter = 1;
        for jj = 1:numel(Settings.signal)
            for ii = 1:numel(Settings.contacts)
                if ii == 2
                    idx = 2;
                else
                    idx = 1;
                end
                demod = sprintf('demod%01d',idx);
                addpoints(lineplot{i, counter}, Settings.currents(j) * 1e3, Timetrace.data_all.(Settings.contacts{ii}).(demod).(Settings.signal{jj}).mean(i,j))
                counter = counter + 1;
            end
        end
        drawnow
    end

end

%% ramp down lockin 1 heater current
fprintf('%s - Heater measurement - Setting amplitude to %1.3e A...', datetime('now'), 0)
for ii = 1 : 1
    ramp_lockin(Lockin.(Lockin.device_names{ii}), actualV, 0, Lockin.(Lockin.device_names{ii}).ramp_rate_rescaled);
end
fprintf(' done\n')

%% ramp down DC offset on thermometers
fprintf('%s - Setting DC offset to %1.2f uA...', datetime('now'), 0)
for ii = 1 : Timetrace.N_devices
    ramp_lockin_offset(Lockin.(Lockin.device_names{ii}), Lockin.(Lockin.device_names{ii}).DC_current_rescaled, 0, Lockin.(Lockin.device_names{ii}).ramp_rate_rescaled);
end
fprintf(' done \n')

%% save data
filename = sprintf('%s/%s_%s_freq_current_calibration', Settings.save_dir, Settings.filename, Settings.sample);
Save_data(Settings, Lockin, Timetrace, [filename '.mat']);

%% save figures time dep
saveas(fig, [filename '_freq_current_dep.png'])
saveas(fig, [filename '_freq_current_dep.fig'])
