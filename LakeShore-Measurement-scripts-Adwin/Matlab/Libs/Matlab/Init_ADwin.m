function Settings = Init_ADwin(varargin)

Settings = varargin{1};

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

%% ADwin load processes
AO_24bit_Loaded = 0;
i = 2;
while i <=nargin
    structure = varargin{i};

    %% set process number
    if regexp(structure.process,'Sweep_AO')
        structure.process_number = 1;
    elseif regexp(structure.process,'Read_AI')
        structure.process_number = 2;
    elseif regexp(structure.process,'Fixed_AO')
        structure.process_number = 3;
    elseif regexp(structure.process,'Single_DO')
        structure.process_number = 5;
    elseif regexp(structure.process,'Waveform_AO')
        structure.process_number = 6; 
    elseif regexp(structure.process,'MCBJ')
        structure.process_number = 7;

        %% check if 24bit AO is needed
        if isfield(structure,'dV') && ~AO_24bit_Loaded
            if structure.dV < 1 * (2*Settings.input_range / 2 ^ Settings.output_resolution)  % check for 24 bit output
                structure.process = 'Fixed_AO_24bit';
                structure.process_number = 4;
                AO_24bit_Loaded = 1;
                i = i-1;
            end
        end

    else
        disp('Unknown process')
    end

    %% ADwin load processes
    switch Settings.ADwin
        case 'GoldII'
            Load_Process(regexprep(sprintf('%s/%s/%s_%s.TB%1.0f', Settings.path,  Settings.ADwin, structure.process, Settings.ADwin, structure.process_number),'\','/'));
            fprintf('%s/%s/%s_%s.TB%1.0f \n', Settings.path,  Settings.ADwin, structure.process, Settings.ADwin, structure.process_number);
        case 'ProII'
            Load_Process(regexprep(sprintf('%s/%s/%s_%s.TC%1.0f', Settings.path,  Settings.ADwin, structure.process, Settings.ADwin, structure.process_number),'\','/'));
            fprintf('%s/%s/%s_%s.TC%1.0f \n', Settings.path,  Settings.ADwin, structure.process, Settings.ADwin, structure.process_number);
    end
    i = i + 1;

end
disp('Boot successful')

return
