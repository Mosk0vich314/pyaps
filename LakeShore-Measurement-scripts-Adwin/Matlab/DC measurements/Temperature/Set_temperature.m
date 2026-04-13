%% clear
clear
close all hidden
clc
instrreset

%% Settings
Temperature = 250;      %K

%% load Lakeshore
Settings.T_controller = Temperature_controller_Settings.T_controller336('COM4');

Settings.T_controller.set_T_setpoint(1, Temperature);
%%Lakeshore.set_heater_off(1);