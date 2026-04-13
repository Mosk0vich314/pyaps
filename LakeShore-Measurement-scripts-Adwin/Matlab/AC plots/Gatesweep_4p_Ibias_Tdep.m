%% clear
clear
clc
close all

%% settings
filepath = 'E:\Samples\20220627_Suspended_TBG_sample1\255mK\Gatesweep_Ibias_AC1nA_Tdep_20220629';
sample_name = '';
smoothing_window = 20;

%% get files
list = dir([filepath '/*.mat']);
numT = numel(list);

%% Initialize
Temperature = zeros(numT, 1);
Data = load(sprintf('%s/%s', list(1).folder, list(1).name));

Gate = Data.Gate.bias;

idx_max = find(min(abs(Data.Gate.bias_new - Data.Gate.maxV)) == abs(Data.Gate.bias_new - Data.Gate.maxV));
idx_min = find(min(abs(Data.Gate.bias_new - Data.Gate.minV)) == abs(Data.Gate.bias_new - Data.Gate.minV));

Bias = flipud(Data.Gate.bias_new(idx_max(end):idx_min(1)));
Bias_der = linspace(Bias(1), Bias(end), numel(Bias)-1);
numBias = numel(Bias);

Resistance = zeros(numBias, numT);
Derivative = zeros(numBias-1, numT);
Legend = cell(numT, 1);

%% load data
for i = 1:numT
    Data = load(sprintf('%s/%s', list(i).folder, list(i).name));

    %% get temperature
    Temperature(i) = Data.Settings.T_sample;

    %% get mean current
    Data.Gate.current = Data.Gate.resistance;
    Data.Gate = split_data_sweep(Data.Settings, Data.Gate);
    Resistance(:,i) = Data.Gate.data1{1};

    %% set legend
    Legend{i} = sprintf('%1.2f K', Temperature(i));

end

%% sort data
[Temperature, idx] = sort(Temperature);
Resistance = Resistance(:,idx);
Legend = Legend(idx);

%% plot IVs
fig = figure; hold on
set(gcf,'color','white')
cmap = viridis(numT);

for i = 1:numT
    plot(Bias, Resistance(:,i),'linewidth',1.5,'color',cmap(i,:));
end

set(gca,'box','on','fontsize',16,'LineWidth',2)
set(gca,'xcolor','black')
set(gca,'ycolor','black')
set(gca,'xlim',[Bias(1) Bias(end)])

set(gca,'clim',[Temperature(1) Temperature(end)])
colormap(viridis)
cbar = colorbar;
cbar.Label.String = 'Temperature (K)';
set(cbar,'color','black')

mkdir(sprintf('%s/%s', filepath, sample_name));
saveas(fig, sprintf('%s/%s/Resistance.eps', filepath, sample_name),'psc2')
xlabel('Gate voltage (V)')
ylabel('Resistance (\Omega)')
saveas(fig, sprintf('%s/%s/Resistance.png', filepath, sample_name))
saveas(fig, sprintf('%s/%s/Resistance.fig', filepath, sample_name))

%% Plot IVs 3D
fig = figure; hold on
set(gcf,'color','white')

imagesc(Bias, Temperature, Resistance');

set(gca,'box','on','fontsize',16,'LineWidth',2)
set(gca,'xcolor','black')
set(gca,'ycolor','black')
set(gca,'xlim',[Bias(1) Bias(end)])
set(gca,'ylim',[Temperature(1) Temperature(end)])

% set(gca,'clim',[10 300])
colormap(inferno(256))
cbar = colorbar('location','eastoutside');
set(cbar,'color','black')

mkdir(sprintf('%s/%s', filepath, sample_name));
saveas(fig, sprintf('%s/%s/Resistance_3D.eps', filepath, sample_name),'psc2')
xlabel('Gate voltage (V)')
ylabel('Temperature (K)')
cbar.Label.String = 'Resistance (\Omega)';
saveas(fig, sprintf('%s/%s/Resistance_3D.png', filepath, sample_name))
saveas(fig, sprintf('%s/%s/Resistance_3D.fig', filepath, sample_name))
