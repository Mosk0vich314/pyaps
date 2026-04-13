%% clear
clear
close all hidden
clc

%% Settings
Settings.save_dir = 'C:\Samples\Fred\testingAcquisitionMethodsGains\aux1\1e6';
Settings.sample = 'High_res_noAC_sig1'; %A2-GatetoGate G0b Test_100MOhm_50ohm_termination
Settings.auto = ''; %FEMTO
Settings.ADC_gain = [0 0 0 0 0 0 0 0]; % 2^N
Settings.get_sample_T = 'Lakeshore336'; % {'', 'Lakeshore336', 'Lakeshore325', 'Oxford_ITC'}
Settings.type = 'Gate_sweep_TEP_Timetraces';
Settings.ADwin = 'ProII'; % GoldII or ProII

Bias.initV = 0;
Bias.V_per_V = 0.01;          % V/V0
Bias.voltage = 0.001;              % V
Bias.ramp_rate = 0.01;
Bias.fixed_voltage = 'ADwin';

% Lockin 1 --> apply on heater
Lockin.dev1.sensitivity = 10;           % sensitivity (V). Use 10 for MFLI with no sensitivity set
Lockin.dev1.frequency = [7.77];           % Hz
Lockin.dev1.harmonic = [2 1 1 1];           %
Lockin.dev1.timeconstant = 0.1;           % seconds
Lockin.dev1.VI_gain = 1e-3;             % A / V of current source
Lockin.dev1.ramp_rate = 0.1;            % heater amplitude ramp rate mA/s
Lockin.dev1.IVgain = 1e6;               %  IV converter
Lockin.dev1.reserve = 0;               %  0 = high, 1 = normal, 2 = low
Lockin.dev1.model = 'ZI_MFLI';
Lockin.dev1.input_diff = 'A';
Lockin.dev1.input_range = 0.03;
Lockin.dev1.filter_order = 4;
Lockin.dev1.channels = {'x','y','auxin0'};
Lockin.dev1.autoranging = 0;
Lockin.dev1.resync = 0;
Lockin.dev1.datarate = 30e3; % do not exceed 30e3!
Lockin.dev1.input_AC = 1;

% Lockin 2 --> apply across device, measure conductance, DC current measured on AUX1
Lockin.dev2 = Lockin.dev1;
Lockin.dev2.sensitivity = 10;           % sensitivity (V). Use 10 for MFLI with no sensitivity set
Lockin.dev2.frequency = 77;           % Hz
Lockin.dev2.harmonic = 1;           %
Lockin.dev2.amplitude_Vbias = 0.01;           % amplitude bias oscillation for conductance measurement mV
Lockin.dev2.ramp_rate = 0.1;           % mV / s
Lockin.dev2.V_per_V = 0.0001;
Lockin.dev2.model = 'ZI_MFLI';
Lockin.dev2.input_diff = 'A';
Lockin.dev2.input_range = 0.03;

% Timetrace.runtime = (1/(Lockin.dev2.frequency - Lockin.dev1.frequency)) * 7;      % s
Timetrace.accuracy = 2; % digits for timeperiod calculation
Timetrace.wait_time = Get_lockin_waiting_period(Lockin.dev1.filter_order, 60) * Lockin.dev1.timeconstant;      % s

% ADwin
Timetrace.scanrate = 500000;       % Hz
Timetrace.points_av = 10;        % points
Timetrace.settling_time = 0;      % ms
Timetrace.settling_time_autoranging = 0;      % ms
Timetrace.process_number = 2;
Timetrace.clim = [];

% ZI MFLI
Timetrace.N_channels = numel(Lockin.dev1.channels);
Timetrace.channels = Lockin.dev1.channels;
Timetrace.clockbase = 60e6;
Timetrace.clim = [];
Timetrace.model = Lockin.dev1.model;
Timetrace.datarate = Lockin.dev1.datarate;
Timetrace.high_speed = 1;
Timetrace.get_T = 0;

Gate.initV = 0;
Gate.minV = -1.5;            % V
Gate.maxV = 1.5;            % V
Gate.points = 2001;
Gate.ramp_rate = 1;       % V/s
Gate.waiting_time = 0;     % s after setting Gate.setV
Gate.V_per_V = 1;          % V/V0
Gate.sweep_dir = 'up';

