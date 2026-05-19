%% replot_log-log

%% initialize figure
cmap = colormap(parula); close all
colors = cmap(round(linspace(1, length(cmap), N_frequency)), :);

fig = figure('position', [ 74  114 1700  835]); hold on;
set(gcf,'color','white','Inverthardcopy','off')
subplot(2, 3, 1);hold on
set(gca,'box','on','fontsize',16)
set(gca,'xlim',[Lockin1.frequency(1) Lockin1.frequency(end)])
set(gca, 'YScale', 'log')
set(gca, 'XScale', 'log')
xlabel('Heater frequency (Hz)')
ylabel('abs(X_{2\omega} - Heater (V))')

subplot(2, 3, 2);hold on
set(gca,'box','on','fontsize',16)
set(gca,'xlim',[Lockin1.frequency(1) Lockin1.frequency(end)])
set(gca, 'YScale', 'log')
set(gca, 'XScale', 'log')
xlabel('Heater frequency (Hz)')
ylabel('abs(Y_{2\omega} - Heater (V))')

subplot(2, 3, 3);hold on
set(gca,'box','on','fontsize',16)
set(gca,'xlim',[Lockin1.frequency(1) Lockin1.frequency(end)])
set(gca, 'YScale', 'log')
set(gca, 'XScale', 'log')
xlabel('Heater frequency (Hz)')
ylabel('R_{2\omega} - Heater (V)')

subplot(2, 3, 4);hold on
set(gca,'box','on','fontsize',16)
set(gca,'xlim',[0 Gt.runtime])
xlabel('Heater frequency (Hz)')
ylabel('X_{\omega} - Conductance (V)')
set(gca,'xlim',[Lockin1.frequency(1) Lockin1.frequency(end)])
set(gca, 'YScale', 'log')
set(gca, 'XScale', 'log')

subplot(2, 3, 5);hold on
set(gca,'box','on','fontsize',16)
set(gca,'xlim',[0 Gt.runtime])
xlabel('Heater frequency (Hz)')
ylabel('Y_{\omega} - Conductance (V)')
set(gca,'xlim',[Lockin1.frequency(1) Lockin1.frequency(end)])
set(gca, 'YScale', 'log')
set(gca, 'XScale', 'log')

subplot(2, 3, 6);hold on
set(gca,'box','on','fontsize',16)
set(gca,'xlim',[0 Gt.runtime])
xlabel('Heater frequency (Hz)')
ylabel('R_{\omega} - Conductance (V)')
set(gca,'xlim',[Lockin1.frequency(1) Lockin1.frequency(end)])
set(gca, 'YScale', 'log')
set(gca, 'XScale', 'log')

%%

figure(fig);
    subplot(2, 3, 1);hold on
    plot(Lockin1.frequency, abs(Lockin1.voltage(:,1)), '.','markersize',24,'color',[0, 0.4470, 0.7410])
    
    subplot(2, 3, 2);hold on
    plot(Lockin1.frequency, abs(Lockin1.voltage(:,2)) , '.','markersize',24,'color',[0, 0.4470, 0.7410])
    
    subplot(2, 3, 3);hold on
    plot(Lockin1.frequency, sqrt(Lockin1.voltage(:,1).^2 + Lockin1.voltage(j,2).^2), '.','markersize',24,'color',[0, 0.4470, 0.7410])
    
    subplot(2, 3, 4);hold on
    plot(Lockin1.frequency, Lockin1.voltage(:,3), '.','markersize',24,'color',[0, 0.4470, 0.7410])
    
    subplot(2, 3, 5);hold on
    plot(Lockin1.frequency, Lockin1.voltage(:,4), '.','markersize',24,'color',[0, 0.4470, 0.7410])
    
    subplot(2, 3, 6);hold on
    plot(Lockin1.frequency, sqrt(Lockin1.voltage(:,3).^2 + Lockin1.voltage(j,4).^2), '.','markersize',24,'color',[0, 0.4470, 0.7410])

    
%% save plot
saveas(fig, sprintf('%s/%s_%s_%s_heater_freq_dep_loglog.png', Settings.save_dir, Settings.filename, Settings.sample{1}, Settings.type))


