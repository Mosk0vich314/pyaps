% This script measures the resistance of the heater, thermometer 1,
% thermometer 2 for various bath temperatures, frequencies and heater currents. For each measurement, and long measurement at low sampling rate is performed, followed
% by a short measurement at high sample rate that is used for averaging.The
% switch is used to measure sequentially each thermometer, in case for
% example graphene is present on the device.

% This scripts requires 3x ZI MFLI lockins as the lockin output needs to be able to apply both a DC current bias on the
% thermometers during the heater dependence (and the voltage is monitored on the second harmonic), as well as an
% AC modulation to measure the conductance when the heater is switched off.


%% clear
clear
close all hidden
clc

%% Settings
Settings.save_dir = 'E:\Samples\FrevaPaal_graphene_TEP\FullCalibrationAndFreq_v2';
Settings.sample = 'GrapheneA3';
Settings.ADC_gain = [0 0 0 0 0 0 0 0]; % 2^N
Settings.get_sample_T = 'Lakeshore325'; % {'', 'Lakeshore336', 'Lakeshore325', 'Oxford_ITC'}
Settings.temperature_heater = 50:10:300;           % bath temperature [7.5 25 50 75 100 125 150 175 200 225 250 275 300]

Settings.temperature_no_heater = 50:1:300; %[105:-15:105];

Settings.frequency_array = 10.^linspace(1, log10(2738), 27);           % Hz
Settings.frequency_array(5) = 21.7;
Settings.frequency_array(7) = 38;
Settings.frequency_array(10) = 66;
Settings.frequency_array(21) = 770;
Settings.conductance_frequency = 70;
Settings.N_thermometers = 1;  % number of thermometers to measure using switch

Settings.ADwin = 'GoldII'; % GoldII or ProII

% Lockin 1 --> apply on heater, measure on thermometer 1
Lockin.dev1.sensitivity = 10;           % sensitivity (V). Use 10 for MFLI with no sensitivity set
Lockin.dev1.demod_oscillator = 1;           % select which oscillator input to use for each demodulator
Lockin.dev1.harmonic = 2;
Lockin.dev1.timeconstant = 1;           % seconds
Lockin.dev1.amplitude_heater_current = linspace(0,2,21);           % heater amplitude mA
Lockin.dev1.amplitude_Ibias = 50e-6;     % AC current for resistance measurement (A) and used as DC current value for heater dependence
Lockin.dev1.VI_gain = 1e-3;          % gain for V to I (source) conversion
Lockin.dev1.ramp_rate_current = 200e-6;       % A/s
Lockin.dev1.DC_current = 50e-6;       % A/s
Lockin.dev1.DC_current_ramp_rate = 50e-6;       % A/s
Lockin.dev1.model = 'ZI_MFLI';
Lockin.dev1.input_diff = 'A';
Lockin.dev1.input_range = 1;
Lockin.dev1.filter_order = 4;
Lockin.dev1.channels = {'x','y'};
Lockin.dev1.autoranging = 1;
Lockin.dev1.resync = 0;
Lockin.dev1.datarate_no_heater = 50; % do not exceed 30e3!
Lockin.dev1.datarate_heater = 50; % do not exceed 30e3!
Lockin.dev1.datarate_average = 1000; % do not exceed 30e3!
Lockin.dev1.input_AC = 0;
Lockin.dev1.Vgain = 10;      % to measure on thermometer
Lockin.dev1.accuracy = 90;      % measurement accuracy of lockin filter

Lockin.dev2 = Lockin.dev1;
Lockin.dev2.VI_gain = 1e-3;
Lockin.dev2.demod_oscillator = 1;
Lockin.dev2.harmonic = [1 2 4 6];

Lockin.dev3 = Lockin.dev1;
Lockin.dev3.VI_gain = 1e-3;
Lockin.dev3.demod_oscillator = 1;
Lockin.dev3.harmonic = [1 2 4 6];
Lockin.dev3.Vgain = 1;      % to measure on thermometer

