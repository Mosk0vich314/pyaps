function Static = Realtime_sweep_MCBJ_feedback(Settings, Static, Bias, figure_name)

%% create legend
LEG{1} = 'Conductance versus applied voltage';
LEG{2} = 'Conductance versus measured voltage';

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
    % set(gca,'xlim',[sweep.minV sweep.maxV])

    subplot(1,2,2);
    set(gca,'Fontsize',20,'box','on')
    set(gcf,'color','white','Inverthardcopy','off')
    xlabel(Settings.Labels.X_1D)
    ylabel(Settings.Labels.Y_1D)
    set(gca,'yscale','log')
    % set(gca,'xlim',[sweep.minV sweep.maxV])

    %% linear subplot
    handles = guidata(fig);

    subplot(1,2,1);
    Colors = [0 0.4470 0.7410; 0.8500 0.3250 0.0980; 0.9290 0.6940 0.1250; 0.4940 0.1840 0.5560; 0.4660 0.6740 0.1880; 0.3010 0.7450 0.9330; 0.6350 0.0780 0.1840; 0 0 0];

    handles.h = animatedline('Color',Colors(1,:),'LineWidth',1.5);
    handles.h_realV = animatedline('Color',Colors(2,:),'LineWidth',1.5);

    leg = legend(LEG);
    set(leg,'box','off','fontsize',12)

    %% log subplot
    subplot(1,2,2);

    handles.h_log = animatedline('Color',Colors(1,:),'LineWidth',1.5);
    handles.h_log_realV = animatedline('Color',Colors(2,:),'LineWidth',1.5);

    leg = legend(LEG);
    set(leg,'box','off','fontsize',12)

    %% add voltage text
    handles.text = title(sprintf('Static = %1.2fV, reading %1.2fV', 0, 0));
    
    %% update handles
    guidata(fig,handles)
else

    handles = guidata(fig);

    clearpoints(handles.h);
    clearpoints(handles.h_log);

    %% update handles
    guidata(fig,handles)
end

Static.figure = fig;
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

        %% get data
        for i = 1:Settings.N_ADC
            temp(i,:) = GetData_Double(array(i), previous_counter + 1, actual_time - previous_counter);
        end

        % size(temp)

        %% plot data
        addpoints(handles.h_realV, temp(2,:), temp(1,:) / Bias.setV / Settings.G0);
        addpoints(handles.h_log_realV, temp(2,:), abs(temp(1,:)) / Bias.setV / Settings.G0);

        addpoints(handles.h, Static.bias(previous_counter + 1:actual_time), temp(1,:) / Bias.setV / Settings.G0);
        addpoints(handles.h_log, Static.bias(previous_counter + 1:actual_time), abs(temp(1,:)) / Bias.setV / Settings.G0);

        drawnow limitrate

        %% update DC voltage text
        handles.text.String = sprintf('Static = %1.2fV, reading %1.2fV', convert_bin_to_V(Get_Par(24), Settings.output_max, Settings.output_resolution), Get_FPar(2));

        %% prepare for next iteration
        previous_counter = actual_time;

        %% stop if target current is reached
        if Static.direction == 0 % breaking
            if sum(temp(1,:) < Static.current_limit) ~= 0
                Stop_Process(1)
                Static.currentV = convert_bin_to_V(Get_Par(24), Settings.output_max, Settings.output_resolution);
            end
        end

        if Static.direction == 1 % making
            if sum(temp(1,:) > Static.current_limit) ~= 0
                Stop_Process(1)
                Static.currentV = convert_bin_to_V(Get_Par(24), Settings.output_max, Settings.output_resolution);
            end
        end
    end
end


return