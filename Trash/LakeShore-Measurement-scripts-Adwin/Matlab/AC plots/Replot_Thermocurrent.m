clc
close all
clear all
load('E:\Samples\TEP_Dev_V2_CH2\Posttransfer_S558\RT\TEP_Stability\2020-07-15_run31_E1t_Stability_2.00mA.mat')
Figurename = 'Heatercurrent_2mA';
Figurename_2 = 'Heatercurrent_2mA';
IV.clim.IV = [-5e-9 5e-9];
IV.clim.dIdV_numeric = [0 10e-9];
IV.clim.dIdV_lockin = [0 10e-9];
IV.clim.Thermovoltage =  [-10e-3 10e-3];
IV.clim.Thermovoltage_RR = [0 10e-3];
IV.clim.Thermocurrent =  [-5e-11 5e-11];
IV.clim.Gateleakage =  [-5e-12 5e-12];

Thermocurrent_conductance3D(Settings, IV, Lockin1, Lockin2, Figurename);
fig = findobj('Name', Figurename);

saveas(fig, sprintf('%s/%s_%s_%s_%s_%s.png', Settings.save_dir, Settings.filename, Settings.sample{1}, Settings.type, Gate.sweep_dir, Figurename))

%Thermocurrent_Gateleakage(Settings, IV, Lockin1, Lockin2, Figurename_2);
%fig = findobj('Name', Figurename_2);
%saveas(fig, sprintf('%s/%s_%s_%s_%s_%s_Gateleakage.png', Settings.save_dir, Settings.filename, Settings.sample{1}, Settings.type, Gate.sweep_dir, Figurename_2))