Timetrace.wait_time = Get_lockin_waiting_period(Lockin.dev1.filter_order, Lockin.dev1.accuracy) * Lockin.dev1.timeconstant;      % s
Timetrace.runtime_no_heater = 10; %1800;
Timetrace.runtime_heater = 1; %60;
Timetrace.runtime_average = 10; %10;
Timetrace.get_T = 2;          %  measure T during waiting, specify number of thermometers

% ZI MFLI
Timetrace.N_channels = numel(Lockin.dev1.channels);
Timetrace.channels = Lockin.dev1.channels;
Timetrace.device_list = cell(1);
Timetrace.clockbase = 60e6;
Timetrace.clim = [];
Timetrace.model = Lockin.dev1.model;
Timetrace.N_devices = 3;
Timetrace.high_speed = 0;           % 1 cannot be used because T has be be acquired at the same time
Timetrace.lowpass = 0;
Timetrace.save_timetrace = 0;

% ADwin
Timetrace.scanrate = 75000;       % Hz
Timetrace.points_av = 1000;        % points
Timetrace.settling_time = 0;      % ms
Timetrace.settling_time_autoranging = 0;      % ms
Timetrace.process_number = 2;
Timetrace.clim = [];

Lockin.dev1.address = 'DEV6676'; % drive heater & measure heater
Lockin.dev2.address = 'DEV6056'; % drive thermometer 1 & measure thermometer 1
Lockin.dev3.address = 'DEV6565'; % drive thermometer 2 & measure thermometer 2

Switch.V_per_V = 1;
Switch.output = 5;
Switch.ramp_rate = 1000;
Switch.process_number = 3;
Switch.process = 'Fixed_AO';

%% Initialize
Settings = Init(Settings);

%% get ADC gains
Settings.ADC = {Lockin.dev1.DC_current / Lockin.dev1.Vgain, Lockin.dev2.DC_current / Lockin.dev2.Vgain, Lockin.dev3.DC_current / Lockin.dev3.Vgain};

%% Initialize Lockin
clear ziDAQ
ziDAQ('connect', 'localhost', 8004, 6);

Lockin.dev1.frequency = Settings.frequency_array(1);
Lockin.dev2.frequency = Settings.frequency_array(1);
Lockin.dev3.frequency = Settings.frequency_array(1);

Lockin.device_names = fieldnames(Lockin);
for i = 1:Timetrace.N_devices
    Lockin.(Lockin.device_names{i}) = Init_lockin(Lockin.(Lockin.device_names{i}));
end

%% initialize DAQ
Timetrace = Init_lockin_ZI_DAQ(Timetrace, Lockin);

Timetrace.N_harmonics_no_heater = {1, 1, 1};
Timetrace.N_harmonics_heater = Timetrace.N_harmonics;

%% Init ADwin
[Settings, Timetrace] = get_readAI_process(Settings, Timetrace);
Settings = Init_ADwin(Settings, Timetrace, Switch);

%% synchronize lockins
mydlg = warndlg('Go to LabOne and stop any existing MDS');
waitfor(mydlg);

[mds, Timetrace.devices_string] = Init_sync_ZI_lockins(Timetrace.device_list);
Run_sync_ZI_lockins(mds, Timetrace.devices_string);

% run phase sync for third lockin, instead of external reference
Run_phasesync_ZI_lockins(mds, Timetrace.devices_string);

%% Initialize data array
Settings.N_temp_heater = length(Settings.temperature_heater);
Settings.N_temp_no_heater = length(Settings.temperature_no_heater);
Settings.N_amplitude_heater_current = length(Lockin.dev1.amplitude_heater_current);
Settings.N_freq = length(Settings.frequency_array);

[Timetrace.no_heater.long, Settings] = Define_arrays_T_calibration(Settings, Timetrace, [Settings.N_temp_no_heater Settings.N_amplitude_heater_current Settings.N_freq 2]);
[Timetrace.no_heater.short, Settings] = Define_arrays_T_calibration(Settings, Timetrace, [Settings.N_temp_no_heater Settings.N_amplitude_heater_current Settings.N_freq 2]);
[Timetrace.heater.long, Settings] = Define_arrays_T_calibration(Settings, Timetrace, [Settings.N_temp_no_heater Settings.N_amplitude_heater_current Settings.N_freq 2]);
[Timetrace.heater.short, Settings] = Define_arrays_T_calibration(Settings, Timetrace, [Settings.N_temp_no_heater Settings.N_amplitude_heater_current Settings.N_freq 2]);

