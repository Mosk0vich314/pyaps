function fig = Realtime_timetrace_T_calibration_T_dep(Settings, Timetrace, figure_name)

%% start figure
fig = findobj('Type', 'Figure', 'Name', figure_name);
line_colors = lines(3);

if isempty(fig)
    fig = figure('Name', figure_name);
    set(gcf,'units','normalized')
    set(fig, 'Position', Settings.plot_position)
    handles = guidata(fig);

    % init
    
    handles.ax = [];
    Fontsize = 12;

    % 1D plots vs set T
    leg = zeros(numel(Settings.contacts), 1);
    for i = 1:2
        handles.ax_set_T.(Settings.signal{i}) = subplot(2, 3, i); hold on
        set(gca,'fontsize',Fontsize,'box','on')
        set(gcf,'Color','white')
        xlabel('Set temperature (K)')
        ylabel(['Resistance - ' Settings.signal{i} ' (\Omega)'])
        set(gca,'xlim',[min(Settings.temperature_no_heater) max(Settings.temperature_no_heater)]);


        for j = 1:numel(Settings.contacts)
            handles.animated_lines_set_T.(Settings.signal{i}).(Settings.contacts{j}) = animatedline('LineWidth',1.5,'Parent',handles.ax_set_T.(Settings.signal{i}),'Color', line_colors(j,:));
        end

        leg(i) = legend(Settings.contacts);
        set(leg(i), 'box','off','location','northwest')
    end

    % 1D plots vs measured T
    leg = zeros(numel(Settings.contacts), 1);
    for i = 1:2
        handles.ax_meas_T.(Settings.signal{i}) = subplot(2, 3, i + 3); hold on
        set(gca,'fontsize',Fontsize,'box','on')
        set(gcf,'Color','white')
        xlabel('Measured temperature (K)')
        ylabel(['Resistance - ' Settings.signal{i} ' (\Omega)'])
        set(gca,'xlim',[min(Settings.temperature_no_heater) max(Settings.temperature_no_heater)]);


        for j = 1:numel(Settings.contacts)
            handles.animated_lines_meas_T.(Settings.signal{i}).(Settings.contacts{j}) = animatedline('LineWidth',1.5,'Parent',handles.ax_meas_T.(Settings.signal{i}),'Color', line_colors(j,:));
        end

        leg(i) = legend(Settings.contacts);
        set(leg(i), 'box','off','location','northwest')
    end

    % line plot measured T vs set T 
    handles.ax_T_vs_T = subplot(2, 3, 3); hold on
    handles.ax_T_vs_T.Position = handles.ax_T_vs_T.Position - [0 0.3 0 0];

    set(gca,'fontsize',Fontsize,'box','on')
    set(gcf,'Color','white')
    xlabel('Set temperature (K)')
    ylabel('Measured temperature (K)')
    set(gca,'xlim',[min(Settings.temperature_no_heater) max(Settings.temperature_no_heater)]);

    handles.animated_lines_T_vs_T = animatedline('LineWidth',1.5,'Parent',handles.ax_T_vs_T,'Color', lines(1));

    guidata(fig, handles)

else

    handles = guidata(fig);

end

%% update line plots - set T
demod = sprintf('demod%01d', 1);
for i = 1:Timetrace.N_devices
    for j = 1:2
        addpoints(handles.animated_lines_set_T.(Settings.signal{j}).(Settings.contacts{i}), Settings.temperature_no_heater(Timetrace.index), ...
            Timetrace.no_heater.short.(Settings.contacts{i}).(demod).(Settings.signal{j}).mean(Timetrace.index));
    end
end

%% update line plots - measured T
demod = sprintf('demod%01d', 1);
for i = 1:Timetrace.N_devices
    for j = 1:2
        addpoints(handles.animated_lines_meas_T.(Settings.signal{j}).(Settings.contacts{i}), Timetrace.no_heater.short.T.mean(2), ...
            Timetrace.no_heater.short.(Settings.contacts{i}).(demod).(Settings.signal{j}).mean(Timetrace.index));
    end
end

%% update measured T vs set T plot
addpoints(handles.animated_lines_T_vs_T, Settings.temperature_no_heater(Timetrace.index), Timetrace.no_heater.short.T.mean(2));

return
