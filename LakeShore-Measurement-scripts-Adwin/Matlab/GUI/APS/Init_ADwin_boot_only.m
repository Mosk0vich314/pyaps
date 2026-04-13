function Settings = Init_ADwin_boot_only(Settings)

%% ADC/DAC settings
Settings.input_resolution = 18;     % bits
Settings.output_resolution = 16;     % bits
Settings.output_min = -10;       %  AO1 output range
Settings.output_max = 9.99969;       %  AO1 output range
Settings.input_range = 10;       %  AO1 output range
Settings.AI_address = 1;
Settings.AO_address = 2;
Settings.DIO_address = 3;

%% set clock frequency
switch Settings.ADwin
    case 'GoldII'
        Settings.clockfrequency = 0.3e9;                                   % ADwin frequency
    case 'ProII'
        Settings.clockfrequency = 1e9;                                   % ADwin frequency
end

%% ADwin boot ADwin if needed
try
    Type = Processor_Type;
catch
    Type = 0;
end

try
if Type == 0
    if regexp(Settings.ADwin,'ProII')
        Boot('C:\ADwin\ADwin12.btl',2000000);
    end
    if regexp(Settings.ADwin,'GoldII')
        Boot('C:/ADwin/ADwin11.btl',2000000);
    end
    disp('ADwin booted')

else
    disp('ADwin already booted')
end
catch ME
    if regexp(ME.identifier,'calllib') ~= 0
        errordlg('Install MinGW C compiler and reboot PC')
    end
end

%% ADwin clear all processes
for i = 1:10
    Stop_Process(i);
    Clear_Process(i);
end

return
