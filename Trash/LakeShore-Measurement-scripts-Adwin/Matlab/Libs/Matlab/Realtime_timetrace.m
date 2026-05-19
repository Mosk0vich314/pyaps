function Timetrace = Realtime_timetrace(Settings, Timetrace, figure_name)

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
else
    figure(fig);
    subplot(1,2,1);cla
    subplot(1,2,2);cla
end

figure(fig);
subplot(1,2,1);
set(gca,'Fontsize',20,'box','on')
set(gcf,'color','white','Inverthardcopy','off')
xlabel('Time (s)')
ylabel('Voltage (V) * Gain')
leg = legend(LEG);
set(leg,'box','off','fontsize',12)

subplot(1,2,2);
set(gca,'Fontsize',20,'box','on')
set(gcf,'color','white','Inverthardcopy','off')
xlabel('Time (s)')
ylabel('|Voltage (V) * Gain|')
set(gca,'yscale','log')
leg = legend(LEG);
set(leg,'box','off','fontsize',12)
drawnow

%% linear subplot
subplot(1,2,1);
Colors = [0 0.4470 0.7410; 0.8500 0.3250 0.0980; 0.9290 0.6940 0.1250; 0.4940 0.1840 0.5560; 0.4660 0.6740 0.1880; 0.3010 0.7450 0.9330; 0.6350 0.0780 0.1840; 0 0 0];
clear h h_log
for i = 1:Settings.N_ADC
    h(i) = animatedline('Color',Colors(i,:),'LineWidth',1.5);
end
leg = legend(LEG);
set(leg,'box','off','fontsize',12)

%% log subplot
subplot(1,2,2);
for i = 1:Settings.N_ADC
    h_log(i) = animatedline('Color',Colors(i,:),'LineWidth',1.5);
end
leg = legend(LEG);
set(leg,'box','off','fontsize',12)

%% initialize
previous_time = 0;

%% run loop
run = true;
while run

    if Get_Par(19) > 0
        run = Process_Status(2);
        actual_time = Get_Par(19) - 1;

        %% define time array
        time = (previous_time + 1 : actual_time) * Timetrace.time_per_point;

        %% get voltage and make plot
        array = 2:9;
        for i = 1:Settings.N_ADC
            try
                temp = GetData_Double(array(Settings.ADC_idx(i)), previous_time + 1, actual_time - previous_time);
                if Timetrace.runtime_counts > 50000
                    skip = round(Timetrace.runtime_counts/50000);
                    addpoints(h(i), time(1:skip:end), temp(1:skip:end));
                    addpoints(h_log(i), time(1:skip:end), abs(temp(1:skip:end)));
                else
                    addpoints(h(i), time, temp);
                    addpoints(h_log(i), time, abs(temp));
                end
            end
            drawnow limitrate
        end

        %% prepare for next iteration
        previous_time = actual_time;
    end
end

hold off

%% define time array
Timetrace.time = 0:Timetrace.time_per_point:Timetrace.time_per_point * (Timetrace.runtime_counts-1);
% Timetrace.time_corr = GetData_Double(7, 1, Timetrace.runtime_counts) * (Timetrace.process_delay / Settings.clockfrequency);

%% get final voltage
array = 2:9;
for i = 1:Settings.N_ADC
    Timetrace.voltage{i}(:,Timetrace.index) = (GetData_Double(array(Settings.ADC_idx(i)), 1, Timetrace.runtime_counts))';
end

return