Gate.output = 2;
Gate.process_number = 3;
Gate.process = 'Fixed_AO';

Bias.output = 1;
Bias.process_number = 3;
Bias.process = 'Fixed_AO';

Lockin.dev1.address = 'DEV6565'; % heater - thermocurrent
Lockin.dev2.address = 'DEV6628'; % bias

%% get ADC gains for ADwin
Settings.ADC = {Lockin.dev1.IVgain,...
    1,...
    1 / (Lockin.dev1.sensitivity / 10 / Lockin.dev1.IVgain), ...
    1 / (Lockin.dev1.sensitivity / 10 / Lockin.dev1.IVgain), ...
    1 / (Lockin.dev2.sensitivity / 10 / Lockin.dev1.IVgain / (Lockin.dev2.amplitude_Vbias * 1e-3)), ...
    1 / (Lockin.dev2.sensitivity / 10 / Lockin.dev1.IVgain / (Lockin.dev2.amplitude_Vbias * 1e-3)), ...
    };

%% Initialize
Settings = Init(Settings);

%% Initialize ADwin
[Settings, Timetrace] = get_readAI_process(Settings, Timetrace);
Settings = Init_ADwin(Settings, Timetrace, Gate);

%% Initialize Lockin
clear ziDAQ
ziDAQ('connect', 'localhost', 8004, 6);

Timetrace.N_devices = 2;

Lockin.device_names = fieldnames(Lockin);
for i = 1:Timetrace.N_devices
    Lockin.(Lockin.device_names{i}) = Init_lockin(Lockin.(Lockin.device_names{i}));
end

%% convert bias lockin voltage
Lockin.dev2.amplitude_rescaled = Lockin.dev2.amplitude_Vbias * 1e-3 / Lockin.dev2.V_per_V;
Lockin.dev2.ramp_rate_rescaled = Lockin.dev2.ramp_rate * 1e-3 / Lockin.dev2.V_per_V;

%% initialize Lockin
% osc 1, AC bias, demod AC current
% osc 2, AC bias, demod Aux1 @ 0 Hz
% osc 1, AC bias, demod AC current
Lockin.dev2.dev.set_input_AC(0)
Lockin.dev2.dev.set_input_float(1)
Lockin.dev2.dev.set_input_50Ohm(0)
Lockin.dev2.dev.set_input_diff('A')

% set frequencies
ziDAQ('setDouble', sprintf('/%s/oscs/%1.0f/freq', Lockin.dev2.address, 0), Lockin.dev2.frequency);
ziDAQ('setDouble', sprintf('/%s/oscs/%1.0f/freq', Lockin.dev2.address, 1), 0);
ziDAQ('setDouble', sprintf('/%s/oscs/%1.0f/freq', Lockin.dev2.address, 2), 0);
ziDAQ('setDouble', sprintf('/%s/oscs/%1.0f/freq', Lockin.dev2.address, 3), 0);

% select oscillators
ziDAQ('setInt', sprintf('/%s/demods/0/oscselect', Lockin.dev2.address), 0);
ziDAQ('setInt', sprintf('/%s/demods/1/oscselect', Lockin.dev2.address), 1);
ziDAQ('setInt', sprintf('/%s/demods/2/oscselect', Lockin.dev2.address), 2);
ziDAQ('setInt', sprintf('/%s/demods/3/oscselect', Lockin.dev2.address), 3);

% set harmonic
ziDAQ('setInt', sprintf('/%s/demods/%01d/harmonic', Lockin.dev2.address, 0), Lockin.dev2.harmonic);
ziDAQ('setInt', sprintf('/%s/demods/%01d/harmonic', Lockin.dev2.address, 1), Lockin.dev2.harmonic);
ziDAQ('setInt', sprintf('/%s/demods/%01d/harmonic', Lockin.dev2.address, 2), Lockin.dev2.harmonic);
ziDAQ('setInt', sprintf('/%s/demods/%01d/harmonic', Lockin.dev2.address, 3), Lockin.dev2.harmonic);

% set phase
ziDAQ('setDouble', sprintf('/%s/demods/%1.0f/phaseshift', Lockin.dev2.address, 0), 0);
ziDAQ('setDouble', sprintf('/%s/demods/%1.0f/phaseshift', Lockin.dev2.address, 1), 45);
ziDAQ('setDouble', sprintf('/%s/demods/%1.0f/phaseshift', Lockin.dev2.address, 2), 0);
ziDAQ('setDouble', sprintf('/%s/demods/%1.0f/phaseshift', Lockin.dev2.address, 3), 0);

