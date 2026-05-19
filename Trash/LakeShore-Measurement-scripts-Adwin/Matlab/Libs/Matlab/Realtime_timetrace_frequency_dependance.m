function [Timetrace, Lockin1] = Realtime_timetrace_frequency_dependance(Settings, Timetrace, Lockin1, figure_name)
%% initialize figure
fig = findobj('Type', 'Figure', 'Name', figure_name);

% if Timetrace.index == 1

if isempty(fig)
    cmap = colormap(parula);
    colors = cmap(round(linspace(1, length(cmap), Timetrace.repeat)), :);
    
    fig = figure('Name', figure_name);

    set(gcf,'color','white','Inverthardcopy','off')
    subplot(2, 3, 1);hold on
    set(gca,'box','on','fontsize',16)
    set(gca,'xlim',[Lockin1.frequencies(1) Lockin1.frequencies(end)])
    set(gca, 'XScale', 'log')
    set(gca, 'YScale', 'log')
    xlabel('Heater frequency (Hz)')
    ylabel('DC current (A)')

    subplot(2, 3, 2);hold on
    set(gca,'box','on','fontsize',16)
    set(gca,'xlim',[Lockin1.frequencies(1) Lockin1.frequencies(end)])
    set(gca, 'XScale', 'log')
    set(gca, 'YScale', 'log')
    xlabel('Heater frequency (Hz)')
    ylabel('R thermocurrent')

    subplot(2, 3, 3);hold on
    set(gca,'box','on','fontsize',16)
    set(gca,'xlim',[Lockin1.frequencies(1) Lockin1.frequencies(end)])
    xlabel('Heater frequency (Hz)')
    ylabel('X_{2\omega} - Thermocurrent X (A)')
    set(gca, 'XScale', 'log')
    set(gca, 'YScale', 'log')

    subplot(2, 3, 4);hold on
    set(gca,'box','on','fontsize',16)
    set(gca,'xlim',[0 Timetrace.runtime])
    xlabel('Heater frequency (Hz)')
    ylabel('Y_{\omega} - Thermocurrent X (A)')
    set(gca,'xlim',[Lockin1.frequencies(1) Lockin1.frequencies(end)])
    set(gca, 'XScale', 'log')
    set(gca, 'YScale', 'log')

    subplot(2, 3, 5);hold on
    set(gca,'box','on','fontsize',16)
    set(gca,'xlim',[0 Timetrace.runtime])
    xlabel('Heater frequency (Hz)')
    ylabel('X_{\omega} - Conductance (S)')   
    set(gca,'xlim',[Lockin1.frequencies(1) Lockin1.frequencies(end)])
    set(gca, 'XScale', 'log')
    set(gca, 'YScale', 'log')

    subplot(2, 3, 6);hold on
    set(gca,'box','on','fontsize',16)
    set(gca,'xlim',[0 Timetrace.runtime])
    xlabel('Heater frequency (Hz)')
    ylabel('X_{\omega} - Conductance (S)')
    set(gca,'xlim',[1 length(Lockin1.frequencies)])
    set(gca,'xlim',[Lockin1.frequencies(1) Lockin1.frequencies(end)])
    set(gca, 'XScale', 'log')
    set(gca, 'YScale', 'log')
end

if Timetrace.index == 1
    Lockin1.voltage = zeros(Timetrace.repeat, 6);
end
%% run loop
pause(0.1);
run = true;
while run && Get_Par(25) >= 0
    run = Process_Status(2);

end
disp('First trace');
%% get final current
array = 2:9;
for i = 1:Settings.N_ADC
    Timetrace.data{i}(:, Timetrace.index) = GetData_Double(array(Settings.ADC_idx(i)), 1, Timetrace.runtime_counts);
end

Lockin1.voltage(Timetrace.index,1) = mean(Timetrace.data{1}(:,Timetrace.index)); % current DC - DC
Lockin1.voltage(Timetrace.index,2) = mean(Timetrace.data{2}(:,Timetrace.index)); % gate leakage - DC
Lockin1.voltage(Timetrace.index,3) = mean(Timetrace.data{3}(:,Timetrace.index)); % thermocurrent - X
Lockin1.voltage(Timetrace.index,4) = mean(Timetrace.data{4}(:,Timetrace.index)); % thermocurrent - Y
Lockin1.voltage(Timetrace.index,5) = mean(Timetrace.data{5}(:,Timetrace.index)); % conductance - X
Lockin1.voltage(Timetrace.index,6) = mean(Timetrace.data{6}(:,Timetrace.index)); % conductance - Y

%% make plot

figure(fig);
subplot(2, 3, 1);hold on
plot(Lockin1.frequencies(Timetrace.index), abs(Lockin1.voltage(Timetrace.index,1)), '.','markersize',24,'color',[0, 0.4470, 0.7410])

subplot(2, 3, 2);hold on
plot(Lockin1.frequencies(Timetrace.index), sqrt(Lockin1.voltage(Timetrace.index,3).^2 + Lockin1.voltage(Timetrace.index,4).^2), '.','markersize',24,'color',[0, 0.4470, 0.7410])

subplot(2, 3, 3);hold on
plot(Lockin1.frequencies(Timetrace.index), abs(Lockin1.voltage(Timetrace.index,3)) , '.','markersize',24,'color',[0, 0.4470, 0.7410])

subplot(2, 3, 4);hold on
plot(Lockin1.frequencies(Timetrace.index), abs(Lockin1.voltage(Timetrace.index,4)), '.','markersize',24,'color',[0, 0.4470, 0.7410])

subplot(2, 3, 5);hold on
plot(Lockin1.frequencies(Timetrace.index), abs(Lockin1.voltage(Timetrace.index,5)), '.','markersize',24,'color',[0, 0.4470, 0.7410])

subplot(2, 3, 6);hold on
plot(Lockin1.frequencies(Timetrace.index), abs(Lockin1.voltage(Timetrace.index,6)), '.','markersize',24,'color',[0, 0.4470, 0.7410])