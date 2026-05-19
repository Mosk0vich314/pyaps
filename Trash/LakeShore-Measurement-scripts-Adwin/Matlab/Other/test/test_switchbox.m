%% clear
clear
clc
close all

%% settings
Settings.switchbox.clock_bit = 11;
Settings.switchbox.latch_bit = 10;
Settings.switchbox.data_bit = 9;
Settings.switchbox.disable_bit = 8;
Settings.N_switches = 16;
Settings.coils_per_switch = 2;
Settings.N_coils = Settings.N_switches * Settings.coils_per_switch;
Settings.type = 'Switching';
Settings.get_sample_T = 0;
Settings.save_dir = '';
Settings.switch_frequency = 500;

Switches.process = 'control_switches';
Switches.process_number = 5;

switches = 1:Settings.N_switches;
states =   zeros(1,Settings.N_switches);
% states =   ones(1,Settings.N_switches);

% states =  [0 0 0 0 0 0 1 0 1 0 0  0  1  1  0  0]; % hard ground
% states =  [0 0 0 0 0 0 0 0 1 0 0  0  1  1  0  0]; % soft ground
% states =   [0 0 0 0 0 0 1 0 1 0 0  0  1  1  0  1]; % heater 1
% states =   [0 0 0 0 0 0 1 0 1 0 0  0  1  1  1  0]; % heater 2
% states =   [0 0 0 0 0 0 1 0 1 0 0  0  1  1  1  1]; % heater 1 & 2
% states =   [0 0 0 0 0 0 1 1 1 1 1  1  1  1  1  1]; % mesure temperature while applying heaters
%states =  [0 0 0 0 0 1 1 1 0 0 0  0  1  1  1  1]; % measure I-V`s of graphene while applying heaters (I1RA & I2RA)
% states =  [0 0 0 0 1 1 1 1 0 0 0  0  1  1  1  1]; % measure thermovoltage while applying heaters (I1RA & I2RA)

%%
Settings = Init(Settings, Switches);
Set_Par(43, Settings.switchbox.clock_bit);
Set_Par(44, Settings.switchbox.latch_bit);
Set_Par(45, Settings.switchbox.data_bit);
Set_Par(46, Settings.switchbox.disable_bit);

Set_Par(47, 0); % clock
Set_Par(48, 1); % latch
Set_Par(49, 0); % data
Set_Par(50, 1); % disable

%% run
Start_Process(Switches.process_number);
Set_Processdelay(Switches.process_number, 1000);
for i = 1:Settings.N_switches
    control_switches(Settings, switches(i), states(i));
end
Stop_Process(5);