%% Calculate heater currents
Lockin.dev1.amplitude_heater_rescaled = Lockin.dev1.amplitude_heater_current * 1e-3 / Lockin.dev1.VI_gain;  % heater dependence

%% Calculate current for AC measurement
for i = 1 : Timetrace.N_devices
    Lockin.(Lockin.device_names{i}).amplitude_Ibias_rescaled = Lockin.(Lockin.device_names{i}).amplitude_Ibias / Lockin.(Lockin.device_names{i}).VI_gain;
    Lockin.(Lockin.device_names{i}).ramp_rate_rescaled = Lockin.(Lockin.device_names{i}).ramp_rate_current / Lockin.(Lockin.device_names{i}).VI_gain;
end

%% define figures
figure_time_dep = 'Resistance versus time';
figure_T_dep = 'Resistance versus bath temperature';
figure_heater_dep = 'Resistance versus heater current';
figure_heater_dep_conductance = 'AC resistance versus heater current';

%% define swtich starting voltage
Switch.startV = 0;

%% Run measurements
for i = 1 : Settings.N_temp_no_heater

    %% resynchronize MFLI lockins
    if Lockin.dev1.resync
        Run_sync_ZI_lockins(mds, Timetrace.devices_string)
    end
    
    %% set frequency for conductance measurement
    for ii = 1 : Timetrace.N_devices
        Lockin.(Lockin.device_names{ii}).dev.set_frequency(Settings.conductance_frequency);
    end

    %% phase sync
    Run_phasesync_ZI_lockins(mds, Timetrace.devices_string);

    %% set temperature
    fprintf('%s - Setting temperature to %1.2fK... \n', datetime('now'), Settings.temperature_no_heater(i))
    Settings.T_controller.set_T_setpoint(1, Settings.temperature_no_heater(i));

    %% set first harmonic
    for ii = 1 : Timetrace.N_devices
        Lockin.(Lockin.device_names{ii}).dev.set_harmonic(1);
    end

    %% set demodulators
    Timetrace.N_harmonics = Timetrace.N_harmonics_no_heater;
    Timetrace.N_demods = cellfun(@numel, Timetrace.N_harmonics);

    %% Run measurement long no heater
    if i~=1
        pause(15*60);
    else 
        pause(30*60);
    end

    Timetrace.runtime = Timetrace.runtime_no_heater;
    Timetrace.runtime_counts = ceil(Lockin.dev1.datarate_no_heater * Timetrace.runtime);

    fprintf('%s - Running time trace long... ', datetime('now'));
    Timetrace = Acquire_data_timetrace_MFLI_DAQ(Settings, Timetrace, Lockin);
    fprintf('done \n');

    %% Process data
    Timetrace.index = i;
    Timetrace.index2 = 1;
    Timetrace.index3 = 1;
    Timetrace.index4 = 1;
    gains = {Lockin.dev1.amplitude_Ibias * Lockin.dev1.Vgain, ...
        Lockin.dev1.amplitude_Ibias * Lockin.dev2.Vgain,...
        Lockin.dev1.amplitude_Ibias * Lockin.dev3.Vgain};

    Timetrace.no_heater.long = Process_data_T_calibration(Settings, Timetrace, Lockin, Timetrace.no_heater.long, Timetrace.save_timetrace, gains);
    Timetrace.no_heater.long = Process_data_T_calibration_Temperature(Timetrace, Timetrace.no_heater.long);

    %% Init short measurement with heater off
    Timetrace.T = zeros(1, Timetrace.get_T);
    Timetrace.T_time = zeros(1, 1);

    %% set data rate
    Timetrace.datarate = Lockin.dev1.datarate_average;
    for ii = 1 : Timetrace.N_devices
        for k = 1:numel(Lockin.(Lockin.device_names{ii}).harmonic)
            Lockin.(Lockin.device_names{ii}).dev.set_data_rate(Timetrace.datarate, k);
        end
    end

    Timetrace.datarate = Lockin.(Lockin.device_names{1}).dev.get_data_rate(1);
    Lockin.dev1.datarate_average_new = Timetrace.datarate;

    %% switch thermometers
    for index4 = 1:Settings.N_thermometers

        %% set thermometer switch
        Timetrace.index4 = index4;
        fprintf('%s - Switching thermometer %0d measurement...', datetime('now'), index4)
        Switch.setV = (index4-1)*5;
        Switch = Apply_fixed_voltage(Settings, Switch);
        Switch.startV = Switch.setV;
        fprintf('done\n')

        %% ramp up lockin 1 and 2 and 3 for conductance measurement
        fprintf('%s - Conductance measurement - Setting AC amplitude to %1.3fmA...', datetime('now'), Lockin.dev2.amplitude_Ibias * 1e3)
        for ii = 1 : Timetrace.N_devices
            ramp_lockin(Lockin.(Lockin.device_names{ii}), 0, Lockin.(Lockin.device_names{ii}).amplitude_Ibias_rescaled, Lockin.(Lockin.device_names{ii}).ramp_rate_rescaled, 1);
        end
        fprintf(' done \n')

        %% 
        pause(1)

        %% autorange input
        if Lockin.dev1.autoranging
            MFLI_autorange(Lockin, Timetrace.N_devices);
        end

        %% 
        pause(10)

        %% Run measurement short with heater off
        Timetrace.runtime = Timetrace.runtime_average;
        Timetrace.runtime_counts = ceil(Lockin.dev1.datarate_average * Timetrace.runtime);

        fprintf('%s - Running time trace short... ', datetime('now'));
        Timetrace = Acquire_data_timetrace_MFLI_DAQ(Settings, Timetrace, Lockin);
        fprintf('done \n');

        %% Process data
        Timetrace.index2 = 1;
        Timetrace.index3 = 1;

        Timetrace.no_heater.short = Process_data_T_calibration(Settings, Timetrace, Lockin, Timetrace.no_heater.short, Timetrace.save_timetrace, gains);
        Timetrace.no_heater.short = Process_data_T_calibration_Temperature(Timetrace, Timetrace.no_heater.short);

        %% make plot time dependence
        Timetrace.runtime = Timetrace.runtime_no_heater;
        fig_time_dep = Realtime_timetrace_T_calibration_time_dep(Settings, Timetrace, figure_time_dep);

        %% make plot temperature depedence
        fig_T_dep = Realtime_timetrace_T_calibration_T_dep(Settings, Timetrace, figure_T_dep);

        %% ramp down AC lockin 1 and 2 and 3 for conductance measurement
        fprintf('%s - Conductance measurement - Setting AC amplitude to %1.3fmA...', datetime('now'), 0 * 1e3)
        for ii = 1 : Timetrace.N_devices
            ramp_lockin(Lockin.(Lockin.device_names{ii}), Lockin.(Lockin.device_names{ii}).amplitude_Ibias_rescaled, 0, Lockin.(Lockin.device_names{ii}).ramp_rate_rescaled);
        end
        fprintf(' done \n')

        %% Run heater dependence
        if ismember(Settings.temperature_no_heater(i), Settings.temperature_heater)

            %% ramp up DC offset lockin 1 and 2 and 3 for heater dependent measurement
            fprintf('%s - Heater dependence - Setting DC offset to %1.3f mA...', datetime('now'), Lockin.dev1.amplitude_Ibias * 1e3)
            for ii = 1 : Timetrace.N_devices
                ramp_lockin_offset(Lockin.(Lockin.device_names{ii}), 0, Lockin.(Lockin.device_names{ii}).amplitude_Ibias_rescaled, Lockin.(Lockin.device_names{ii}).ramp_rate_rescaled);
            end
            fprintf(' done \n')

            %% set harmonics
            for ii = 1:Timetrace.N_devices
                for jj = 1:numel(Lockin.(Lockin.device_names{ii}).harmonic)
                    Lockin.(Lockin.device_names{ii}).dev.set_harmonic(Lockin.(Lockin.device_names{ii}).harmonic(jj), jj);
                end
            end

            %% set demodulators
            Timetrace.N_harmonics = Timetrace.N_harmonics_heater;
            Timetrace.N_demods = cellfun(@numel, Timetrace.N_harmonics);

            %% run freq dependence
            for kk = 1:Settings.N_freq

                Timetrace.index3 = kk;

                %% set heater frequency
                fprintf('%s - Heater dependence - Setting AC heater frequency to %1.3f Hz...', datetime('now'), Settings.frequency_array (kk))
                for ii = 1 : Timetrace.N_devices
                    Lockin.(Lockin.device_names{ii}).dev.set_frequency(Settings.frequency_array(kk));
                end
                fprintf(' done\n')

                %% phase sync
                Run_phasesync_ZI_lockins(mds, Timetrace.devices_string);

                %% update timeconstant
                % Lockin.dev1.timeconstant = 10 / min(Settings.frequency_array(kk)*2, Settings.conductance_frequency);
                % Timetrace.wait_time = Get_lockin_waiting_period(Lockin.dev1.filter_order, Lockin.dev1.accuracy) * Lockin.dev1.timeconstant;      % s
                % 
                % for iii = 1:Timetrace.N_devices
                %     Lockin.(Lockin.device_names{iii}).dev.set_timeconstant(Lockin.dev1.timeconstant);
                % end

                %% run heater dependence
                amplitude_actualV = 0;
                for j = 1 : Settings.N_amplitude_heater_current

                    Timetrace.index2 = j;

                    %% ramp up lockin 1 heater current
                    fprintf('%s - Heater dependence - Setting AC heater current to %1.3f mA...', datetime('now'), Lockin.dev1.amplitude_heater_current(j))
                    ramp_lockin(Lockin.dev1, amplitude_actualV, Lockin.dev1.amplitude_heater_rescaled(j), Lockin.dev1.ramp_rate_rescaled);
                    amplitude_actualV = Lockin.dev1.amplitude_heater_rescaled(j);
                    fprintf(' done\n')

                    %% Init long measurement with heater on
                    Timetrace.T = zeros(1, Timetrace.get_T);
                    Timetrace.T_time = zeros(1, 1);

                    %% Init ADwin
                    Timetrace.runtime = Timetrace.runtime_heater + 100;
                    Timetrace = Init_timetrace_ADwin(Settings, Timetrace);
                    Timetrace.runtime = Timetrace.runtime_heater;

                    %% set data rate
                    Timetrace.datarate = Lockin.dev1.datarate_heater;
                    for ii = 1 : Timetrace.N_devices
                        for k = 1:numel(Lockin.(Lockin.device_names{ii}).harmonic)
                            Lockin.(Lockin.device_names{ii}).dev.set_data_rate(Timetrace.datarate, k);
                        end
                    end

                    Timetrace.datarate = Lockin.(Lockin.device_names{1}).dev.get_data_rate(1);
                    Lockin.dev1.datarate_heater_new = Timetrace.datarate;

                    %% pause 
                    pause(1)

                    %% autorange input
                    if Lockin.dev1.autoranging
                        MFLI_autorange(Lockin, Timetrace.N_devices);
                    end

                    %% Run measurement
                    fprintf('%s - Running time trace long... ', datetime('now'));
                    pause(10);
                    Timetrace = Acquire_data_timetrace_ADwin_MFLI_DAQ(Settings, Timetrace, Lockin);
                    fprintf('done \n');

                    %% Process data
                    gains = {Lockin.dev1.DC_current * Lockin.dev1.Vgain, Lockin.dev2.DC_current * Lockin.dev2.Vgain * ones(4,1),...
                        Lockin.dev2.DC_current * Lockin.dev2.Vgain * ones(4,1)};

                    Timetrace.heater.long = Process_data_T_calibration(Settings, Timetrace, Lockin, Timetrace.heater.long, Timetrace.save_timetrace, gains);
                    Timetrace.heater.long = Process_data_T_calibration_Temperature(Timetrace, Timetrace.heater.long);
                    Timetrace.heater.long = Process_data_T_calibration_ADwin(Settings, Timetrace, Timetrace.heater.long, Timetrace.save_timetrace, ones(3,1));

                    %% Init short measurement with heater on
                    Timetrace.T = zeros(1, Timetrace.get_T);
                    Timetrace.T_time = zeros(1, 1);

                    %% Init ADwin
                    Timetrace.runtime = Timetrace.runtime_average + 100;
                    Timetrace = Init_timetrace_ADwin(Settings, Timetrace);
                    Timetrace.runtime = Timetrace.runtime_average;

                    %% set data rate
                    Timetrace.datarate = Lockin.dev1.datarate_average;
                    for ii = 1 : Timetrace.N_devices
                        for k = 1:numel(Lockin.(Lockin.device_names{ii}).harmonic)
                            Lockin.(Lockin.device_names{ii}).dev.set_data_rate(Timetrace.datarate, k);
                        end
                    end

                    Timetrace.datarate = Lockin.(Lockin.device_names{1}).dev.get_data_rate(1);
                    Lockin.dev1.datarate_average_new = Timetrace.datarate;

                    %% Run measurement
                    fprintf('%s - Running time trace short... ', datetime('now'));
                    Timetrace = Acquire_data_timetrace_ADwin_MFLI_DAQ(Settings, Timetrace, Lockin);
                    fprintf('done \n');

                    %% Process data
                    Timetrace.heater.short = Process_data_T_calibration(Settings, Timetrace, Lockin, Timetrace.heater.short, Timetrace.save_timetrace, gains);
                    Timetrace.heater.short = Process_data_T_calibration_Temperature(Timetrace, Timetrace.heater.short);
                    Timetrace.heater.short = Process_data_T_calibration_ADwin(Settings, Timetrace, Timetrace.heater.short, Timetrace.save_timetrace, ones(3,1));

                    %% make plot heater dependence
                    fig_heater_dep = Realtime_timetrace_T_calibration_heater_dep(Settings, Timetrace, Lockin, figure_heater_dep);

                end

                %% ramp down lockin heater current
                fprintf('%s - Heater dependence - Setting AC heater current to %1.3f mA...', datetime('now'), 0)
                ramp_lockin(Lockin.dev1, amplitude_actualV, 0, Lockin.dev1.ramp_rate_rescaled);
                fprintf(' done\n')

            end

            %% ramp down DC offset lockin 1, 2 and 3 for heater dependent measurement
            fprintf('%s - Heater dependence - Setting DC offset to %1.3f mA...', datetime('now'), 0 * 1e3)
            for ii = 1 : Timetrace.N_devices
                ramp_lockin_offset(Lockin.(Lockin.device_names{ii}), Lockin.(Lockin.device_names{ii}).amplitude_Ibias_rescaled, 0, Lockin.(Lockin.device_names{ii}).ramp_rate_rescaled);
            end
            fprintf(' done\n')

        end

    end

    %% save data
    filename = sprintf('%s/%s_%s_T_calibration', Settings.save_dir, Settings.filename, Settings.sample);
    Save_data(Settings, Lockin, Timetrace, [filename '.mat']);

