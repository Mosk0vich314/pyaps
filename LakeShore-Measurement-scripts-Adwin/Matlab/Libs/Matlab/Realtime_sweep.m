function sweep = Realtime_sweep(Settings, sweep, figure_name)

%% create legend
LEG = cell(Settings.N_ADC, 1);
for i = 1:Settings.N_ADC
    LEG{i} = sprintf('ADC %1.0f', i);
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
    set(gca,'xlim',[sweep.minV sweep.maxV])
    if strcmp(Settings.type,'VI')
        set(gca,'xlim',[sweep.minI sweep.maxI])
    end

    subplot(1,2,2);
    set(gca,'Fontsize',20,'box','on')
    set(gcf,'color','white','Inverthardcopy','off')
    xlabel(Settings.Labels.X_1D)
    ylabel(Settings.Labels.Y_1D)
    set(gca,'yscale','log')
    set(gca,'xlim',[sweep.minV sweep.maxV])
    if strcmp(Settings.type,'VI')
        set(gca,'xlim',[sweep.minI sweep.maxI])
    end

    %% linear subplot
    handles = guidata(fig);

    subplot(1,2,1);
    Colors = [0 0.4470 0.7410; 0.8500 0.3250 0.0980; 0.9290 0.6940 0.1250; 0.4940 0.1840 0.5560; 0.4660 0.6740 0.1880; 0.3010 0.7450 0.9330; 0.6350 0.0780 0.1840; 0 0 0];

    if Settings.res4p == 1
        for i = 1:Settings.N_ADC/2
            handles.h(i) = animatedline('Color',Colors(i,:),'LineWidth',1.5);
        end
    else
        for i = 1:Settings.N_ADC
            handles.h(i) = animatedline('Color',Colors(i,:),'LineWidth',1.5);
        end
    end

    leg = legend(LEG);
    set(leg,'box','off','fontsize',12)

    %% log subplot
    subplot(1,2,2);
    if Settings.res4p == 1
        for i = 1:Settings.N_ADC/2
            handles.h_log(i) = animatedline('Color',Colors(i,:),'LineWidth',1.5);
        end
    else
        for i = 1:Settings.N_ADC
            handles.h_log(i) = animatedline('Color',Colors(i,:),'LineWidth',1.5);
        end
    end
    leg = legend(LEG);
    set(leg,'box','off','fontsize',12)

    guidata(fig,handles)
else

    handles = guidata(fig);
    if Settings.res4p == 1
        for i = 1:Settings.N_ADC / 2
            clearpoints(handles.h(i));
            clearpoints(handles.h_log(i));
        end
    else

        for i = 1:Settings.N_ADC
            clearpoints(handles.h(i));
            clearpoints(handles.h_log(i));
        end
    end
    guidata(fig,handles)
end

drawnow

%% initialize
previous_counter = 0;
pause(0.2);

%% run loop
run = true;
array = Settings.ADC_idx + 1;

while run && Get_Par(25) > 0

    run = Process_Status(1);
    actual_time = Get_Par(25) - 1;

    %% get current and update plot
    temp = zeros(length(array), actual_time - previous_counter);
    try

        for i = 1:Settings.N_ADC
            temp(i,:) = GetData_Double(array(i), previous_counter + 1, actual_time - previous_counter);
        end
        if strcmp(Settings.type,'IV')
            if Settings.res4p == 1
                for i = 1:Settings.N_ADC/2
                    addpoints(handles.h(i), sweep.bias(previous_counter + 1 : actual_time), temp((i-1)*2 + 1,:)./temp((i-1)*2 + 2,:));
                    addpoints(handles.h_log(i), sweep.bias(previous_counter + 1 : actual_time), abs(temp((i-1)*2 + 1,:)./temp((i-1)*2 + 2,:)));
                end
            else
                for i = 1:Settings.N_ADC
                    addpoints(handles.h(i), sweep.bias(previous_counter + 1 : actual_time), temp(i,:));
                    addpoints(handles.h_log(i), sweep.bias(previous_counter + 1 : actual_time), abs(temp(i,:)));
                end
            end
        elseif strcmp(Settings.type,'Gatesweep')
            if Settings.res4p == 1
                for i = 1:Settings.N_ADC/2
                    addpoints(handles.h(i), sweep.bias(previous_counter + 1 : actual_time), temp((i-1)*2 + 1,:)./temp((i-1)*2 + 2,:));
                    addpoints(handles.h_log(i), sweep.bias(previous_counter + 1 : actual_time), abs(temp((i-1)*2 + 1,:)./temp((i-1)*2 + 2,:)));
                end
            else
                for i = 1:Settings.N_ADC
                    addpoints(handles.h(i), sweep.bias(previous_counter + 1 : actual_time), temp(i,:));
                    addpoints(handles.h_log(i), sweep.bias(previous_counter + 1 : actual_time), abs(temp(i,:)));
                end
            end
        elseif strcmp(Settings.type,'VI')
            for i = 1:Settings.N_ADC
                addpoints(handles.h(i), sweep.bias(previous_counter + 1 : actual_time) * sweep.VIgain, temp(i,:));
                addpoints(handles.h_log(i), sweep.bias(previous_counter + 1 : actual_time) * sweep.VIgain, abs(temp(i,:)));
            end
        elseif strcmp(Settings.type,'Gatesweep_4p_I')
            for i = 1:Settings.N_ADC
                addpoints(handles.h(i), sweep.bias(previous_counter + 1 : actual_time), temp(i,:) / sweep.current_bias);
                addpoints(handles.h_log(i), sweep.bias(previous_counter + 1 : actual_time), abs(temp(i,:)) / sweep.current_bias);
            end
        elseif strcmp(Settings.type,'Gatesweep_4p_Vac')
            addpoints(handles.h(1), sweep.bias(previous_counter + 1 : actual_time), temp(5,:) ./ temp(3,:));
            addpoints(handles.h_log(1), sweep.bias(previous_counter + 1 : actual_time), abs(temp(5,:) ./ temp(3,:)));
            addpoints(handles.h(2), sweep.bias(previous_counter + 1 : actual_time), sweep.fixed_bias * 1e-3  ./ temp(3,:));
            addpoints(handles.h_log(2), sweep.bias(previous_counter + 1 : actual_time), abs(sweep.fixed_bias * 1e-3  ./ temp(3,:)));
        else
            for i = 1:Settings.N_ADC
                addpoints(handles.h(i), sweep.bias(previous_counter + 1 : actual_time), temp(i,:));
                addpoints(handles.h_log(i), sweep.bias(previous_counter + 1 : actual_time), abs(temp(i,:)));
            end
        end
        drawnow limitrate

        %% prepare for next iteration
        previous_counter = actual_time;
    end

end

%% get final current
if strcmp(Settings.type,'Gatesweep_4p_I')
    for i = 1:Settings.N_ADC
        sweep.current{i}(:, sweep.index) = GetData_Double(array(Settings.ADC_idx(i)), 1, sweep.NumBias) / sweep.current_bias;
    end
else
    for i = 1:Settings.N_ADC
        sweep.current{i}(:, sweep.index) = GetData_Double(array(i), 1, sweep.NumBias);
    end
end

return