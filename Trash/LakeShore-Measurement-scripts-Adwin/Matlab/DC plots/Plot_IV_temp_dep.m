%% clear
clear
close all
clc

%% settings
filepath = 'E:\Samples\hBN_Stack01_9AGNR\Post_3rd\9K\IV';
filename1 = '2019-10-18_run';
filename2 = '20-16_0Vg_Tdep_IVs';
runs = 21:50;

%%  importdata
load(sprintf('%s/%s%1.0f_%s.mat',filepath,filename1,runs(1),filename2))
IV = split_data_sweep(Settings, IV);

Current1 = zeros(length(IV.Bias1), length(runs));
Current2 = zeros(length(IV.Bias1), length(runs));
T = zeros(length(runs), 1);
LEG = cell(length(runs), 1);

for i = 1:length(runs)
    load(sprintf('%s/%s%1.0f_%s.mat',filepath,filename1,runs(i),filename2))
    IV = split_data_sweep(Settings, IV);
    Current1(:,i) = IV.data1{1};
    Current2(:,i) = IV.data2{1};
    T(i) = Settings.T_sample;
    LEG{i} = sprintf('%1.0f K', T(i));
end

Current = (Current1 + Current2) / 2;

%% linear plot
fig = figure;
set(gcf,'units','normalized')
set(fig, 'Position', Settings.plot_position)

subplot(1,2,1); cla; hold on
for i=1:length(runs)
    plot(IV.Bias1, Current(:, i),'LineWidth',1.5)
end
set(gca,'Fontsize',20,'box','on')
set(gcf,'color','white','Inverthardcopy','off')
leg = legend(LEG);
set(leg,'box','off','fontsize',12)
xlabel('Bias voltage (V)')
ylabel('Current (A)')
set(gca,'xlim',[IV.minV IV.maxV])

%% log plot
subplot(1,2,2); cla; hold on
for i=1:length(runs)
    plot(IV.Bias1, abs(Current(:, i)),'LineWidth',1.5)
end
set(gca,'yscale','log')
set(gca,'Fontsize',20,'box','on')
set(gcf,'color','white','Inverthardcopy','off')
leg = legend(LEG);
set(leg,'box','off','fontsize',12)
xlabel('Bias voltage (V)')
ylabel('Current (A)')
set(gca,'xlim',[IV.minV IV.maxV])

saveas(fig, sprintf('%s/%s_%s.png',filepath,filename1,filename2))

%% arrhenius plot
arrhenius = abs(Current(end, :));
fig = figure; hold on
plot(1./T, log10(arrhenius),'LineWidth',1.5)
set(gca,'Fontsize',20,'box','on')
set(gcf,'color','white','Inverthardcopy','off')
xlabel('1/T (1/K)')
ylabel('log_{10}(I)')
% set(gca,'xlim',[IV.minV IV.maxV])

saveas(fig, sprintf('%s/%s_%s_arrhenius.png',filepath,filename1,filename2))