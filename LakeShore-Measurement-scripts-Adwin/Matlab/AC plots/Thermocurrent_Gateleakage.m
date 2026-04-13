function sweep = Thermocurrent_Gateleakage(Settings, sweep, Lockin1, Lockin2, figure_name)

%% start figure
    fig = figure('Name', figure_name);
    set(gcf,'units','normalized')
    set(fig, 'Position', Settings.plot_position)

%% make 3D surface plot
sweep = split_data_sweep(Settings, sweep);
data_Gateleakage = sweep.data2{6};


%% surf Input6
subplot(2,3,1)
surf(sweep.x_axis, sweep.Bias2, data_Gateleakage,'edgecolor','interp')
view([0 90])
set(gca,'fontsize',20,'box','on')
set(gcf,'Color','white')
ylabel(Settings.Labels.Y_2D)
xlabel(Settings.Labels.X_2D)
xlabel('Gate voltage (V)')
ylabel('Bias voltage (V)')
set(gca,'xlim',[min(sweep.x_axis) max(sweep.x_axis)]);
set(gca,'ylim',[sweep.minV sweep.maxV]);
try set(gca,'clim',[sweep.clim.Gateleakage(1) sweep.clim.Gateleakage(2)]); end
title('Gateleakage')
colorbar

% surf dIdV
subplot(2,3,2)
surf(sweep.x_axis, sweep.Bias2, data_Gateleakage,'edgecolor','interp')
view([0 90])
set(gca,'fontsize',20,'box','on')
set(gcf,'Color','white')
ylabel(Settings.Labels.Y_2D)
xlabel(Settings.Labels.X_2D)
xlabel('Gate voltage (V)')
ylabel('Bias voltage (V)')
set(gca,'xlim',[min(sweep.x_axis) max(sweep.x_axis)]);
set(gca,'ylim',[sweep.minV sweep.maxV]);
try set(gca,'clim',[sweep.clim.Gateleakage(1) sweep.clim.Gateleakage(2)]); end
title('Gateleakage')
colorbar

% surf thermovoltage
subplot(2,3,3)
surf(sweep.x_axis, sweep.Bias2, data_Gateleakage,'edgecolor','interp')
view([0 90])
set(gca,'fontsize',20,'box','on')
set(gcf,'Color','white')
ylabel(Settings.Labels.Y_2D)
xlabel(Settings.Labels.X_2D)
xlabel('Gate voltage (V)')
ylabel('Bias voltage (V)')
set(gca,'xlim',[min(sweep.x_axis) max(sweep.x_axis)]);
set(gca,'ylim',[sweep.minV sweep.maxV]);
try set(gca,'clim',[sweep.clim.Gateleakage(1) sweep.clim.Gateleakage(2)]); end
title('Gateleakage')
colorbar

%% surf Input6
subplot(2,3,4)
surf(sweep.x_axis, sweep.Bias2, data_Gateleakage,'edgecolor','interp')
view([0 90])
set(gca,'fontsize',20,'box','on')
set(gcf,'Color','white')
ylabel(Settings.Labels.Y_2D)
xlabel(Settings.Labels.X_2D)
xlabel('Gate voltage (V)')
ylabel('Bias voltage (V)')
set(gca,'xlim',[min(sweep.x_axis) max(sweep.x_axis)]);
set(gca,'ylim',[sweep.minV sweep.maxV]);
try set(gca,'clim',[sweep.clim.Gateleakage(1) sweep.clim.Gateleakage(2)]); end
title('Gateleakage')
colorbar

%% surf Input6
subplot(2,3,5)
surf(sweep.x_axis, sweep.Bias2, data_Gateleakage,'edgecolor','interp')
view([0 90])
set(gca,'fontsize',20,'box','on')
set(gcf,'Color','white')
ylabel(Settings.Labels.Y_2D)
xlabel(Settings.Labels.X_2D)
xlabel('Gate voltage (V)')
ylabel('Bias voltage (V)')
set(gca,'xlim',[min(sweep.x_axis) max(sweep.x_axis)]);
set(gca,'ylim',[sweep.minV sweep.maxV]);
try set(gca,'clim',[sweep.clim.Gateleakage(1) sweep.clim.Gateleakage(2)]); end
title('Gateleakage')
colorbar

%% surf Input6
subplot(2,3,6)
surf(sweep.x_axis, sweep.Bias2, data_Gateleakage,'edgecolor','interp')
view([0 90])
set(gca,'fontsize',20,'box','on')
set(gcf,'Color','white')
ylabel(Settings.Labels.Y_2D)
xlabel(Settings.Labels.X_2D)
xlabel('Gate voltage (V)')
ylabel('Bias voltage (V)')
set(gca,'xlim',[min(sweep.x_axis) max(sweep.x_axis)]);
set(gca,'ylim',[sweep.minV sweep.maxV]);
try set(gca,'clim',[sweep.clim.Gateleakage(1) sweep.clim.Gateleakage(2)]); end
title('Gateleakage')
colorbar

drawnow

return