function Surf_stability(Settings, sweep, Gate, figure_name)

if Settings.res4p == 1
    N_plots = Settings.N_ADC/2;
else
    N_plots = Settings.N_ADC;
end

%% make surface plot

for index = 1:N_plots
    
    fig = figure('Name', figure_name);
    set(gcf,'units','normalized')
    set(fig, 'Position', Settings.plot_position)
    tit = sgtitle(Settings.sample{index},'fontsize',32);
    
    if Settings.res4p == 1
        sweep.data = sweep.data1{(index-1)*2 + 1} ./ sweep.data1{(index-1)*2 + 2};
        sweep.data_der = diff(sweep.data)' ./ sweep.dV;
    else
        sweep.data = sweep.data1{index};
        sweep.data_der = sweep.data_der1{index};
    end
    
    % get color limits
    if isempty(sweep.clim_log)
        Clim_log_minIV = log10(0.9*min(min(abs(sweep.data))));
        Clim_log_maxIV = log10(1.1*max(max(abs(sweep.data))));
        Clim_log_mindIdV = log10(0.9*min(min(abs(sweep.data_der))));
        Clim_log_maxdIdV =  log10(1.1*max(max(abs(sweep.data_der))));
    else
        Clim_log_minIV = sweep.clim_log(1);
        Clim_log_maxIV = sweep.clim_log(2);
        Clim_log_mindIdV = sweep.clim_log(3);
        Clim_log_maxdIdV = sweep.clim_log(4);
    end
    
    if isempty(sweep.clim_lin)
        Clim_lin_minIV = -1.1*max(max(abs(sweep.data)));
        Clim_lin_maxIV = 1.1*max(max(abs(sweep.data)));
        Clim_lin_mindIdV = 0;
        Clim_lin_maxdIdV = 1.1*max(max(abs(sweep.data_der)));
    else
        Clim_lin_minIV = sweep.clim_lin(1);
        Clim_lin_maxIV = sweep.clim_lin(2);
        Clim_lin_mindIdV = sweep.clim_lin(3);
        Clim_lin_maxdIdV = sweep.clim_lin(4);
    end
    
    % individual IVs log
    subplot('position', [0.06 0.08 0.23 0.35])
    hold on
    plot(sweep.Bias1, abs(sweep.data),'.');
    set(gca,'fontsize',20,'box','on')
    set(gcf,'Color','white')
    ylabel(Settings.Labels.Y_1D)
    xlabel(Settings.Labels.X_1D)
    set(gca,'xlim',[sweep.minV*1.05 sweep.maxV*1.05]);
    set(gca,'ylim',10.^[Clim_log_minIV Clim_log_maxIV]);
    set(gca,'yscale','log')
    
    % individual IVs log
    subplot('position', [0.06 0.55 0.23 0.35])
    hold on
    plot(sweep.Bias1, sweep.data,'.');
    set(gca,'fontsize',20,'box','on')
    set(gcf,'Color','white')
    ylabel(Settings.Labels.Y_1D)
    xlabel(Settings.Labels.X_1D)
    set(gca,'xlim',[sweep.minV*1.05 sweep.maxV*1.05]);
    set(gca,'ylim',[Clim_lin_minIV Clim_lin_maxIV]);
    
    % surf IV log
    subplot('position', [0.355 0.08 0.27 0.35])
    hold on
    title('\fontsize{16} IV - log')
    surf(Gate.voltage, sweep.Bias1, log10(abs(sweep.data)),'edgecolor','interp')
    colormap(gca, viridis(256))
    view([0 90])
    set(gca,'fontsize',20,'box','on')
    set(gcf,'Color','white')
    ylabel(Settings.Labels.Y_2D)
    xlabel(Settings.Labels.X_2D)
    set(gca,'xlim',[Gate.minV Gate.maxV]);
    set(gca,'ylim',[sweep.minV sweep.maxV]);
    try set(gca,'clim',[Clim_log_minIV Clim_log_maxIV]); end
    colorbar
    
    % surf IV linear
    subplot('position', [0.355 0.55 0.27 0.35])
    hold on
    title('\fontsize{16} IV')
    surf(Gate.voltage, sweep.Bias1, sweep.data,'edgecolor','interp')
    colormap(gca, cbrewer('div','RdBu',256))
    view([0 90])
    set(gca,'fontsize',20,'box','on')
    set(gcf,'Color','white')
    ylabel(Settings.Labels.Y_2D)
    xlabel(Settings.Labels.X_2D)
    set(gca,'xlim',[Gate.minV Gate.maxV]);
    set(gca,'ylim',[sweep.minV sweep.maxV]);
    try set(gca,'clim',[Clim_lin_minIV Clim_lin_maxIV]); end
    colorbar
    
    % surf dI/dV log
    subplot('position', [0.70 0.08 0.27 0.35])
    hold on
    surf(Gate.voltage, sweep.Bias_der1, log10(abs(sweep.data_der')),'edgecolor','interp')
    view([0 90])
    colormap(gca, inferno(256))
    set(gca,'fontsize',20,'box','on')
    set(gcf,'Color','white')
    title('\fontsize{16} dI/dV (A/V) - log')
    ylabel(Settings.Labels.Y_2D)
    xlabel(Settings.Labels.X_2D)
    set(gca,'xlim',[Gate.minV Gate.maxV]);
    set(gca,'ylim',[sweep.minV sweep.maxV]);
    try  set(gca,'clim',[Clim_log_mindIdV Clim_log_maxdIdV]); end
    colorbar
    
    % surf dI/dV linear
    subplot('position', [0.70 0.55 0.27 0.35])
    hold on
    surf(Gate.voltage, sweep.Bias_der1, sweep.data_der','edgecolor','interp')
    colormap(gca, inferno(256))
    view([0 90])
    set(gca,'fontsize',20,'box','on')
    set(gcf,'Color','white')
    title('\fontsize{16} dI/dV (A/V)')
    ylabel(Settings.Labels.Y_2D)
    xlabel(Settings.Labels.X_2D)
    set(gca,'xlim',[Gate.minV Gate.maxV]);
    set(gca,'ylim',[sweep.minV sweep.maxV]);
    try  set(gca,'clim',[Clim_lin_mindIdV Clim_lin_maxdIdV]); end
    colorbar
    
end
