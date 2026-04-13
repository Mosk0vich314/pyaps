function Timetrace = Init_lockin_ZI_DAQ(Timetrace, Lockin)

%% find demodulators and harmonics to use
Timetrace.N_demods = [];
Timetrace.N_harmonics = cell(0);
Timetrace.datarate = Lockin.dev1.datarate;

for i = 1:Timetrace.N_devices
    Timetrace.N_demods = [Timetrace.N_demods Lockin.(Lockin.device_names{i}).N_demods];
    Timetrace.N_harmonics{i} = Lockin.(Lockin.device_names{i}).harmonic;
end

%% check for high speed option
if ~isfield(Timetrace,'high_speed')
    Timetrace.high_speed = 0;
end

%% create device list
Timetrace.device_list = cell(1);
for i= 1:Timetrace.N_devices
    Timetrace.device_list{i} = Lockin.(Lockin.device_names{i}).address;
end

switch Timetrace.high_speed
    case 0

        % Create a Data Acquisition Module instance, the return argument is a handle to the module
        Timetrace.daq = ziDAQ('dataAcquisitionModule');
        ziDAQ('set', Timetrace.daq, 'count', 1);
        ziDAQ('set', Timetrace.daq, 'endless', 0);

        %% set grid mode
        % 'grid/mode' - Specify the interpolation method of
        %   the returned data samples.
        %
        % 1 = Nearest. If the interval between samples on the grid does not match
        %     the interval between samples sent from the device exactly, the nearest
        %     sample (in time) is taken.
        %
        % 2 = Linear interpolation. If the interval between samples on the grid does
        %     not match the interval between samples sent from the device exactly,
        %     linear interpolation is performed between the two neighbouring
        %     samples.
        %
        % 4 = Exact. The subscribed signal with the highest sampling rate (as sent
        %     from the device) defines the interval between samples on the DAQ
        %     Module's grid. If multiple signals are subscribed, these are
        %     interpolated onto the grid (defined by the signal with the highest
        %     rate, "highest_rate"). In this mode, duration is
        %     read-only and is defined as num_cols/highest_rate.
        grid_mode = 4;
        ziDAQ('set', Timetrace.daq, 'grid/mode', grid_mode);

        %% set trigger type
        %   type:
        %     NO_TRIGGER = 0
        %     EDGE_TRIGGER = 1
        %     DIGITAL_TRIGGER = 2
        %     PULSE_TRIGGER = 3
        %     TRACKING_TRIGGER = 4
        %     HW_TRIGGER = 6
        %     TRACKING_PULSE_TRIGGER = 7
        %     EVENT_COUNT_TRIGGER = 8
        % ziDAQ('set', daq, 'type', 1);
        %   triggernode, specify the triggernode to trigger on.
        %     SAMPLE.X = Demodulator X value
        %     SAMPLE.Y = Demodulator Y value
        %     SAMPLE.R = Demodulator Magnitude
        %     SAMPLE.THETA = Demodulator Phase
        %     SAMPLE.AUXIN0 = Auxilliary input 1 value
        %     SAMPLE.AUXIN1 = Auxilliary input 2 value
        %     SAMPLE.DIO = Digital I/O value
        triggernode = sprintf('/%s/demods/0/sample.%s', Timetrace.device_list{1}, Timetrace.channels{1});
        ziDAQ('set', Timetrace.daq, 'triggernode', triggernode);

        %   edge:
        %     POS_EDGE = 1
        %     NEG_EDGE = 2
        %     BOTH_EDGE = 3
        % ziDAQ('set', daq, 'edge', 1)

        %% Subscribe to the demodulators
        ziDAQ('unsubscribe', Timetrace.daq, '*');
        for i = 1:Timetrace.N_devices
            for j = 1:Timetrace.N_channels
                for k = 1:Timetrace.N_demods(i)
                    ziDAQ('subscribe', Timetrace.daq, sprintf('/%s/demods/%01d/sample.%s', Timetrace.device_list{i}, k-1, Timetrace.channels{j}));
                end
            end
        end

    case 1
        ziDAQ('unsubscribe', '*');
        for i = 1:Timetrace.N_devices
            for k = 1:Timetrace.N_demods(i)
                ziDAQ('subscribe', sprintf('/%s/demods/%01d/sample', Timetrace.device_list{i}, k-1));
            end
        end
end