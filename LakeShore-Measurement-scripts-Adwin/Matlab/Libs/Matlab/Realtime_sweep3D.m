function sweep = Realtime_sweep3D(Settings, sweep, figure_name)

%% start figure
if Settings.res4p == 1
    N_plots = Settings.N_ADC/2;
else
    N_plots = Settings.N_ADC;
end

dX = abs(sweep.x_axis(2) - sweep.x_axis(1));
dY = abs(sweep.bias(2) - sweep.bias(1));

for idx = 1:N_plots

    if isempty(findobj('Type', 'Figure', 'Name', sprintf('%s %s', figure_name, Settings.sample{idx})))
        fig = figure('Name', sprintf('%s %s', figure_name, Settings.sample{idx}));
        set(fig,'units','normalized')
        set(fig, 'Position', Settings.plot_position)
        sweep.handles(idx).fig = fig;

        % individual IVs lin
        sweep.handles(idx).ax.lin = subplot('position', [0.06 0.55 0.23 0.35]);
        hold on
        set(gca,'fontsize',20,'box','on')
        set(gcf,'Color','white')
        ylabel(Settings.Labels.Y_1D)
        xlabel(Settings.Labels.X_1D)
        set(gca,'xlim',[sweep.minV*1.05 sweep.maxV*1.05]);
        sweep.handles(idx).animated_lines.lin = animatedline(gca, 'LineWidth',1.5);
        
        % individual IVs log
        sweep.handles(idx).ax.log = subplot('position', [0.06 0.08 0.23 0.35]);
        hold on
        set(gca,'fontsize',20,'box','on')
        set(gcf,'Color','white')
        ylabel(Settings.Labels.Y_1D)
        xlabel(Settings.Labels.X_1D)
        set(gca,'xlim',[sweep.minV*1.05 sweep.maxV*1.05]);
        set(gca,'yscale','log')
        sweep.handles(idx).animated_lines.log = animatedline(gca, 'LineWidth',1.5);

        % surf IV log
        sweep.handles(idx).ax.IV3D_log = subplot('position', [0.355 0.08 0.27 0.35]);
        colormap(gca, viridis(256))
        hold on
        title('\fontsize{16} IV - log')
        view([0 90])
        set(gca,'fontsize',20,'box','on')
        set(gcf,'Color','white')
        ylabel(Settings.Labels.Y_2D)
        xlabel(Settings.Labels.X_2D)
        set(gca,'xlim',[min(sweep.x_axis)-dX/2 max(sweep.x_axis)+dX/2]);
        set(gca,'ylim',[sweep.minV-dY/2 sweep.maxV+dY/2]);
        colorbar
        
        % surf IV linear
        sweep.handles(idx).ax.IV3D_lin = subplot('position', [0.355 0.55 0.27 0.35]);
        hold on
        colormap(gca, brewermap(256,'RdBu'))
        title('\fontsize{16} IV')
        view([0 90])
        set(gca,'fontsize',20,'box','on')
        set(gcf,'Color','white')
        ylabel(Settings.Labels.Y_2D)
        xlabel(Settings.Labels.X_2D)
        set(gca,'xlim',[min(sweep.x_axis)-dX/2 max(sweep.x_axis)+dX/2]);
        set(gca,'ylim',[sweep.minV-dY/2 sweep.maxV+dY/2]);
        colorbar
        
        % surf dI/dV log
        sweep.handles(idx).ax.dIdV3D_log = subplot('position', [0.70 0.08 0.27 0.35]);
        hold on
        colormap(gca, inferno(256))
        view([0 90])
        set(gca,'fontsize',20,'box','on')
        set(gcf,'Color','white')
        title('\fontsize{16} dI/dV (A/V) - log')
        ylabel(Settings.Labels.Y_2D)
        xlabel(Settings.Labels.X_2D)
        set(gca,'xlim',[min(sweep.x_axis)-dX/2 max(sweep.x_axis)+dX/2]);
        set(gca,'ylim',[sweep.minV-dY/2 sweep.maxV+dY/2]);
        colorbar
        
        % surf dI/dV linear
        sweep.handles(idx).ax.dIdV3D_lin = subplot('position', [0.70 0.55 0.27 0.35]);
        hold on
        colormap(gca, inferno(256))
        view([0 90])
        set(gca,'fontsize',20,'box','on')
        set(gcf,'Color','white')
        title('\fontsize{16} dI/dV (A/V)')
        ylabel(Settings.Labels.Y_2D)
        xlabel(Settings.Labels.X_2D)
        set(gca,'xlim',[min(sweep.x_axis)-dX/2 max(sweep.x_axis)+dX/2]);
        set(gca,'ylim',[sweep.minV-dY/2 sweep.maxV+dY/2]);
        colorbar
        
    else
        cla(sweep.handles(idx).ax.lin);
        cla(sweep.handles(idx).ax.log);

        sweep.handles(idx).animated_lines.lin = animatedline(sweep.handles(idx).ax.lin, 'LineWidth',1.5);
        sweep.handles(idx).animated_lines.log = animatedline(sweep.handles(idx).ax.log, 'LineWidth',1.5);
    end
