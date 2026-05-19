function sweep = Realtime_sweep_tripleGate(Settings, sweep, figure_name)

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
    
    % individual IVs lin
    subplot(1,2,1)
    hold on
    set(gca,'fontsize',20,'box','on')
    set(gcf,'Color','white')
    ylabel(Settings.Labels.Y_1D)
    xlabel(Settings.Labels.X_1D)
    set(gca,'xlim',[sweep.minV*1.05 sweep.maxV*1.05]);
    
    % individual IVs log
    subplot(1,2,2)
    hold on
    set(gca,'fontsize',20,'box','on')
    set(gcf,'Color','white')
    ylabel(Settings.Labels.Y_1D)
    xlabel(Settings.Labels.X_1D)
    set(gca,'xlim',[sweep.minV*1.05 sweep.maxV*1.05]);
    set(gca,'yscale','log')
    
    
    %% linear subplot
    handles = guidata(fig);
        
    subplot(1,2,1)
    Colors = [0 0.4470 0.7410; 0.8500 0.3250 0.0980; 0.9290 0.6940 0.1250; 0.4940 0.1840 0.5560; 0.4660 0.6740 0.1880; 0.3010 0.7450 0.9330; 0.6350 0.0780 0.1840; 0 0 0];
    for i = 1:Settings.N_ADC
        handles.h(i) = animatedline('Color',Colors(i,:),'LineWidth',1.5);
    end
    
    %% log subplot
    subplot(1,2,2)
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
while run && Get_Par(25) > 0
    
    run = Process_Status(1);
    actual_time = Get_Par(25) - 1;
    
    %% get current and update plot
    array = 2:9;
    for i = 1:Settings.N_ADC
        try
            temp = GetData_Double(array(Settings.ADC_idx(i)), previous_counter + 1, actual_time - previous_counter);
            addpoints(handles.h(i), sweep.bias(previous_counter + 1 : actual_time), temp);
            addpoints(handles.h_log(i), sweep.bias(previous_counter + 1 : actual_time), abs(temp));
        end
        drawnow limitrate
    end
    
    %% add legend
    subplot(1,2,1)
    leg = legend(LEG);
    set(leg,'box','off','fontsize',12)
    subplot(1,2,2)
    leg = legend(LEG);
    set(leg,'box','off','fontsize',12)
    drawnow
    
    %% prepare for next iteration
    previous_counter = actual_time;
end

%% get final current
array = 2:9;
if ~isfield(sweep,'index2')
    sweep.index = 1;
end

for i = 1:Settings.N_ADC
    sweep.current{i}(:, sweep.index, sweep.index2) = GetData_Double(array(Settings.ADC_idx(i)), 1, sweep.NumBias);
end


%% save figure

% saveas(fig, sprintf('%s/%s_%s_%s.png', Settings.save_dir, Settings.filename, Settings.sample, Settings.type))

return