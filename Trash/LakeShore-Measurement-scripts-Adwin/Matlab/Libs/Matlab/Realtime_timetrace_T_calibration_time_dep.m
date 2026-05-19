function fig = Realtime_timetrace_T_calibration_time_dep(Settings, Timetrace, figure_name)

%% generate colormap
cmap = inferno(Settings.N_temp_no_heater);

%% start figure
fig = findobj('Type', 'Figure', 'Name', figure_name);

if isempty(fig)
    fig = figure('Name', figure_name);
    set(gcf,'units','normalized')
    set(fig, 'Position', Settings.plot_position)
    handles = guidata(fig);

    % init
    t = tiledlayout(2, 2);
    handles.ax = [];
    Fontsize = 12;

    % 1D plots
    for i = 1:numel(Settings.contacts)
        handles.ax.(Settings.contacts{i}) = nexttile(t); hold on
        set(gca,'fontsize',Fontsize,'box','on')
        set(gcf,'Color','white')
        xlabel('Time (s)')
        ylabel(['Resistance ' Settings.contacts{i} ' -X (\Omega)'])
        set(gca,'xlim',[0 Timetrace.runtime]);

        colorbar;
        clim([min(Settings.temperature_no_heater) max(Settings.temperature_no_heater)])
        colormap(cmap)
    end

    handles.ax.T = nexttile(t); hold on
    set(gca,'fontsize',Fontsize,'box','on')
    set(gcf,'Color','white')
    xlabel('Time (s)')
    ylabel('Measured temperature (K)')
    set(gca,'xlim',[0 Timetrace.runtime]);

    colorbar;
    clim([min(Settings.temperature_no_heater) max(Settings.temperature_no_heater)])
    colormap(cmap)

    guidata(fig, handles)

else

    handles = guidata(fig);

end

%% make update line plots
for i = 1:numel(Settings.contacts)
    demod = sprintf('demod%01d', 1);
    if Settings.temperature_no_heater(1) > Settings.temperature_no_heater(end)
        plot(Timetrace.no_heater.long.(Settings.contacts{i}).(demod).X.time{Timetrace.index}, Timetrace.no_heater.long.(Settings.contacts{i}).(demod).X.data{Timetrace.index},'Color', cmap(Settings.N_temp_no_heater + 1 - Timetrace.index,:),'Parent',handles.ax.(Settings.contacts{i}));
    else
        plot(Timetrace.no_heater.long.(Settings.contacts{i}).(demod).X.time{Timetrace.index}, Timetrace.no_heater.long.(Settings.contacts{i}).(demod).X.data{Timetrace.index},'Color', cmap(Timetrace.index,:),'Parent',handles.ax.(Settings.contacts{i}));
    end
end

%% update temperature plot
markers = {'.','o','*','x'};
for i = 1:Timetrace.get_T
    if Settings.temperature_no_heater(1) > Settings.temperature_no_heater(end)
        plot(Timetrace.no_heater.long.T.time, Timetrace.no_heater.long.T.data(:,i),'Color', cmap(Settings.N_temp_no_heater + 1 - Timetrace.index,:),'Parent',handles.ax.T, 'Marker',markers{i},'MarkerSize',12);
    else
        plot(Timetrace.no_heater.long.T.time, Timetrace.no_heater.long.T.data(:,i),'Color', cmap(Timetrace.index,:),'Parent',handles.ax.T, 'Marker',markers{i},'MarkerSize',12);
    end
end
return
