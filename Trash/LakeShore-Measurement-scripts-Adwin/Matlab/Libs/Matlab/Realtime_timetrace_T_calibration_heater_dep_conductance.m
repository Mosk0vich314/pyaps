function fig = Realtime_timetrace_T_calibration_heater_dep_conductance(Settings, Timetrace, Lockin, figure_name)

%% generate colormap
cmap = inferno(Settings.N_temp_no_heater);

%% start figure
fig = findobj('Type', 'Figure', 'Name', figure_name);

i = 2;
j = 1;

if isempty(fig)
    fig = figure('Name', figure_name);
    set(gcf,'units','normalized')
    set(fig, 'Position', Settings.plot_position)
    handles = guidata(fig);

    % init
    Fontsize = 12;
    handles.ax = gca; hold on
    set(gca,'fontsize',Fontsize,'box','on')
    set(gcf,'Color','white')
    xlabel('Heater current (mA)')
    ylabel(['AC Resistance ' Settings.contacts{i} ' - ' Settings.signal{j} ' (\Omega)'])
    set(gca,'xlim',[Lockin.dev1.amplitude_heater_current(1) Lockin.dev1.amplitude_heater_current(end)]);

    colorbar;
    clim([min(Settings.temperature_no_heater) max(Settings.temperature_no_heater)])
    colormap(cmap)

    guidata(fig, handles);

else

    handles = guidata(fig);

end

%% make animated line plots
if Timetrace.index2 == 1
    if Settings.temperature_no_heater(1) > Settings.temperature_no_heater(end)
        handles.animated_lines = animatedline('LineWidth',1.5,'Parent', handles.ax,...
            'Color', cmap(Settings.N_temp_no_heater + 1 - Timetrace.index,:),'Marker','.','MarkerSize',16);
    else
        handles.animated_lines = animatedline('LineWidth',1.5,'Parent',handles.ax,...
            'Color', cmap(Timetrace.index,:),'Marker','.','MarkerSize',16);
    end
end

%% update animated lines
demod = sprintf('demod%01d',4);
addpoints(handles.animated_lines, Lockin.dev1.amplitude_heater_current(Timetrace.index2), Timetrace.heater.short.(Settings.contacts{i}).(demod).(Settings.signal{j}).mean(Timetrace.index, Timetrace.index2));

guidata(fig, handles);

return
