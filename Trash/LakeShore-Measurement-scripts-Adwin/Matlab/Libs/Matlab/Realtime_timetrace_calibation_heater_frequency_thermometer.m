function [Timetrace, Lockin1] = Realtime_timetrace_calibation_heater_frequentie_thermometer(Settings, Timetrace, Lockin1, I_source, figure_name)

%% initialize figure
fig = findobj('Type', 'Figure', 'Name', figure_name);
% if Timetrace.index == 1
if isempty(fig)
    
    fig = figure('Name', figure_name);
    set(gcf,'units','normalized')
    set(fig, 'Position', Settings.plot_position)

    cmap = colormap(parula); 
    colors = cmap(round(linspace(1, length(cmap), Lockin1.N_frequency)), :);

    set(gcf,'color','white','Inverthardcopy','off')
    subplot(2, 2, 1);hold on
    set(gca,'box','on','fontsize',16)
    %set(gca,'xlim',[Lockin1.amplitude(1) Lockin1.amplitude(end)])
    xlabel('Heater frequency (Hz)')
    ylabel('X_{2\omega} (\Omega)')

    subplot(2, 2, 2);hold on
    set(gca,'box','on','fontsize',16)
    %set(gca,'xlim',[Lockin1.amplitude(1) Lockin1.amplitude(end)])
    xlabel('Heater frequency (Hz)')
    ylabel('Y_{2\omega} (\Omega)')

    subplot(2, 2, 3);hold on
    set(gca,'box','on','fontsize',16)
    %set(gca,'xlim',[Lockin1.amplitude(1) Lockin1.amplitude(end)])
    xlabel('Heater frequency (Hz)')
    ylabel('4-point resistance - DC (\Omega)')

    subplot(2, 2, 4);hold on
    set(gca,'box','on','fontsize',16)
    set(gca,'xlim',[0 Timetrace.runtime])
    xlabel('Time (s)')
    ylabel('Y_{2\omega} (V)')

end
if Timetrace.index == 1
    Lockin1.voltage = zeros(Timetrace.repeat, 6);
end

% run loop
pause(0.1);
run = true;
while run && Get_Par(25) >= 0
    run = Process_Status(2);
end

%% get final current
array = 2:9;
for i = 1:Settings.N_ADC
    Timetrace.data{i}(:, Timetrace.index, 1, 1) = GetData_Double(array(Settings.ADC_idx(i)), 1, Timetrace.runtime_counts);
end

idx = round(Timetrace.integration_periods/(Timetrace.integration_periods + ceil(Lockin1.wait_time * Lockin1.timeconstant * Lockin1.frequency ))*Timetrace.runtime_counts);

Lockin1.voltage(Timetrace.index,1) = mean(Timetrace.data{1}(end - idx:end,Timetrace.index)); % thermometer 1 - DC resistance
Lockin1.voltage(Timetrace.index,2) = mean(Timetrace.data{2}(end - idx:end,Timetrace.index)); % thermometer 2 - DC resistance
Lockin1.voltage(Timetrace.index,3) = mean(Timetrace.data{3}(end - idx:end,Timetrace.index)); % thermometer 1 - X
Lockin1.voltage(Timetrace.index,4) = mean(Timetrace.data{4}(end - idx:end,Timetrace.index)); % thermometer 1 - Y
Lockin1.voltage(Timetrace.index,5) = mean(Timetrace.data{5}(end - idx:end,Timetrace.index)); % thermometer 2 - X
Lockin1.voltage(Timetrace.index,6) = mean(Timetrace.data{6}(end - idx:end,Timetrace.index)); % thermometer 2 - Y

Lockin1.resistance(Timetrace.index,1) = Lockin1.voltage(Timetrace.index,1) / I_source.current1* 1e6; % thermometer 1 - DC resistance
Lockin1.resistance(Timetrace.index,2) = Lockin1.voltage(Timetrace.index,2) / I_source.current1* 1e6; % thermometer 2 - DC resistance
Lockin1.resistance(Timetrace.index,3) = Lockin1.voltage(Timetrace.index,3) / I_source.current1* 1e6; % thermometer 1 - X
Lockin1.resistance(Timetrace.index,4) = Lockin1.voltage(Timetrace.index,4) / I_source.current1* 1e6; % thermometer 1 - Y
Lockin1.resistance(Timetrace.index,5) = Lockin1.voltage(Timetrace.index,5) / I_source.current1 * 1e6; % thermometer 2 - X
Lockin1.resistance(Timetrace.index,6) = Lockin1.voltage(Timetrace.index,6) / I_source.current1 * 1e6; % thermometer 2 - Y

%% make plot
figure(fig);
subplot(2, 2, 1);hold on
plot(Lockin1.frequencies(Timetrace.index), Lockin1.resistance(Timetrace.index,3), '.','markersize',24,'color',[0, 0.4470, 0.7410])
plot(Lockin1.frequencies(Timetrace.index), Lockin1.resistance(Timetrace.index,5) , '.','markersize',24,'color',[0.8500, 0.3250, 0.0980])
leg = legend('Thermometer 1', 'Thermometer 2');
set(leg,'fontsize',16,'box','off')

subplot(2, 2, 2);hold on
plot(Lockin1.frequencies(Timetrace.index), Lockin1.resistance(Timetrace.index,4) , '.','markersize',24,'color',[0, 0.4470, 0.7410])
plot(Lockin1.frequencies(Timetrace.index), Lockin1.resistance(Timetrace.index,6) , '.','markersize',24,'color',[0.8500, 0.3250, 0.0980])
leg = legend('Thermometer 1', 'Thermometer 2');
set(leg,'fontsize',16,'box','off')

subplot(2, 2, 3);hold on
plot(Lockin1.frequencies(Timetrace.index), Lockin1.resistance(Timetrace.index,1) , '.','markersize',24,'color',[0, 0.4470, 0.7410])
plot(Lockin1.frequencies(Timetrace.index), Lockin1.resistance(Timetrace.index,2) , '.','markersize',24,'color',[0.8500, 0.3250, 0.0980])
leg = legend('Thermometer 1', 'Thermometer 2');
set(leg,'fontsize',16,'box','off')

subplot(2, 2, 4);hold on
plot(Timetrace.time, Timetrace.data{4}(:,Timetrace.index) , '.','markersize',24)
drawnow

return