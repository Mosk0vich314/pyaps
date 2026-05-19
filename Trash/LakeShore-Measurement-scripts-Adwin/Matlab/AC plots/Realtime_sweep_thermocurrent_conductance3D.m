function sweep = Realtime_sweep_thermocurrent_conductance3D(Settings, sweep, Lockin1, Lockin2, figure_name)

%% start figure

    fig = figure('Name', figure_name);
    set(gcf,'units','normalized')
    set(fig, 'Position', Settings.plot_position)
    
    % individual IVs
    subplot(2,3,1)
    title('\fontsize{16} IV')
    set(gca,'fontsize',20,'box','on')
    set(gcf,'Color','white')
    ylabel('Current (A)')
    xlabel('Bias voltage (V)')
    set(gca,'xlim',[sweep.minV*1.05 sweep.maxV*1.05]);
    handles.h_IV = animatedline('LineWidth',1.5);
    
    % surf IVs
    subplot(2,3,4)
    view([0 90])
    set(gca,'fontsize',20,'box','on')
    set(gcf,'Color','white')
    xlabel('Gate voltage (V)')
    ylabel('Bias voltage (V)')
    set(gca,'xlim',[min(sweep.x_axis) max(sweep.x_axis)]);
    set(gca,'ylim',[sweep.minV sweep.maxV]);
    colorbar
    
    % dI/dV lockin lin
    subplot(2,3,2)
    title('\fontsize{16} dI/dV - lockin')
    set(gca,'fontsize',20,'box','on')
    set(gcf,'Color','white')
    ylabel('dI/dV (A/V)')
    xlabel('Bias voltage (V)')
    set(gca,'xlim',[sweep.minV*1.05 sweep.maxV*1.05]);
    handles.h_dIdV = animatedline('LineWidth',1.5);
    
    % surf dI/dV lockin
    subplot(2,3,5)
    view([0 90])
    set(gca,'fontsize',20,'box','on')
    set(gcf,'Color','white')
    xlabel('Gate voltage (V)')
    ylabel('Bias voltage (V)')
    set(gca,'xlim',[min(sweep.x_axis) max(sweep.x_axis)]);
    set(gca,'ylim',[sweep.minV sweep.maxV]);
    colorbar
    
    % thermovoltage lin
    subplot(2,3,3)
    title('\fontsize{16} Thermovoltage')
    set(gca,'fontsize',20,'box','on')
    set(gcf,'Color','white')
    ylabel('Thermovoltage (\muV)')
    xlabel('Bias voltage (V)')
    set(gca,'xlim',[sweep.minV*1.05 sweep.maxV*1.05]);
    handles.h_Thermovoltage = animatedline('LineWidth',1.5);
    
    % surf thermovoltage
    subplot(2,3,6)
    view([0 90])
    set(gca,'fontsize',20,'box','on')
    set(gcf,'Color','white')
    title('\fontsize{16} dI/dV (A/V)')
    xlabel('Gate voltage (V)')
    ylabel('Bias voltage (V)')
    set(gca,'xlim',[min(sweep.x_axis) max(sweep.x_axis)]);
    set(gca,'ylim',[sweep.minV sweep.maxV]);
    colorbar
    
    guidata(fig,handles)
    

drawnow

%% make 3D surface plot
sweep = split_data_sweep(Settings, sweep);
data_IV = sweep.data2{5};
data_dIdV = sweep.data2{3};
data_thermoV = sweep.data2{2};

%% get color limits
if isempty(sweep.clim)
    clim_IV_minIV = -1.1*max(max(abs(data_IV)));
    clim_IV_maxIV = 1.1*max(max(abs(data_IV)));
    clim_dIdV_minIV = 0;
    clim_dIdV_maxIV = 1.1*max(max(abs(data_dIdV)));
    clim_thermoV_minIV = -1.1*max(max(abs(data_thermoV)));
    clim_thermoV_maxIV = 1.1*max(max(abs(data_thermoV)));
else
    clim_IV_minIV = sweep.clim(1);
    clim_IV_maxIV = sweep.clim(2);
    clim_dIdV_minIV = sweep.clim(3);
    clim_dIdV_maxIV = sweep.clim(4);
    clim_thermoV_minIV = sweep.clim(5);
    clim_thermoV_maxIV = sweep.clim(6);
end

% surf IV
subplot(2,3,4)
surf(sweep.x_axis, sweep.Bias2, data_IV,'edgecolor','interp')
view([0 90])
set(gca,'fontsize',20,'box','on')
set(gcf,'Color','white')
ylabel(Settings.Labels.Y_2D)
xlabel(Settings.Labels.X_2D)
xlabel('Gate voltage (V)')
ylabel('Bias voltage (V)')
try set(gca,'clim',[clim_IV_minIV clim_IV_maxIV]); end
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
try set(gca,'clim',[clim_dIdV_minIV clim_dIdV_maxIV]); end
colorbar

% surf thermovoltage
subplot(2,3,6)
surf(sweep.x_axis, sweep.Bias2, data_thermoV * 1e6,'edgecolor','interp')
view([0 90])
set(gca,'fontsize',20,'box','on')
set(gcf,'Color','white')
xlabel('Gate voltage (V)')
ylabel('Bias voltage (V)')
set(gca,'xlim',[min(sweep.x_axis) max(sweep.x_axis)]);
set(gca,'ylim',[sweep.minV sweep.maxV]);
try set(gca,'clim',[clim_thermoV_minIV clim_thermoV_maxIV]); end
colorbar

drawnow

return