function Plot_Gt(Settings, Gt, figure_name)

%% create legend
LEG = cell(Settings.N_ADC, 1);
for i=1:Settings.N_ADC
    LEG{i} = sprintf('ADC %1.0f', Settings.ADC_idx(i));
end

%% create figure
fig = findobj('Type', 'Figure', 'Name', figure_name);
if isempty(fig)
    fig = figure('Name', figure_name);
    set(gcf,'units','normalized')
    set(fig, 'Position', Settings.plot_position)
end

if Gt.index == 1
    figure(fig); cla; hold on
end

%% linear plot
subplot(1,2,1);hold on
for i = 1:Settings.N_ADC
    plot(Gt.time, Gt.current{i}(:, Gt.index),'LineWidth',1.5)
end

set(gca,'Fontsize',20,'box','on')
set(gcf,'color','white','Inverthardcopy','off')
xlabel('Time (s)')
ylabel('Current (A)')
leg = legend(LEG);
set(leg,'box','off','fontsize',12)
drawnow

%% log plot
subplot(1,2,2);hold on
for i = 1:Settings.N_ADC
    plot(Gt.time, abs(Gt.current{i}(:, Gt.index)),'LineWidth',1.5)
end
set(gca,'yscale','log')
set(gca,'Fontsize',20,'box','on')
set(gcf,'color','white','Inverthardcopy','off')
xlabel('Time (s)')
ylabel('Current (A)')
leg = legend(LEG);
set(leg,'box','off','fontsize',12)
drawnow

return