function sweep = Realtime_sweep_feedback_EB(Settings, sweep, figure_name)

%% create legend
LEG = cell(Settings.N_ADC, 1);
for i=1:Settings.N_ADC
    LEG{i} = sprintf('ADC %1.0f', Settings.ADC_idx(i));
end

%% start figure
fig = findobj('Type', 'Figure', 'Name', figure_name);
if isempty(fig)
    fig = figure('Name', figure_name);
    set(gcf,'units','normalized')
    set(fig, 'Position', Settings.plot_position)
    
    subplot(1,2,1);
    set(gca,'Fontsize',20,'box','on')
    set(gcf,'color','white','Inverthardcopy','off')
    xlabel(Settings.Labels.X_1D)
    ylabel(Settings.Labels.Y_1D)
    set(gca,'xlim',[sweep.startV sweep.maxV])
    
    subplot(1,2,2);
    set(gca,'Fontsize',20,'box','on')
    set(gcf,'color','white','Inverthardcopy','off')
    xlabel(Settings.Labels.X_1D)
    ylabel(Settings.Labels.Y_1D)
    set(gca,'yscale','log')
    set(gca,'xlim',[sweep.startV sweep.maxV])
    
    %% linear subplot
    handles = guidata(fig);

    subplot(1,2,1);
    Colors = [0 0.4470 0.7410; 0.8500 0.3250 0.0980; 0.9290 0.6940 0.1250; 0.4940 0.1840 0.5560];
    for i = 1:Settings.N_ADC
        handles.h(i) = animatedline('Color',Colors(i,:),'LineWidth',1.5);
    end
    
    %% log subplot
    subplot(1,2,2);
    for i = 1:Settings.N_ADC
        handles.h_log(i) = animatedline('Color',Colors(i,:),'LineWidth',1.5);
    end

    guidata(fig,handles)
else
    
    handles = guidata(fig);

    for i = 1:Settings.N_ADC
        clearpoints(handles.h(i));
        clearpoints(handles.h_log(i));
    end
    guidata(fig,handles)
end

drawnow
%% initialize
previous_counter = 1;
pause(0.2);

%% run loop
run = true;


while run && Get_Par(25) > 0 && Get_Par(31) == 0
    
    run = Process_Status(sweep.process_number);
    actual_time = Get_Par(25) - 1;
    tempV = GetData_Double(1, previous_counter + 1, actual_time - previous_counter) * sweep.V_per_V;    
    
    %% get current and update plot
    array = 2:5;
    for i = 1:Settings.N_ADC
        try
            temp = GetData_Double(array(Settings.ADC_idx(i)), previous_counter + 1, actual_time - previous_counter);
%             tempR = tempV/temp;
            addpoints(handles.h(i), tempV, temp);
            addpoints(handles.h_log(i), tempV, abs(temp));
%             addpoints(handles.h_log(i), tempV, tempR);
        end
        drawnow limitrate
    end
    
    %% add legend
    subplot(1,2,1);
    leg = legend(LEG);
    set(leg,'box','off','fontsize',12)
    subplot(1,2,2);
    leg = legend(LEG);
    set(leg,'box','off','fontsize',12)
    drawnow

    %% prepare for next iteration
    previous_counter = actual_time;
end

%% get final current
sweep.NumBias = Get_Par(25) - 1;
sweep.bias = GetData_Double(1, 1, sweep.NumBias) * sweep.V_per_V;
sweep.data = GetData_Double(2, 1, sweep.NumBias);

sweep.current{sweep.index} = [sweep.bias' sweep.data'];


saveas(fig, sprintf('%s/%s_%s_%s.png', Settings.save_dir, Settings.filename, Settings.sample, Settings.type))

return