end

drawnow

%% initialize
previous_counter = 1;
pause(0.5);

%% run loop
run = true;
while run && Get_Par(25) > 0
    
    run = Process_Status(1);
    actual_time = Get_Par(25) - 1;
    
    %% get current and update plot
    array = Settings.ADC_idx + 1;

    if Settings.res4p == 1
        try
            temp = zeros(Settings.N_ADC, actual_time - previous_counter);
            for i = 1:Settings.N_ADC
                temp(i,:) = GetData_Double(array(i), previous_counter + 1, actual_time - previous_counter);
            end
            for i = 1:N_plots
                addpoints(sweep.handles(i).animated_lines.lin, sweep.bias(previous_counter + 1 : actual_time), temp((i-1)*2 + 1, :)./temp((i-1)*2 + 2, :));
                addpoints(sweep.handles(i).animated_lines.log, sweep.bias(previous_counter + 1 : actual_time), abs(temp((i-1)*2 + 1, :)./temp((i-1)*2 + 2, :)));
            end
            drawnow limitrate
        end
    else

        for i = 1:Settings.N_ADC
            try
                temp = GetData_Double(array(idx), previous_counter + 1, actual_time - previous_counter);
                addpoints(sweep.handles(i).animated_lines.lin, sweep.bias(previous_counter + 1 : actual_time), temp);
                addpoints(sweep.handles(i).animated_lines.log, sweep.bias(previous_counter + 1 : actual_time), abs(temp));
            end
            drawnow limitrate
        end
    end

    %% prepare for next iteration
    previous_counter = actual_time;
end

%% get final current
array = Settings.ADC_idx + 1;
for i = 1:Settings.N_ADC
    sweep.current{i}(:, sweep.index) = GetData_Double(array(i), 1, sweep.NumBias);
end

%% make 3D surface plot
sweep = split_data_sweep(Settings, sweep);

for idx = 1:N_plots
    if Settings.res4p == 1
        sweep.data = sweep.data1{(idx-1)*2 + 1} ./ sweep.data1{(idx-1)*2 + 2};
        sweep.data_der = diff(sweep.data)' ./ sweep.dV;
    else
        sweep.data = sweep.data1{idx};
        sweep.data_der = sweep.data_der1{idx};
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
  
    % surf IV log
    cla(sweep.handles(idx).ax.IV3D_log);
    imagesc(sweep.x_axis, sweep.Bias1, log10(abs(sweep.data)),'Parent', sweep.handles(idx).ax.IV3D_log)
    try set(sweep.handles(idx).ax.IV3D_log,'clim',[Clim_log_minIV Clim_log_maxIV]); end
    
    % surf IV linear
    cla(sweep.handles(idx).ax.IV3D_lin);
    imagesc(sweep.x_axis, sweep.Bias1, sweep.data,'Parent', sweep.handles(idx).ax.IV3D_lin)
    try set(sweep.handles(idx).ax.IV3D_lin,'clim',[Clim_lin_minIV Clim_lin_maxIV]); end
    
    % surf dI/dV log
    cla(sweep.handles(idx).ax.dIdV3D_log);
    imagesc(sweep.x_axis, sweep.Bias_der1, log10(abs(sweep.data_der')),'Parent', sweep.handles(idx).ax.dIdV3D_log)
    try  set(sweep.handles(idx).ax.dIdV3D_log,'clim',[Clim_log_mindIdV Clim_log_maxdIdV]); end
    
    % surf dI/dV linear
    cla(sweep.handles(idx).ax.dIdV3D_lin);
    imagesc(sweep.x_axis, sweep.Bias_der1, sweep.data_der','Parent', sweep.handles(idx).ax.dIdV3D_lin)
    try set(sweep.handles.ax.dIdV3D_lin,'clim',[Clim_lin_mindIdV Clim_lin_maxdIdV]); end
    
    drawnow
    
end

return