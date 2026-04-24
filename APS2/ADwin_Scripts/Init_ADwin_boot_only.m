function Settings = Init_ADwin_boot_only(Settings)
    % Init_ADwin_boot_only - Sets up ADwin parameters and boots the processor.
    %
    % Usage: Settings = Init_ADwin_boot_only(Settings)
    %
    % Inputs:
    %   Settings - Structure with 'ADwin' type (e.g., 'GoldII', 'ProII')
    
    %% ADC/DAC settings
    Settings.input_resolution = 18;      % bits
    Settings.output_resolution = 16;     % bits
    Settings.output_min = -10;           % AO1 output range (V)
    Settings.output_max = 9.99969;       % AO1 output range (V)
    Settings.input_range = 10;           % AI input range (V)
    Settings.AI_address = 1;
    Settings.AO_address = 2;
    Settings.DIO_address = 3;

    %% Set clock frequency
    switch Settings.ADwin
        case 'GoldII'
            Settings.clockfrequency = 0.3e9;  % 300 MHz
        case 'ProII'
            Settings.clockfrequency = 1e9;    % 1 GHz
        otherwise
            warning('Unknown ADwin type: %s. Defaulting to GoldII freq.', Settings.ADwin);
            Settings.clockfrequency = 0.3e9;
    end

    %% Boot ADwin if needed
    try
        % Processor_Type is a global ADwin driver function
        Type = Processor_Type;
    catch
        Type = 0; % Assume not booted if function fails
    end

    try
        if Type == 0
            if contains(Settings.ADwin, 'ProII')
                Boot('C:\ADwin\ADwin12.btl', 2000000);
            elseif contains(Settings.ADwin, 'GoldII')
                Boot('C:/ADwin/ADwin11.btl', 2000000);
            end
            disp('ADwin booted successfully.');
        else
            disp('ADwin already booted.');
        end
    catch ME
        warning('ADwin Boot Error: %s', ME.message);
    end
end