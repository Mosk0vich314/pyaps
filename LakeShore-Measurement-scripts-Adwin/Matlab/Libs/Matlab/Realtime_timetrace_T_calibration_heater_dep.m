function fig = Realtime_timetrace_T_calibration_heater_dep(Settings, Timetrace, Lockin, figure_name)

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
    t = tiledlayout(numel(Settings.contacts), numel(Settings.signal));
    handles.ax = [];
    Fontsize = 12;

    % 1D plots
    for i = 1:numel(Settings.contacts)
        for j = 1:numel(Settings.signal)
            
            handles.ax.(Settings.contacts{i}).(Settings.signal{j}) = nexttile(t); hold on
            set(gca,'fontsize',Fontsize,'box','on')
            set(gcf,'Color','white')
            xlabel('Heater current (mA)')
            ylabel(['Resistance ' Settings.contacts{i} ' - ' Settings.signal{j} ' (\Omega)'])
            set(gca,'xlim',[Lockin.dev1.amplitude_heater_current(1) Lockin.dev1.amplitude_heater_current(end)]);

            colorbar;
            clim([min(Settings.temperature_no_heater) max(Settings.temperature_no_heater)])
            colormap(cmap)
        end
    end
   

    guidata(fig, handles);

else

    handles = guidata(fig);

end

%% make animated line plots
if Timetrace.index2 == 1
    for i = 1:numel(Settings.contacts)
        for j = 1:numel(Settings.signal)

            if Settings.temperature_no_heater(1) > Settings.temperature_no_heater(end)
                handles.animated_lines.(Settings.contacts{i}).(Settings.signal{j}) = animatedline('LineWidth',1.5,'Parent',handles.ax.(Settings.contacts{i}).(Settings.signal{j}),...
                    'Color', cmap(Settings.N_temp_no_heater + 1 - Timetrace.index,:),'Marker','.','MarkerSize',16);
            else
                handles.animated_lines.(Settings.contacts{i}).(Settings.signal{j}) = animatedline('LineWidth',1.5,'Parent',handles.ax.(Settings.contacts{i}).(Settings.signal{j}),...
                    'Color', cmap(Timetrace.index,:),'Marker','.','MarkerSize',16);
            end
        end
    end
end

%% update animated lines
for i = 1:numel(Settings.contacts)
    for j = 1:numel(Settings.signal)
        if i == 1
            demod = sprintf('demod%01d',1);
        else
            demod = sprintf('demod%01d',2);
        end
        addpoints(handles.animated_lines.(Settings.contacts{i}).(Settings.signal{j}), Lockin.dev1.amplitude_heater_current(Timetrace.index2), Timetrace.heater.short.(Settings.contacts{i}).(demod).(Settings.signal{j}).mean(Timetrace.index, Timetrace.index2));
    end
end


guidata(fig, handles);

return
