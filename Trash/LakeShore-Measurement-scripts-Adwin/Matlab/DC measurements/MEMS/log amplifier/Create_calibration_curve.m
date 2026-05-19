%% clear
clear
close all hidden
clc

%% load data
load('E:\Samples\Mickael\log_amp_calibration\2025-10-20_run36_Calibration_1.25V_IV_.mat');
filename = 'Curve_20_10_2025_1.25V';

R = Switchbox.resistance_values;
numR = numel(R);

%% settings
threshold = 3e-2; % upper current threshold
voltage_division = 8; % only 1.25V range is used!

%% split IV and average
IV = split_data_sweep(Settings, IV);
data = (IV.data1{1} + IV.data2{1})/2;
[NumBias, ~] = size(data);

%% split pos and neg voltages
data_pos = data(ceil(NumBias/2)+1:end,:);
data_neg = data(1:ceil(NumBias/2)-1,:);

Bias_pos = IV.Bias1(ceil(NumBias/2)+1:end);
Bias_neg = IV.Bias1(1:ceil(NumBias/2)-1);

%% init arrays
bins = zeros(size(data));
bin_array = 1:2^Settings.input_resolution;

Voltages = linspace(-10, 9.99969, 2^Settings.input_resolution)'/ voltage_division; 
data_all_voltage = zeros(2^Settings.input_resolution, numR);

%% plot output voltage
fig = figure;
fig.WindowState = 'maximized';
set(gcf,'color','white')
t = tiledlayout('horizontal');
nexttile(t);
plot(IV.Bias1, data,'linewidth',2)
title('Raw data')
xlabel('Applied bias voltage (V)')
ylabel('Measured voltage (V)')
set(gca,'linewidth',2, 'fontsize', 16)
set(gca,'box','on')

%% plot voltage versus expected current
nexttile(t);
hold on;set(gca,'YScale','log')
for i = 1:numR
    plot(data(:,i), abs(IV.Bias1 / R(i)),'linewidth',2)
end

title('Current vs measured voltage')
xlabel('Measured voltage (V)')
ylabel('Current (A)')
set(gca,'linewidth',2, 'fontsize', 16)
set(gca,'box','on')

%% convert mesured voltage to bin
nexttile(t);
hold on;set(gca,'YScale','log')
for i = 1:numR
    i
    bins(:,i) = convert_V_to_bin(data(:,i), Settings.output_min / voltage_division, Settings.output_max / voltage_division, Settings.input_resolution);
    plot(bins(:,i), abs(IV.Bias1 / R(i)),'linewidth',2)
end

title('Current vs ADC bin number ')
xlabel('ADC bin number')
set(gca,'linewidth',2, 'fontsize', 16)
set(gca,'box','on')

%% interpolate voltage, split pos and neg bias, clean up data to make unique, smooth
nexttile(t);
hold on;set(gca,'YScale','log')

for i = 1:numR

    i

    % find voltage range
    minV = min(data_pos(:,i));
    maxV = max(data_pos(:,i));

    idx_minV_all = find(min(abs(minV - Voltages)) == abs(minV - Voltages));
    idx_maxV_all = find(min(abs(maxV - Voltages)) == abs(maxV - Voltages));

    % remove data above threshold
    tmp = abs(Bias_pos / R(i));
    idx_to_keep = (tmp < threshold);
    data_V = data_pos(idx_to_keep, i);
    data_I = abs(Bias_pos(idx_to_keep) / R(i));

    % get unique points
    [data_V, idx, ~] = unique(data_V);
    data_I = data_I(idx);

    % interpolate pos voltages
    data_all_voltage(idx_minV_all:idx_maxV_all, i) = interp1(data_V, data_I , Voltages(idx_minV_all:idx_maxV_all)');

    % find voltage range
    minV = min(data_neg(:,i));
    maxV = max(data_neg(:,i));

    idx_minV_all = find(min(abs(minV - Voltages)) == abs(minV - Voltages));
    idx_maxV_all = find(min(abs(maxV - Voltages)) == abs(maxV - Voltages));

     % remove data above threshold
    tmp = abs(Bias_neg / R(i));
    idx_to_keep = (tmp < threshold);
    data_V = data_neg(idx_to_keep, i);
    data_I = abs(Bias_neg(idx_to_keep) / R(i));

    % get unique points
    [data_V, idx, ~] = unique(data_V);
    data_I = data_I(idx);

    % interpolate neg voltages
    data_all_voltage(idx_minV_all:idx_maxV_all, i) = interp1(data_V, data_I , Voltages(idx_minV_all:idx_maxV_all)');
   
    % make plot
    plot(bin_array, data_all_voltage(:,i),'linewidth',2)
end

title('Interp. current - all data ')
xlabel('ADC bin number')
set(gca,'linewidth',2, 'fontsize', 16)
set(gca,'box','on')

%% go through all bins, use only nonzeros voltages, then take only last appearing point, i.e. for the highest available resistance, that should the most accurate one
nexttile(t);
hold on;
set(gca,'YScale','log')

data_all_voltage_single = zeros(size(Voltages));

for i = 1:2^Settings.input_resolution
    tmp = nonzeros(data_all_voltage(i,:));
    if ~isempty(tmp)
        data_all_voltage_single(i) = tmp(end);
    end
end

plot(bin_array, data_all_voltage_single,'.','MarkerSize',24);
title('Interp. current - best data ')
xlabel('ADC bin number')
set(gca,'linewidth',2, 'fontsize', 16)
set(gca,'box','on')

%% smoothing
data_all_voltage_single_smooth = smooth(data_all_voltage_single, 100, 'moving');

%% remove NaN
data_all_voltage_single_smooth(isnan(data_all_voltage_single_smooth)) = 0;

%% make plot of smoothed data
plot(bin_array, data_all_voltage_single_smooth,'linewidth',2);

%% export calibration curve
Calibration = data_all_voltage_single_smooth;
save(sprintf('Calibration_curves/%s.mat',filename),'Voltages','Calibration','bin_array')
saveas(fig, sprintf('Calibration_curves/%s.fig',filename))
saveas(fig, sprintf('Calibration_curves/%s.png',filename))