end

%% save data
Timetrace.no_heater = rmfield(Timetrace.no_heater,"long");
Timetrace.heater = rmfield(Timetrace.heater,"long");
filename = sprintf('%s/%s_%s_T_calibration', Settings.save_dir, Settings.filename, Settings.sample);
Save_data(Settings, Lockin, Timetrace, [filename '.mat']);

%% save figures time dep
saveas(fig_time_dep, [filename '_time_dep.png'])
saveas(fig_time_dep, [filename '_time_dep.fig'])

%% save figures T dep
saveas(fig_T_dep, [filename '_T_dep.png'])
saveas(fig_T_dep, [filename '_T_dep.fig'])

%% save figures heater dep
saveas(fig_heater_dep, [filename '_heater_dep.png'])
saveas(fig_heater_dep, [filename '_heater_dep.fig'])

%% set temperature back to first point
% fprintf('%s - Setting temperature to %1.2fK... \n', datetime('now'), Settings.temperature_no_heater(1))
% Settings.T_controller.set_T_setpoint(1, Settings.temperature_no_heater(1));

%% set thermometer switch
index4 = 1;
fprintf('%s - Switching thermometer %0d measurement...', datetime('now'), index4)
Switch.setV = (index4-1)*5;
Switch = Apply_fixed_voltage(Settings, Switch);
Switch.startV = Switch.setV;
fprintf('done\n')