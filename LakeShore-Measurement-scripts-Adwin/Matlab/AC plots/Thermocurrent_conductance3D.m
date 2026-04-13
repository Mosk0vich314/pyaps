function sweep = Thermocurrent_conductance3D(Settings, sweep, Lockin1, Lockin2, figure_name)

%% start figure
    fig = figure('Name', figure_name);
    set(gcf,'units','normalized')
    set(fig, 'Position', Settings.plot_position)

%% make 3D surface plot
sweep = split_data_sweep(Settings, sweep);
data_IV = sweep.data2{5};
data_dIdV = sweep.data2{3};
data_thermoI = sweep.data2{2};

%% Calculate Derivate
data_dIdV_numeric = sweep.data_der2{5};

%% Calculate Thermovolatage
data_thermoV = data_thermoI./data_dIdV;

%% Calculate Thermocurrent R/R
data_thermoI_RR = sqrt(sweep.data2{1}.^2 + sweep.data2{2}.^2);
data_dIdV_RR = sqrt(sweep.data2{3}.^2 + sweep.data2{4}.^2);
data_thermoV_RR = data_thermoI_RR./data_dIdV_RR;

%% surf IV
subplot(2,3,1)
surf(sweep.x_axis, sweep.Bias2, data_IV,'edgecolor','interp')
view([0 90])
set(gca,'fontsize',20,'box','on')
set(gcf,'Color','white')
ylabel(Settings.Labels.Y_2D)
xlabel(Settings.Labels.X_2D)
xlabel('Gate voltage (V)')
ylabel('Bias voltage (V)')
set(gca,'xlim',[min(sweep.x_axis) max(sweep.x_axis)]);
set(gca,'ylim',[sweep.minV sweep.maxV]);
try set(gca,'clim',[sweep.clim.IV(1) sweep.clim.IV(2)]); end
title('I-V')
colorbar

% surf dIdV
subplot(2,3,2)
surf(sweep.x_axis, sweep.Bias_der2, data_dIdV_numeric','edgecolor','interp')
view([0 90])
set(gca,'fontsize',20,'box','on')
set(gcf,'Color','white')
xlabel('Gate voltage (V)')
ylabel('Bias voltage (V)')
set(gca,'xlim',[min(sweep.x_axis) max(sweep.x_axis)]);
set(gca,'ylim',[sweep.minV sweep.maxV]);
try set(gca,'clim',[sweep.clim.dIdV_numeric(1) sweep.clim.dIdV_numeric(2)]); end
title('dI/dV-numerical')
colorbar

% surf thermovoltage
subplot(2,3,3)
surf(sweep.x_axis, sweep.Bias2, data_thermoV_RR,'edgecolor','interp')
view([0 90])
set(gca,'fontsize',20,'box','on')
set(gcf,'Color','white')
xlabel('Gate voltage (V)')
ylabel('Bias voltage (V)')
set(gca,'xlim',[min(sweep.x_axis) max(sweep.x_axis)]);
set(gca,'ylim',[sweep.minV sweep.maxV]);
try set(gca,'clim',[sweep.clim.Thermovoltage_RR(1) sweep.clim.Thermovoltage_RR(2)]); end
title('Thermovoltage-R/R')
colorbar

% surf Thermocurrent
subplot(2,3,4)
surf(sweep.x_axis, sweep.Bias2, data_thermoI,'edgecolor','interp')
view([0 90])
set(gca,'fontsize',20,'box','on')
set(gcf,'Color','white')
ylabel(Settings.Labels.Y_2D)
xlabel(Settings.Labels.X_2D)
xlabel('Gate voltage (V)')
ylabel('Bias voltage (V)')
set(gca,'xlim',[min(sweep.x_axis) max(sweep.x_axis)]);
set(gca,'ylim',[sweep.minV sweep.maxV]);
try set(gca,'clim',[sweep.clim.Thermocurrent(1) sweep.clim.Thermocurrent(2)]); end
title('Thermocurrent')
colorbar

% surf dIdV
subplot(2,3,5)
surf(sweep.x_axis, sweep.Bias2, data_dIdV,'edgecolor','interp')
view([0 90])
set(gca,'fontsize',20,'box','on')
set(gcf,'Color','white')
xlabel('Gate voltage (V)')
ylabel('Bias voltage (V)')
set(gca,'xlim',[min(sweep.x_axis) max(sweep.x_axis)]);
set(gca,'ylim',[sweep.minV sweep.maxV]);
try set(gca,'clim',[sweep.clim.dIdV_lockin(1) sweep.clim.dIdV_lockin(2)]); end
title('dI/dV-lockin')
colorbar

% surf thermovoltage
subplot(2,3,6)
surf(sweep.x_axis, sweep.Bias2, data_thermoV,'edgecolor','interp')
view([0 90])
set(gca,'fontsize',20,'box','on')
set(gcf,'Color','white')
xlabel('Gate voltage (V)')
ylabel('Bias voltage (V)')
set(gca,'xlim',[min(sweep.x_axis) max(sweep.x_axis)]);
set(gca,'ylim',[sweep.minV sweep.maxV]);
try set(gca,'clim',[sweep.clim.Thermovoltage(1) sweep.clim.Thermovoltage(2)]); end
title('Thermovoltage')
colorbar

drawnow

return