% select signal input
ziDAQ('setInt', sprintf('/%s/demods/%01d/adcselect', Lockin.dev2.address, 0), 0);
ziDAQ('setInt', sprintf('/%s/demods/%01d/adcselect', Lockin.dev2.address, 1), 0);
ziDAQ('setInt', sprintf('/%s/demods/%01d/adcselect', Lockin.dev2.address, 2), 0);
ziDAQ('setInt', sprintf('/%s/demods/%01d/adcselect', Lockin.dev2.address, 3), 0);

% select filter order
ziDAQ('setInt', sprintf('/%s/demods/%01d/order', Lockin.dev2.address, 0), Lockin.dev2.filter_order);
ziDAQ('setInt', sprintf('/%s/demods/%01d/order', Lockin.dev2.address, 1), Lockin.dev2.filter_order);
ziDAQ('setInt', sprintf('/%s/demods/%01d/order', Lockin.dev2.address, 2), Lockin.dev2.filter_order);
ziDAQ('setInt', sprintf('/%s/demods/%01d/order', Lockin.dev2.address, 3), Lockin.dev2.filter_order);

% set TC
ziDAQ('setDouble', sprintf('/%s/demods/%1.0f/timeconstant', Lockin.dev2.address, 0), Lockin.dev1.timeconstant);
ziDAQ('setDouble', sprintf('/%s/demods/%1.0f/timeconstant', Lockin.dev2.address, 1), Lockin.dev1.timeconstant);
ziDAQ('setDouble', sprintf('/%s/demods/%1.0f/timeconstant', Lockin.dev2.address, 2), Lockin.dev1.timeconstant);
ziDAQ('setDouble', sprintf('/%s/demods/%1.0f/timeconstant', Lockin.dev2.address, 3), Lockin.dev1.timeconstant);

% set datarate
ziDAQ('setDouble', sprintf('/%s/demods/%1.0f/rate', Lockin.dev2.address, 0), Lockin.dev2.datarate);
ziDAQ('setDouble', sprintf('/%s/demods/%1.0f/rate', Lockin.dev2.address, 1), Lockin.dev2.datarate);
ziDAQ('setDouble', sprintf('/%s/demods/%1.0f/rate', Lockin.dev2.address, 2), Lockin.dev2.datarate);
ziDAQ('setDouble', sprintf('/%s/demods/%1.0f/rate', Lockin.dev2.address, 3), Lockin.dev2.datarate);

% enable demods
ziDAQ('setInt', sprintf('/%s/demods/%01d/enable', Lockin.dev2.address, 0), 1);
ziDAQ('setInt', sprintf('/%s/demods/%01d/enable', Lockin.dev2.address, 1), 1);
ziDAQ('setInt', sprintf('/%s/demods/%01d/enable', Lockin.dev2.address, 2), 0);
ziDAQ('setInt', sprintf('/%s/demods/%01d/enable', Lockin.dev2.address, 3), 0);

% set range
ziDAQ('setDouble', sprintf('/%s/sigouts/%1.0f/range', Lockin.dev2.address, 0), 1)

% set outputs
ziDAQ('setDouble', sprintf('/%s/sigouts/%1.0f/amplitudes/%1.0f', Lockin.dev2.address, 0, 0), Lockin.dev2.amplitude_rescaled * sqrt(2));
ziDAQ('setDouble', sprintf('/%s/sigouts/%1.0f/amplitudes/%1.0f', Lockin.dev2.address, 0, 1), 0);
ziDAQ('setDouble', sprintf('/%s/sigouts/%1.0f/amplitudes/%1.0f', Lockin.dev2.address, 0, 2), 0);
ziDAQ('setDouble', sprintf('/%s/sigouts/%1.0f/amplitudes/%1.0f', Lockin.dev2.address, 0, 3), 0);

