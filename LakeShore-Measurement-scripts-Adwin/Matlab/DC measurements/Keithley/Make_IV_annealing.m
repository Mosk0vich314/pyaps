%% clear
clear
clc
close all

%% clear
Settings.save_dir = 'C:\Samples\Fred\CNTTEP2\1112b\annealingR1';
Settings.sample = 'test'; %A2-GatetoGate G0b Test_100MOhm_50ohm_termination

%% init device
Dev = Keithley2450('USB0::0x05E6::0x2450::04431514::INSTR');

%% set measurements
Settings.measurementMode = 'IV';
Settings.currentCompliance = 0.2e-6;
Settings.IVmax = 0.5;
Settings.IVpoints = 10;

Dev.set_PLC(1);

Dev.set_mode_combi(Settings.measurementMode);
Dev.set_current_limit_IVmode(Settings.currentCompliance);

VoltageUp = linspace(0, Settings.IVmax, Settings.IVpoints);
VoltageDown = linspace(Settings.IVmax, 0, Settings.IVpoints);
Voltage = [VoltageUp VoltageDown(2:end)];
Current = zeros(size(Voltage));
Settings.averagingDatapoints = 1;

%% init figure
fig = figure; % create a figure
set(gcf, 'color','white')
cmap = lines;
line_plot = animatedline('LineWidth',2, 'Color', cmap(1,:));
xlabel('Voltage (V)')
ylabel('Current (A)')
set(gca,'Box','on','FontSize',16)

%% run measurement
Dev.set_output('ON');
for i = 1:numel(Voltage)
    Dev.set_voltage_source(Voltage(i))
    
    pause(0.005)
    [time, data] = Dev.read_array(Settings.averagingDatapoints, 0);
    Current(i) = mean(data);
    addpoints(line_plot, Voltage(i), Current(i))
end
Dev.set_output('OFF');

%% save plot
Settings.runname = make_filename;

if ~exist(Settings.save_dir)
    mkdir(Settings.save_dir)
end
saveas(fig, sprintf('%s/%s_%s_annealing.fig', Settings.save_dir, Settings.sample, Settings.runname))
saveas(fig, sprintf('%s/%s_%s_annealing.png', Settings.save_dir, Settings.sample, Settings.runname))

%% save data
save(sprintf('%s/%s_%s_annealing.mat', Settings.save_dir, Settings.sample, Settings.runname),'Current','Voltage','Settings')