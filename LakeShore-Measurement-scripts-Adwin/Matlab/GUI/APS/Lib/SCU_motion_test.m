clear
clc
close all

Motor = SCU;
%% test x
Motor.setFrequency(1000)
Motor.move_x(100)
%% test y
Motor.setFrequency(100)
Motor.move_y(100)
% move_x(100);
%% test theta
Motor.setFrequency(1000)
Motor.move_theta(100)
%% test l pin
Motor.move_leftProbe(-100)
%% test r pin
Motor.move_rightProbe(100)

