function Plot_sweep(Settings, sweep, figure_name)

%% create legend
LEG = cell(Settings.N_ADC, 1);
for i=1:Settings.N_ADC
    LEG{i} = sprintf('ADC %1.0f', Settings.ADC_idx(i));
end

%% prepare figure
fig = findobj('Type', 'Figure', 'Name', figure_name);
if isempty(fig)
    fig = figure('Name', figure_name);
    set(gcf,'units','normalized')
    set(fig, 'Position', Settings.plot_position)
end

%% linear plot
subplot(1,2,1); cla; hold on
for i = 1:Settings.N_ADC
    plot(sweep.bias, sweep.current{i}(:, sweep.index),'LineWidth',1.5)
    set(gca,'Fontsize',20,'box','on')
    set(gcf,'color','white','Inverthardcopy','off')
end
leg = legend(LEG);
set(leg,'box','off','fontsize',12)
xlabel('Bias voltage (V)')
ylabel('Current (A)')
set(gca,'xlim',[sweep.minV sweep.maxV])

%% log plot
subplot(1,2,2); cla; hold on
for i = 1:Settings.N_ADC
    plot(sweep.bias, abs(sweep.current{i}(:, sweep.index)),'LineWidth',1.5)
    set(gca,'Fontsize',20,'box','on')
    set(gcf,'color','white','Inverthardcopy','off')
end
leg = legend(LEG);
set(leg,'box','off','fontsize',12)
set(gca,'yscale','log')
xlabel('Bias voltage (V)')
ylabel('Current (A)')
set(gca,'xlim',[sweep.minV sweep.maxV])

drawnow

saveas(fig, sprintf('%s/%s_%s_%s.png', Settings.save_dir, Settings.filename, Settings.sample, Settings.type))
saveas(fig, sprintf('%s/%s_%s_%s.fig', Settings.save_dir, Settings.filename, Settings.sample, Settings.type))