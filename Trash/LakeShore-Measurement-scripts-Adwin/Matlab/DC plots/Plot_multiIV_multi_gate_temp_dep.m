%% clear
clear
close all
clc

%% settings
filepath = 'E:\Samples\ANL_EB_03\9AGNR\RTannealed\multiIV_multiVg';
filename = '2019-12-10_run14_AR1_IVs';
T = 300:-20:200;

%%  importdata
load(sprintf('%s/%s_%1.0fK.mat', filepath, filename, T(1)))
IV = split_data_sweep(Settings, IV);

[IV.NumBias_split, ~] = size(IV.data1{1});

Current1 = zeros(IV.NumBias_split, Gate.numGate * IV.N_per_gate, Settings.nT);
Current2 = zeros(IV.NumBias_split, Gate.numGate * IV.N_per_gate, Settings.nT);
Current3 = zeros(IV.NumBias_split, Gate.numGate * IV.N_per_gate, Settings.nT);
Current4 = zeros(IV.NumBias_split, Gate.numGate * IV.N_per_gate, Settings.nT);
T_LEG = cell(Settings.nT, 1);

for i = 1:Settings.nT
    try
        load(sprintf('%s/%s_%1.0fK.mat', filepath, filename, T(i)))
        IV = split_data_sweep(Settings, IV);
        Current1(:,:,i) = IV.data1{1};
        Current2(:,:,i) = IV.data2{1};
        Current3(:,:,i) = IV.data1{2};
        Current4(:,:,i) = IV.data2{2};
        
        T_LEG{i} = sprintf('%1.0fK', T(i));
    end
end

Current_sample = (Current1 + Current2) / 2;
Current_interpad = (Current3 + Current4) / 2;

idx_converged = IV.N_per_gate:IV.N_per_gate:Gate.numGate * IV.N_per_gate;
Current_sample_converged = Current_sample(:, idx_converged, :);
Current_interpad_converged = Current_interpad(:, idx_converged, :);

%% plot all IVs
Color = inferno(Gate.numGate);

for i = 1:Settings.nT
    figure
    subplot(1,2,1); hold on
    for j = 1:Gate.numGate
        plot(IV.Bias1, abs(Current_sample(:, (j-1)*IV.N_per_gate + 1: j*IV.N_per_gate  , i)), '.', 'markersize', 12, 'color', Color(j,:))
    end
    
    set(gca,'Fontsize',20,'box','on')
    set(gcf,'color','white','Inverthardcopy','off')
    xlabel('Gate voltage (V)')
    ylabel('Sample current (A)')
    set(gca,'xlim',[IV.minV IV.maxV])
    set(gca,'yscale','log')
    %     leg = legend(T_LEG);
    %     set(leg,'box','off','fontsize',12)
    
    subplot(1,2,2); hold on
    for j = 1:Gate.numGate
        plot(IV.Bias1, abs(Current_interpad(:, (j-1)*IV.N_per_gate + 1: j*IV.N_per_gate  , i)), '.', 'markersize', 12, 'color', Color(j,:))
    end
    
    set(gca,'Fontsize',20,'box','on')
    set(gcf,'color','white','Inverthardcopy','off')
    xlabel('Bias voltage (V)')
    ylabel('Bias current (A)')
    set(gca,'xlim',[IV.minV IV.maxV])
    set(gca,'yscale','log')
    %     leg = legend(T_LEG);
    %     set(leg,'box','off','fontsize',12)
    
end

%% plot current at 1V vs gate vs T
Bias_plot = 1;
Bias_idx = find(abs(IV.Bias1 - Bias_plot) == min(abs(IV.Bias1 - Bias_plot))); Bias_idx = Bias_idx(1);

figure;
for i = 1:Settings.nT
    subplot(1,2,1); hold on
    plot(Gate.bias, abs(Current_sample_converged(Bias_idx, :, i)), '.', 'markersize',24)
    
    set(gca,'Fontsize',20,'box','on')
    set(gcf,'color','white','Inverthardcopy','off')
    xlabel('Gate voltage (V)')
    ylabel('Sample current (A)')
    set(gca,'ylim',[1e-13 1e-7])
    set(gca,'xlim',[Gate.minV Gate.maxV])
    set(gca,'yscale','log')
    set(gca,'ytick',10.^(-20:20))
    %     leg = legend(T_LEG);
    %     set(leg,'box','off','fontsize',12)
    
    subplot(1,2,2); hold on
    plot(Gate.bias, abs(Current_interpad_converged(Bias_idx, :, i)), '.', 'markersize',24)
    
    set(gca,'Fontsize',20,'box','on')
    set(gcf,'color','white','Inverthardcopy','off')
    xlabel('Gate voltage (V)')
    ylabel('Interpad current (A)')
    set(gca,'ylim',[1e-13 1e-7])
    set(gca,'ytick',10.^(-20:20))
    set(gca,'xlim',[Gate.minV Gate.maxV])
    set(gca,'yscale','log')
    %     leg = legend(T_LEG);
    %     set(leg,'box','off','fontsize',12)
    
end

%% plot stabiliuty vs T
figure;
for i = 1:Settings.nT
    subplot(2,3,i);
    surf(Gate.bias, IV.Bias1, log10(abs(Current_sample_converged(:,:,i))), 'edgecolor','interp')
    view([0 90])
    set(gca,'Fontsize',20,'box','on')
    set(gcf,'color','white','Inverthardcopy','off')
    xlabel('Gate voltage (V)')
    ylabel('Bias voltage (V)')
    set(gca,'xlim',[Gate.minV Gate.maxV])
    set(gca,'ylim',[IV.minV IV.maxV])
    set(gca,'clim',[-13 -7])
    title(sprintf('%1.0f K',T(i)))
    colorbar
end