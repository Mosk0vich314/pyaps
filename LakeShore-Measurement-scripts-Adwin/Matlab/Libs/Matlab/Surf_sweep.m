function Surf_sweep(Settings, sweep, figure_name)

%% initialize figure
fig = findobj('Type', 'Figure', 'Name', figure_name);
if isempty(fig)
    fig = figure('Name', figure_name);
    set(gcf,'units','normalized')
    set(fig, 'Position', Settings.plot_position)
end

if Settings.N_ADC > 1
    figure(fig); cla; hold on
    N_x = ceil(sqrt(Settings.N_ADC));
    N_y = ceil(Settings.N_ADC / N_x);
    
    %% make surface plot
    % Gate = gate.minV:R
    for i = 1:Settings.N_ADC
        subplot(N_x, N_y, i)
        surf(1:sweep.index, sweep.Bias1, log10(abs(sweep.data1{i})),'edgecolor','interp')
        set(gca,'Fontsize',20,'box','on')
        set(gcf,'color','white','Inverthardcopy','off')
        ylabel(Settings.Labels.Y_2D)
        xlabel(Settings.Labels.X_2D)
        view([0 90])
        set(gca,'xlim',[1 sweep.index])
        set(gca,'ylim',[sweep.minV sweep.maxV])
    end
    
else
    sweep.data = sweep.current{1};
    sweep.data1 = sweep.data1{1};
    sweep.data2 = sweep.data2{1};
    sweep.data_der1 = sweep.data_der1{1};
    sweep.data_der2 = sweep.data_der2{1};
    
    subplot('position', [0.05 0.1 0.23 0.35])
    hold on
    plot(sweep.Bias1, sweep.data1,'.');
    set(gca,'fontsize',20,'box','on')
    set(gcf,'Color','white')
    ylabel(Settings.Labels.Y_1D)
    xlabel(Settings.Labels.X_1D)
    set(gca,'xlim',[sweep.minV*1.05 sweep.maxV*1.05]);
    set(gca,'ylim',[-1.1*max(max(abs(sweep.data))) 1.1*max(max(abs(sweep.data)))]);
    
    subplot('position', [0.35 0.10 0.27 0.35])
    hold on
    title(Settings.sample, 'Interpreter', 'none')
    surf(1:sweep.index, sweep.Bias1, sweep.data1,'edgecolor','interp')
    view([0 90])
    set(gca,'fontsize',20,'box','on')
    set(gcf,'Color','white')
    ylabel(Settings.Labels.Y_2D)
    xlabel(Settings.Labels.X_2D)
    set(gca,'xlim',[1 sweep.index]);
    set(gca,'ylim',[sweep.minV sweep.maxV]);
    try c_max = mean(mean(abs(sweep.data))) ;     set(gca,'clim',[-1.8*c_max 1.8*c_max]);end
    colorbar
    
    subplot('position', [0.69 0.1 0.27 0.35])
    hold on
    surf(1:sweep.index, sweep.Bias_der1, sweep.data_der1','edgecolor','interp')
    view([0 90])
    set(gca,'fontsize',20,'box','on')
    set(gcf,'Color','white')
    title('\fontsize{16} dI/dV (A/V)')
    ylabel(Settings.Labels.Y_2D)
    xlabel(Settings.Labels.X_2D)
    set(gca,'xlim',[1 sweep.index]);
    set(gca,'ylim',[sweep.minV sweep.maxV]);
    try tmp =  mean(abs(sweep.data_der1));    tmp(isinf(tmp)) = [];    c_max = mean(tmp);    set(gca,'clim',[0 0.5*c_max]); end
    colorbar
    
    subplot('position', [0.05 0.60 0.23 0.35])
    hold on
    plot(sweep.Bias1, sweep.data1,'.');
    set(gca,'fontsize',20,'box','on')
    set(gcf,'Color','white')
    ylabel(Settings.Labels.Y_1D)
    xlabel(Settings.Labels.X_1D)
    set(gca,'xlim',[sweep.minV*1.05 sweep.maxV*1.05]);
    set(gca,'ylim',[-1.1*max(max(abs(sweep.data1))) 1.1*max(max(abs(sweep.data1)))]);
    
    subplot('position', [0.35 0.60 0.27 0.35])
    hold on
    title(Settings.sample, 'Interpreter', 'none')
    surf(1:sweep.index, sweep.Bias1, sweep.data1,'edgecolor','interp')
    view([0 90])
    set(gca,'fontsize',20,'box','on')
    set(gcf,'Color','white')
    ylabel(Settings.Labels.Y_2D)
    xlabel(Settings.Labels.X_2D);
    set(gca,'xlim',[1 sweep.index]);
    set(gca,'ylim',[sweep.minV sweep.maxV]);
    try c_max = mean(mean(abs(sweep.data))) ;     set(gca,'clim',[-1.8*c_max 1.8*c_max]);end
    colorbar
    
    subplot('position', [0.69 0.60 0.27 0.35])
    hold on
    surf(1:sweep.index, sweep.Bias_der1, sweep.data_der1','edgecolor','interp')
    view([0 90])
    set(gca,'fontsize',20,'box','on')
    set(gcf,'Color','white')
    title('\fontsize{16} dI/dV (A/V)')
    ylabel(Settings.Labels.Y_2D)
    xlabel(Settings.Labels.X_2D)
    set(gca,'xlim',[1 sweep.index]);
    set(gca,'ylim',[sweep.minV sweep.maxV]);
    try tmp =  mean(abs(sweep.data_der1));    tmp(isinf(tmp)) = [];    c_max = mean(tmp);    set(gca,'clim',[0 0.5*c_max]); end
    colorbar

end

drawnow
