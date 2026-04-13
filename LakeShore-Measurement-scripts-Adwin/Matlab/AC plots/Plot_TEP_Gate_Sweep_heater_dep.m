%%
clc
close all
clear

%% settings
directory = 'C:\Samples\Fred\CNTTEP2\1112b';
filename = '2023-11-27_run44_TEP_Gate_sweep_TEP_Timetraces_Current';

%% get files
list = dir(sprintf('%s/%s*.mat', directory, filename));
N_heaters = numel(list);

%% load first file
Data = load(sprintf('%s/%s', list(1).folder, list(1).name));
Gate = Data.Gate;
Settings = Data.Settings;
Timetrace = Data.Timetrace;

%% load all files
Data_mean_all = cell(N_heaters, 1);
Data_std_all = cell(N_heaters, 1);

for i = 1:N_heaters
    Data = load(sprintf('%s/%s', list(i).folder, list(i).name));
    Data_mean_all{i} = Data.Timetrace.mean;
    Data_std_all{i} = Data.Timetrace.std;
end

%% plot heater current dependence
colors = inferno(N_heaters);

fig = figure;
set(gcf,'units','normalized')
set(fig, 'Position', Settings.plot_position)

t = tiledlayout('flow');

switch lower(Settings.thermo)
    case 'current'

        % individual gate sweep
        ax_gatesweep = nexttile(t); hold on
        set(gca,'fontsize',16,'box','on')
        set(gcf,'Color','white')
        ylabel('DC Current (A)')
        xlabel('Gate voltage (V)')
        set(gca,'xlim',[Gate.minV*1.05 Gate.maxV*1.05]);
        leg = legend('');
        set(leg,'box','off','Location','northeast')

        % individual thermocurrent
        ax_thermocurrent_X = nexttile(t); hold on
        set(gca,'fontsize',16,'box','on')
        set(gcf,'Color','white')
        ylabel('Thermocurrent - X (A)')
        xlabel('Gate voltage (V)')
        set(gca,'xlim',[Gate.minV*1.05 Gate.maxV*1.05]);

        ax_thermocurrent_Y = nexttile(t); hold on
        set(gca,'fontsize',16,'box','on')
        set(gcf,'Color','white')
        ylabel('Thermocurrent - Y (A)')
        xlabel('Gate voltage (V)')
        set(gca,'xlim',[Gate.minV*1.05 Gate.maxV*1.05]);

        % dI/dV lockin lin 2p
        ax_dIdV2p_X = nexttile(t); hold on
        set(gca,'fontsize',16,'box','on')
        set(gcf,'Color','white')
        ylabel('dI/dV 2p - X (A/V)')
        xlabel('Gate voltage (V)')
        set(gca,'xlim',[Gate.minV*1.05 Gate.maxV*1.05]);

        ax_dIdV2p_Y = nexttile(t); hold on
        set(gca,'fontsize',16,'box','on')
        set(gcf,'Color','white')
        ylabel('dI/dV 2p - Y (A/V)')
        xlabel('Gate voltage (V)')
        set(gca,'xlim',[Gate.minV*1.05 Gate.maxV*1.05]);

        % dI/dV lockin lin 4p
        if Timetrace.N_devices == 3
            ax_dIdV4p_X = nexttile(t); hold on
            set(gca,'fontsize',16,'box','on')
            set(gcf,'Color','white')
            ylabel('dI/dV 4p - X (A/V)')
            xlabel('Gate voltage (V)')
            set(gca,'xlim',[Gate.minV*1.05 Gate.maxV*1.05]);

            ax_dIdV4p_Y = nexttile(t); hold on
            set(gca,'fontsize',16,'box','on')
            set(gcf,'Color','white')
            ylabel('dI/dV 4p - Y(A/V)')
            xlabel('Gate voltage (V)')
            set(gca,'xlim',[Gate.minV*1.05 Gate.maxV*1.05]);
        end

        % thermovoltage lin R * I
        ax_thermovoltage = nexttile(t); hold on
        set(gca,'fontsize',16,'box','on')
        set(gcf,'Color','white')
        ylabel('Thermovoltage (V)')
        xlabel('Gate voltage (V)')
        set(gca,'xlim',[Gate.minV*1.05 Gate.maxV*1.05]);

    case 'voltage'

        % thermovoltage direct
        ax_thermovoltage_direct_X = nexttile(t); hold on
        set(gca,'fontsize',16,'box','on')
        set(gcf,'Color','white')
        ylabel('Thermovoltage - X (V)')
        xlabel('Gate voltage (V)')
        set(gca,'xlim',[Gate.minV*1.05 Gate.maxV*1.05]);

        ax_thermovoltage_direct_Y = nexttile(t); hold on
        set(gca,'fontsize',16,'box','on')
        set(gcf,'Color','white')
        ylabel('Thermovoltage - Y (V)')
        xlabel('Gate voltage (V)')
        set(gca,'xlim',[Gate.minV*1.05 Gate.maxV*1.05]);

end

%% make update line plots
LEG = cell(N_heaters, 1);
for i = 1:N_heaters

    LEG{i} = sprintf('I = %1.4fmA', Settings.Heaters(i));

    switch lower(Settings.thermo)
        case 'current'
            plot(Gate.voltage, Data_mean_all{i}.gatesweep(1,:), 'LineWidth',1.5,'Color',colors(i,:),'Parent',ax_gatesweep)
            plot(Gate.voltage, Data_mean_all{i}.thermocurrent.X(1,:), 'LineWidth',1.5,'Color',colors(i,:),'Parent',ax_thermocurrent_X)
            plot(Gate.voltage, Data_mean_all{i}.thermocurrent.Y(1,:), 'LineWidth',1.5,'Color',colors(i,:),'Parent',ax_thermocurrent_Y)
            plot(Gate.voltage, Data_mean_all{i}.dIdV2p.X(1,:), 'LineWidth',1.5,'Color',colors(i,:),'Parent',ax_dIdV2p_X)
            plot(Gate.voltage, Data_mean_all{i}.dIdV2p.Y(1,:), 'LineWidth',1.5,'Color',colors(i,:),'Parent',ax_dIdV2p_Y)

            if Settings.res4p == 1
                plot(Gate.voltage, Data_mean_all{i}.dIdV4p.X(1,:), 'LineWidth',1.5,'Color',colors(i,:),'Parent',ax_dIdV4p_X)
                plot(Gate.voltage, Data_mean_all{i}.dIdV4p.Y(1,:), 'LineWidth',1.5,'Color',colors(i,:),'Parent',ax_dIdV4p_Y)
            end
            plot(Gate.voltage, Data_mean_all{i}.thermovoltage(1,:), 'LineWidth',1.5,'Color',colors(i,:),'Parent',ax_thermovoltage)

        case 'voltage'
            plot(Gate.voltage, Data_mean_all{i}.Data_mean_all{i}.thermovoltage_direct.X(1,:), 'LineWidth',1.5,'Color',colors(i,:),'Parent',ax_thermovoltage_direct_X)
            plot(Gate.voltage, Data_mean_all{i}.Data_mean_all{i}.thermovoltage_direct.Y(1,:), 'LineWidth',1.5,'Color',colors(i,:),'Parent',ax_thermovoltage_direct_Y)

    end
end

%% update legend
leg.String = LEG;
leg.FontSize = 8;

%% save plot
saveas(fig, sprintf('%s/%s.png', directory, filename));
saveas(fig, sprintf('%s/%s.fig', directory, filename));