% enable outputs
ziDAQ('setInt', sprintf('/%s/sigouts/%01d/enables/%01d', Lockin.dev2.address, 0, 0), 1);
ziDAQ('setInt', sprintf('/%s/sigouts/%01d/enables/%01d', Lockin.dev2.address, 0, 1), 0);
ziDAQ('setInt', sprintf('/%s/sigouts/%01d/enables/%01d', Lockin.dev2.address, 0, 2), 0);
ziDAQ('setInt', sprintf('/%s/sigouts/%01d/enables/%01d', Lockin.dev2.address, 0, 3), 0);

%% define bias and gate vector
Gate.startV = Gate.initV;          % V
Gate.voltage = linspace(Gate.minV, Gate.maxV, Gate.points); %Gate sweep
if  strcmp(Gate.sweep_dir, 'down')
    Gate.voltage = fliplr(Gate.voltage);
end
Gate.dV = abs(Gate.voltage(2) - Gate.voltage(1));

Timetrace.repeat = numel(Gate.voltage);

%% set lockin bias
fprintf('%s - Ramping up AC voltage bias...', datetime('now'))
ramp_lockin(Lockin.dev2, 0, Lockin.dev2.amplitude_rescaled, Lockin.dev2.ramp_rate_rescaled);
fprintf('done\n')

%% set bias voltage
fprintf('%s - Setting Vb = %1.2f...', datetime('now'), Bias.voltage )
Bias.setV = Bias.voltage;
Bias.startV = 0;

Bias = Apply_fixed_voltage(Settings, Bias);
fprintf('done\n')

%% reset arrays
Timetrace.runtime = 50 / Lockin.dev2.frequency;
Data.ADwin = cell(Timetrace.repeat, 1);
Data.MFLI_DAQ_AUX1 = cell(Timetrace.repeat, 1);
Data.MFLI_DAQ_AUX1_AV = cell(Timetrace.repeat, 1);
Data.MFLI_DAQ_Demod = cell(Timetrace.repeat, 1);
Data.MFLI_DAQ_X = cell(Timetrace.repeat, 1);
Data.MFLI_DAQ_Y = cell(Timetrace.repeat, 1);

Current.mean.ADwin = zeros(Gate.points, 1);
Current.mean.MFLI_DAQ_AUX1 = zeros(Gate.points, 1);
Current.mean.MFLI_DAQ_AUX1_AV = zeros(Gate.points, 1);
Current.mean.MFLI_DAQ_Demod = zeros(Gate.points, 1);
Current.mean.MFLI_DAQ_X = zeros(Gate.points, 1);
Current.mean.MFLI_DAQ_Y = zeros(Gate.points, 1);

Current.std.ADwin = zeros(Gate.points, 1);
Current.std.MFLI_DAQ_AUX1 = zeros(Gate.points, 1);
Current.std.MFLI_DAQ_AUX1_AV = zeros(Gate.points, 1);
Current.std.MFLI_DAQ_Demod = zeros(Gate.points, 1);
Current.std.MFLI_DAQ_X = zeros(Gate.points, 1);
Current.std.MFLI_DAQ_Y = zeros(Gate.points, 1);

%% figure
% figure(1);
% t = tiledlayout('flow');

figure(2);

