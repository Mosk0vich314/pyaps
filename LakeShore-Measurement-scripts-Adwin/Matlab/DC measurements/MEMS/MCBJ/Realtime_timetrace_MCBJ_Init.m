function [Timetrace, Initialize] = Realtime_timetrace_MCBJ_Init(Settings, Timetrace,  Bias, Initialize, figure_name)

%% start figure
fig = findobj('Type', 'Figure', 'Name', figure_name);
if isempty(fig)
    fig = figure('Name', figure_name);
    set(gcf,'units','normalized')
    set(fig, 'Position', Settings.plot_position)
else
    figure(fig);
    subplot(1,2,1);cla
    subplot(1,2,2);cla
end

Timetrace.fig = fig;

figure(fig);
subplot(1,2,1);
set(gca,'Fontsize',20,'box','on')
set(gcf,'color','white','Inverthardcopy','off')
xlabel('Time (s)')
ylabel('Conductance (G_0)')
titl = title('');

subplot(1,2,2);
set(gca,'Fontsize',20,'box','on')
set(gcf,'color','white','Inverthardcopy','off')
xlabel('Time (s)')
ylabel('Conductance (G_0)')
set(gca,'yscale','log')
drawnow

%% linear subplot
subplot(1,2,1);
Colors = [0 0.4470 0.7410; 0.8500 0.3250 0.0980; 0.9290 0.6940 0.1250; 0.4940 0.1840 0.5560; 0.4660 0.6740 0.1880; 0.3010 0.7450 0.9330; 0.6350 0.0780 0.1840; 0 0 0];
clear h h_log
h = animatedline('Color',Colors(1,:),'LineWidth',1.5);

%% log subplot
subplot(1,2,2);
h_log = animatedline('Color',Colors(1,:),'LineWidth',1.5);

%% initialize
previous_time = 0;
Initialize.status = 1; % no error

%% run loop
run = true;
while run

    if Get_Par(19) > 0
        run = Process_Status(2);
        actual_time = Get_Par(19) - 1;

        %% define time array
        time = (previous_time + 1 : actual_time) * Timetrace.time_per_point;

        %% get conductance and make plot
        try
            measured_I = GetData_Double(2, previous_time + 1, actual_time - previous_time);
            if Timetrace.runtime_counts > 50000
                skip = round(Timetrace.runtime_counts/50000);
                addpoints(h, time(1:skip:end), measured_I(1:skip:end) / Bias.setV / Settings.G0);
                addpoints(h_log, time(1:skip:end), abs(measured_I(1:skip:end)  / Bias.setV / Settings.G0 ));
            else
                addpoints(h, time, measured_I / Bias.setV / Settings.G0);
                addpoints(h_log, time, abs(measured_I) / Bias.setV / Settings.G0);
            end
            measured_V = GetData_Double(3, previous_time + 1, actual_time - previous_time);
        end

        drawnow limitrate

        %% prepare for next iteration
        previous_time = actual_time;

        %% store current V position
        Set_Par(80, Get_Par(40));

        %% display current Static voltage
        titl.String = sprintf('Static voltage applied = %1.2fV, measured = %1.2fV', convert_bin_to_V(Get_Par(40), Settings.output_max, Settings.output_resolution), measured_V(end));

        %% stop on target
        if Initialize.stop_on_target && Initialize.move_static

            % when breaking reached
            if Initialize.breaking == 0 &&  measured_I(end) > Initialize.targetI
                Stop_Process(2);
                Stop_Process(3);
                Initialize.status = 2;
            end

            % when making reached
            if Initialize.breaking == 1 && measured_I(end) < Initialize.targetI
                Stop_Process(2);
                Stop_Process(3);
                Initialize.status = 2;
            end
        end

        %% adjust setpoint
        if Initialize.stop_on_target == 0 && Initialize.move_static
            if Initialize.targetI > measured_I(end) % needs to break
                Set_Par(42, convert_V_to_bin(0, Settings.output_min, Settings.output_max, Settings.output_resolution)) % update in realtime for changing motion
            else
                Set_Par(42, convert_V_to_bin(10, Settings.output_min, Settings.output_max, Settings.output_resolution)) % update in realtime for changing motion
            end
        end

        %% check Static limits
        if Get_Par(40) > convert_V_to_bin(10, Settings.output_min, Settings.output_max, Settings.output_resolution) % cannot break
            Stop_Process(2);
            Stop_Process(3);
            Initialize.status = 3;
        end
        if Get_Par(40) < convert_V_to_bin(0, Settings.output_min, Settings.output_max, Settings.output_resolution) % cannot make
            Stop_Process(2);
            Stop_Process(3);
            Initialize.status = 4;
        end

    end
end

hold off

%% define time array
% Timetrace.time = 0:Timetrace.time_per_point:Timetrace.time_per_point * (Timetrace.runtime_counts-1);
% Timetrace.time_corr = GetData_Double(7, 1, Timetrace.runtime_counts) * (Timetrace.process_delay / Settings.clockfrequency);

%% get final voltage
array = 2:9;
for i = 1:Settings.N_ADC
    Timetrace.voltage{i} = (GetData_Double(array(Settings.ADC_idx(i)), 1, Timetrace.runtime_counts))';
end

return