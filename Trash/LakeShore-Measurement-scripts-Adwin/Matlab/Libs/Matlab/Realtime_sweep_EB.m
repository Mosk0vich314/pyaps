function sweep = Realtime_sweep_EB(Settings, sweep, figure_name)

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
%     set(gca,'xlim',[sweep.minV sweep.maxV])
    
    subplot(1,2,2);
    set(gca,'Fontsize',20,'box','on')
    set(gcf,'color','white','Inverthardcopy','off')
    xlabel(Settings.Labels.X_1D)
    ylabel(Settings.Labels.X_2D)
%     set(gca,'xlim',[sweep.minV sweep.maxV])
    
    %% linear subplot
    handles = guidata(fig);

    subplot(1,2,1);
    Colors = [0 0.4470 0.7410; 0.8500 0.3250 0.0980; 0.9290 0.6940 0.1250; 0.4940 0.1840 0.5560];
    for i = 1:2
        handles.V(i) = animatedline('Color',Colors(i,:),'LineWidth',1.5);
    end
    
    %% log subplot
    subplot(1,2,2);
    for i = 1:2
        handles.R(i) = animatedline('Color',Colors(i,:),'LineWidth',1.5);
    end

    guidata(fig,handles)
else
    
    handles = guidata(fig);

    for i = 1:2
        clearpoints(handles.R(i));
        clearpoints(handles.V(i));
    end
    guidata(fig,handles)
end

drawnow
%% initialize
previous_counter = 1;
pause(0.2);

%% run loop
run = true;
while run && Get_Par(71) > 0   
    
    run = Process_Status(sweep.process_number);
    actual_time = Get_Par(71) - 1;
        
    %% get current and update plot
    array = 2:5;
    temp = zeros(actual_time - previous_counter, length(array));
    temp1 = zeros(actual_time - previous_counter, length(array));
    for i = 1:length(array)
        try
            temp(:,i) = GetData_Double(array(Settings.ADC_idx(i)), previous_counter + 1, actual_time - previous_counter);
            temp1(:,i) = GetData_Double(5, previous_counter + 1, actual_time - previous_counter);
        end
        drawnow limitrate
    end
    
    addpoints(handles.V(1), (previous_counter + 1 : actual_time), temp(:,1));
    addpoints(handles.V(2), (previous_counter + 1 : actual_time), temp(:,2));
    addpoints(handles.R(1), (previous_counter + 1 : actual_time), abs(temp1(:,1)));
            
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
array = 2:5;
for i = 1:Settings.N_ADC
    sweep.data{i}(:, sweep.index) = GetData_Double(array(Settings.ADC_idx(i)), 1, sweep.NumBias);
    sweep.Voltage{i}(:, sweep.index) = GetData_Double(5, 1, sweep.NumBias);
end

saveas(fig, sprintf('%s/%s_%s_%s.png', Settings.save_dir, Settings.filename, Settings.sample, Settings.type))

return