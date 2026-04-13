function Settings = set_switchbox(Settings)

measurement_type = Settings.switchbox.state;

%% load process
Settings.switchbox.process_number = 5;
Settings.switchbox.process = 'control_switches';

if regexp(Settings.ADwin,'ProII')
    Load_Process(sprintf('%s/%s_%s.TC%1.0f', Settings.path, Settings.switchbox.process, Settings.ADwin, Settings.switchbox.process_number));
end
if regexp(Settings.ADwin,'GoldII')
    Load_Process(sprintf('%s/%s_%s.TC%1.0f', Settings.path, Settings.switchbox.process, Settings.ADwin, Settings.switchbox.process_number));
end

%%
check = 1;

if strcmp(measurement_type,'GND')
    Settings.switchbox.states =   [0 0 0 0 0 0 1 0 1  0  0  0  1  1  0  0];
    
elseif strcmp(measurement_type,'GND-1k')
    Settings.switchbox.states =   [0 0 0 0 0 0 0 0 1  0  0  0  1  1  0  0];
    
elseif strcmp(measurement_type,'2T-H12')
    Settings.switchbox.states =   [0 0 0 0 0 0 1 1 1  1  1  1  1  1  1  1];
    
elseif strcmp(measurement_type,'2T-H1')
    Settings.switchbox.states =   [0 0 0 0 0 0 1 1 1  1  1  1  1  1  0  1];
    
elseif strcmp(measurement_type,'2T-H2')
    Settings.switchbox.states =   [0 0 0 0 0 0 1 1 1  1  1  1  1  1  1  0];
    
elseif strcmp(measurement_type,'2T')
    Settings.switchbox.states =   [0 0 0 0 0 0 1 1 1  1  1  1  1  1  0  0];
    
elseif strcmp(measurement_type,'H1')
    Settings.switchbox.states =   [0 0 0 0 0 0 1 0 1  0  0  0  1  1  0  1];
    
elseif strcmp(measurement_type,'H2')
    Settings.switchbox.states =   [0 0 0 0 0 0 1 0 1  0  0  0  1  1  1  0];
    
elseif strcmp(measurement_type,'H12')
    Settings.switchbox.states =   [0 0 0 0 0 0 1 0 1  0  0  0  1  1  1  1];
    
elseif strcmp(measurement_type,'TEP')
    Settings.switchbox.states =   [0 0 0 0 1 1 1 1 0  0  0  0  1  1  1  1];
    
elseif strcmp(measurement_type,'IV')
    Settings.switchbox.states =   [0 0 0 0 0 1 1 1 0  0  0  0  1  1  0  0];
    
elseif strcmp(measurement_type,'IV-H')
    Settings.switchbox.states =   [0 0 0 0 0 1 1 1 0  0  0  0  1  1  1  1];
    
else
    fprintf('Command not found\n')
    check = 0;
end

Settings.switchbox.switches = [1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16];

if check == 1
    control_switches(Settings);
    fprintf('Switchbox set to %s\n', measurement_type);
end

%% unload process
Clear_Process(Settings.switchbox.process_number);

return
