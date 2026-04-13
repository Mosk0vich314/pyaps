function Timetrace = Realtime_timetrace_monitor_heaters(Settings, Timetrace, figure_name)

%% start figure
fig = findobj('Type', 'Figure', 'Name', figure_name);
if isempty(fig)
    fig = figure('Name', figure_name);
    set(gcf,'units','normalized')
    set(fig, 'Position', Settings.plot_position)
    
    % DC voltage 1 and 2 
    subplot(1,3,1)
    set(gca,'fontsize',16,'box','on')
    set(gcf,'Color','white')
    ylabel('DC Voltage (V)')
    xlabel('Time (s)')
%     set(gca,'xlim',[0 1]);
    handles.h(1) = animatedline('LineWidth',1.5);
    handles.h(2) = animatedline('LineWidth',1.5);
    
    % AC Heater 1
    subplot(1,3,2)
    set(gca,'fontsize',16,'box','on')
    set(gcf,'Color','white')
    ylabel('Resistance Heater 1 (\Omega)')
    xlabel('Time (s)')
%     set(gca,'xlim',[0 1]);
    handles.h(3) = animatedline('LineWidth',1.5);
    handles.h(4) = animatedline('LineWidth',1.5);
    
    % AC Heater 2
    subplot(1,3,3)
    set(gca,'fontsize',16,'box','on')
    set(gcf,'Color','white')
    ylabel('Resistance Heater 2 (\Omega)')
    xlabel('Time (s)')
%     set(gca,'xlim',[0 1]);
    handles.h(5) = animatedline('LineWidth',1.5);
    handles.h(6) = animatedline('LineWidth',1.5);
    
    guidata(fig,handles)
    
else
    
    handles = guidata(fig);
    
end

drawnow


%% initialize
previous_counter = 1;
pause(0.2);

%% run loop
run = true;
while run && Get_Par(19) > 0
    
    run = Process_Status(2);
    actual_time = Get_Par(19) - 1;
    
    %% get current and update plot
    array = 2:9;
    for i = 1:Settings.N_ADC
        try
            temp = GetData_Double(array(Settings.ADC_idx(i)), previous_counter + 1, actual_time - previous_counter);
            t = Timetrace.time_per_point * (previous_counter + 1 : actual_time);
            addpoints(handles.h(i),t, temp);
        end
        drawnow limitrate
    end
        
    %% prepare for next iteration
    previous_counter = actual_time;
end

%% get final current
array = 2:9;
for i = 1:Settings.N_ADC
    Timetrace.data{i}(:, Timetrace.index, Timetrace.index2) = GetData_Double(array(Settings.ADC_idx(i)), 1, Timetrace.runtime_counts);
end

return