%% Make Gate sweep
for j = 1:Timetrace.repeat

    %% set gate voltage
    %                     fprintf('%s - Setting Vg = %1.2f...', datetime('now'), Gate.voltage(j) )
    Gate.setV = Gate.voltage(i);
    Gate = Apply_fixed_voltage(Settings, Gate);
    %                     fprintf('done\n')

    %% autorange input
    if Lockin.dev1.autoranging && j == 1
        for k = 1:Timetrace.N_devices
            Lockin.(Lockin.device_names{k}).dev.autorange;
        end
    end

    %% wait for lockin
    if Lockin.dev1.autoranging && j == 1
        pause(max([Timetrace.wait_time 2])); % wait at least 2 second when autoranging ZI MFLI
    end

    %% run Timetrace ADwin
    Timetrace.model = 'ADwin';
    Timetrace.runtime = 50/Lockin.dev2.frequency;
    Timetrace = Run_timetrace(Settings, Timetrace);
    Timetrace = Get_data_timetrace(Settings, Timetrace);

    Data.ADwin{j} = [Timetrace.time.ADwin Timetrace.data.ADwin{1}];

    %% run Timetrace DAQ
    run = true;

    Timetrace.device_list = cell(1);
    for i= 1:Timetrace.N_devices
        Timetrace.device_list{i} = Lockin.(Lockin.device_names{i}).address;
    end

    while run
        try
            % Create a Data Acquisition Module instance, the return argument is a handle to the module
            Timetrace.daq = ziDAQ('dataAcquisitionModule');
            ziDAQ('set', Timetrace.daq, 'count', 1);
            ziDAQ('set', Timetrace.daq, 'endless', 0);
            grid_mode = 4;
            ziDAQ('set', Timetrace.daq, 'grid/mode', grid_mode);
            triggernode = sprintf('/%s/demods/0/sample.%s', Timetrace.device_list{1}, Timetrace.channels{1});
            ziDAQ('set', Timetrace.daq, 'triggernode', triggernode);

            % add hardware averaging
            for ii = 1:Timetrace.N_devices
                dev = Lockin.device_names{ii};
                Lockin.(dev).dev.set_auxin_averaging(1,1);
                Lockin.(dev).dev.set_auxin_averaging_samples(1,2^15);
            end

            % Subscribe to the demodulators
            ziDAQ('unsubscribe', Timetrace.daq, '*');
            for ii = 1:Timetrace.N_devices
                for jj = 1:Timetrace.N_channels
                    for ll = 1:4
                        ziDAQ('subscribe', Timetrace.daq, sprintf('/%s/demods/%01d/sample.%s', Timetrace.device_list{ii}, ll-1, Timetrace.channels{jj}));
                    end
                end
                ziDAQ('subscribe', Timetrace.daq, sprintf('/%s/auxins/0/values/0', Timetrace.device_list{ii}));
            end

            Timetrace.model = 'ZI_MFLI';

            % data points
            Timetrace.runtime_counts = floor(Timetrace.datarate * Timetrace.runtime);

            % set timetrace settings
            ziDAQ('set', Timetrace.daq, 'grid/cols', Timetrace.runtime_counts);
            ziDAQ('set', Timetrace.daq, 'duration', Timetrace.runtime);

            % run measurement
            ziDAQ('execute', Timetrace.daq);
            ziDAQ('set', Timetrace.daq, 'forcetrigger', 1);

            % run loop
            counter = 1;
            while ~ziDAQ('finished', Timetrace.daq)
                pause(0.001);
            end

            % get final current
            result = ziDAQ('read', Timetrace.daq);
            Data.MFLI_DAQ_AUX1{j} = [linspace(0, Timetrace.runtime, numel(result.dev6628.demods(1).sample_auxin0{1}.value))' result.dev6628.demods(1).sample_auxin0{1}.value' / Lockin.dev2.IVgain];
            Data.MFLI_DAQ_AUX1_AV{j} = [linspace(0, Timetrace.runtime, numel(result.dev6628.auxins.values.value{1}.value))' result.dev6628.auxins.values.value{1}.value' / Lockin.dev2.IVgain];
            Data.MFLI_DAQ_Demod{j} = [linspace(0, Timetrace.runtime, numel(result.dev6628.demods(2).sample_x{1}.value))' result.dev6628.demods(2).sample_x{1}.value' / Lockin.dev2.IVgain];
            Data.MFLI_DAQ_X{j} = [linspace(0, Timetrace.runtime, numel(result.dev6628.demods(1).sample_x{1}.value))' result.dev6628.demods(1).sample_x{1}.value' / Lockin.dev2.IVgain / (1e-3 * Lockin.dev2.amplitude_Vbias)];
            Data.MFLI_DAQ_Y{j} = [linspace(0, Timetrace.runtime, numel(result.dev6628.demods(1).sample_y{1}.value))' result.dev6628.demods(1).sample_y{1}.value' / Lockin.dev2.IVgain / (1e-3 * Lockin.dev2.amplitude_Vbias)];

            run = false;

        catch
            pause(5)
            clear ziDAQ
            ziDAQ('connect', 'localhost', 8004, 6);
            for i= 1:Timetrace.N_devices
                Lockin.dev = ZI_MFLI(Lockin.(Lockin.device_names{i}).address);
            end
        end
    end

    %% update plot timetraces
    %     figure(1)
    %     nexttile(t); hold on
    %     names = fieldnames(Data);
    %
    %     LEG = cell(numel(names),1);
    %     for i = 1:numel(names)
    %         LEG{i} = regexprep(names{i},'_','-');
    %     end
    %
    %     for i = 1:numel(names)
    %         plot(Data.(names{i}){j}(:,1), abs(Data.(names{i}){j}(:,2)))
    %         set(gca,'YScale','log')
    %     end
    %     if j == 1
    %         leg = legend(LEG);
    %     end

    %% get mean and std currents
    names = fieldnames(Data);
    LEG = cell(numel(names),1);
    for i = 1:numel(names)
        LEG{i} = regexprep(names{i},'_','-');
    end

    for i = 1:numel(names)
        tmp = Data.(names{i}){j}(:,2);
        t = Data.(names{i}){j}(:,1);
        tmp(isnan(tmp)) = [];
        tmp = lowpass(tmp,0.01,1/(t(2) - t(1)),ImpulseResponse="fir",Steepness=0.999);

        Current.mean.(names{i})(j) = mean(tmp);
