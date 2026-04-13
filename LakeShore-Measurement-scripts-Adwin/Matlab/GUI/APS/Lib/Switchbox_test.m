%% clear
clear
close all hidden
clc
tic

%% Settings
Settings.ADwin = 'GoldII'; % GoldII or ProII
Switch.bit = 11;
Switch.process = 'Single_DO';

%% add path
idx = regexp(pwd,'(Matlab\\)');
tmp = pwd;
addpath(genpath([tmp(1:idx-1) 'Matlab\Libs\']));
Settings.path = [tmp(1:idx-1) 'Matlab\Libs\ADwin_script'];
addpath(genpath(Settings.path));

%% Initialize ADwin and piezo

Settings = Init_ADwin(Settings, Switch);
Set_Processdelay(5, 100000);
Set_Par(50, Switch.bit); 

Start_Process(5);
Set_Par(51, 0);
Set_Par(51, 1);
pause(0.01)
Set_Par(51, 0); 
Stop_Process(5);