%         Current.mean2.(names{i})(j) = mean(tmp2);
        Current.std.(names{i})(j) = std(tmp);
%         Current.std2.(names{i})(j) = std(tmp2);
    end

    %%
    figure(2);
    subplot(2,1,1);cla; hold on
    for i = 1:4
        plot(Gate.voltage(1:j), abs(Current.mean.(names{i})(1:j)))
    end
    leg = legend(LEG(1:4));

    subplot(2,1,2);cla; hold on
    for i = 5:numel(names)
        plot(Gate.voltage(1:j), abs(Current.mean.(names{i})(1:j)))
    end
    leg = legend(LEG(5:numel(names)));

    %% prepare new cycle
    Gate.startV = Gate.setV;
end


%% set gate voltage back to zero
Gate.startV = Gate.setV;
Gate.setV = 0;
Gate = Apply_fixed_voltage(Settings, Gate);

%% set bias voltage back to zero
Bias.startV = Bias.setV;
Bias.setV = 0;
Bias = Apply_fixed_voltage(Settings, Bias);

%% ramp down lockin bias
fprintf('%s - Ramping down AC voltage bias...', datetime('now'))
ramp_lockin(Lockin.dev2, Lockin.dev2.amplitude_rescaled, 0, Lockin.dev2.ramp_rate_rescaled);
fprintf('done\n')

%% plot histogram mean and std
color = lines(6);

figure(3); clf
set(gcf,'color','white')
for ii = 1:numel(names)
    subplot(2,6,ii); hold on
    set(gca,'Box','on','fontsize',12)
    h = histogram(abs(Current.mean.(names{ii})), 101,'FaceColor',color(ii,:));
    p = fit((h.BinEdges(1:end-1) + h.BinWidth/2)', h.Values', 'gauss1');
    X = linspace(h.BinLimits(1), h.BinLimits(2), 201);
    plot(X,p(X),'color','k','LineWidth',2)
    legend(regexprep(names{ii},'_','-'), sprintf('\\mu=%1.2e, \\sigma=%1.2e',p.b1,p.c1));
    xlabel('\mu')
    ylabel('Counts')
end

figure(3);
for ii = 1:numel(names)
    subplot(2,6,ii+6); hold on
    set(gca,'Box','on','fontsize',12)
    h = histogram(abs(Current.std.(names{ii})), 101,'FaceColor',color(ii,:));
    p = fit((h.BinEdges(1:end-1) + h.BinWidth/2)', h.Values', 'gauss1');
    X = linspace(h.BinLimits(1), h.BinLimits(2), 201);
    plot(X,p(X),'color','k','LineWidth',2)
    legend(regexprep(names{ii},'_','-'), sprintf('\\mu=%1.2e, \\sigma=%1.2e',p.b1,p.c1));
        xlabel('\sigma')
    ylabel('Counts')
end

filename = sprintf('%s/%s_%s_%s', Settings.save_dir, Settings.filename, Settings.sample, Settings.type);

saveas(figure(3), [filename '_histograms.png'])
saveas(figure(3), [filename '_histograms.fig'])

%% save data
Save_data(Settings, Timetrace, Bias, Gate, Lockin, Current, Data, [filename '.mat']);

%% save figure
% saveas(figure(1), [filename '_traces.png'])
% saveas(figure(1), [filename '_traces.fig'])
saveas(figure(2), [filename '_mean.png'])
saveas(figure(2), [filename '_mean.fig'])
