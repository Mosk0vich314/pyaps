function Timetrace = Realtime_timetrace_1D(Settings, Timetrace, Labels, figure_name)

%% get plots
names = fieldnames(Labels.titles);
N_plots = numel(names);

%% start figure
fig = findobj('Type', 'Figure', 'Name', figure_name);
Fontsize = 12;

if isempty(fig)
    fig = figure('Name', figure_name);
    set(gcf,'units','normalized')
    set(fig, 'Position', Settings.plot_position)
    Timetrace.handles = guidata(fig);

    % init
    t = tiledlayout(2,N_plots);

    Timetrace.handles.ax = [];
    Timetrace.handles.ax_log = [];
    Timetrace.handles.animated_lines = [];
    Timetrace.handles.animated_lines_log = [];

    % 1D plots linear
    for i = 1:N_plots
        Timetrace.handles.ax.lines.(names{i}) = nexttile(t); hold on
        set(gca,'fontsize',Fontsize,'box','on')
        set(gcf,'Color','white')
        xlabel(Labels.x_axis_label)
        ylabel(Labels.titles.(names{i}))
        set(gca,'xlim',[Labels.x_axis(1) - abs(Labels.x_axis(1))*0.05 Labels.x_axis(end) + abs(Labels.x_axis(end))*0.05]);
        Timetrace.handles.animated_lines.(names{i}) = animatedline('LineWidth',1.5,'Parent',Timetrace.handles.ax.lines.(names{i}),'color',lines(1));
    end

        % 1D plots log
    for i = 1:N_plots
        Timetrace.handles.ax.lines_log.(names{i}) = nexttile(t); hold on
        set(gca,'fontsize',Fontsize,'box','on')
        set(gcf,'Color','white')
        xlabel(Labels.x_axis_label)
        set(gca,'yscale','log')
        ylabel(Labels.titles.(names{i}))
        set(gca,'xlim',[Labels.x_axis(1) - abs(Labels.x_axis(1))*0.05 Labels.x_axis(end) + abs(Labels.x_axis(end))*0.05]);
        Timetrace.handles.animated_lines_log.(names{i}) = animatedline('LineWidth',1.5,'Parent',Timetrace.handles.ax.lines_log.(names{i}),'color',lines(1));
    end

else

    colors = lines(Timetrace.index);

    %% clear lines
    if Timetrace.index2 == 1
        Timetrace.handles.animated_lines = [];
        Timetrace.handles.animated_lines_log = [];

        % 1D plots
        for i = 1:N_plots
%             cla(Timetrace.handles.ax.lines.(names{i}));
%             cla(Timetrace.handles.ax.lines_log.(names{i}));
            Timetrace.handles.animated_lines.(names{i}) = animatedline('LineWidth',1.5,'Parent',Timetrace.handles.ax.lines.(names{i}),'color',colors(end,:));
            Timetrace.handles.animated_lines_log.(names{i}) = animatedline('LineWidth',1.5,'Parent',Timetrace.handles.ax.lines_log.(names{i}),'color',colors(end,:));
        end

    end

end

%% make update line plots
for i = 1:N_plots
    if isstruct(Timetrace.mean.(names{i}))
        addpoints(Timetrace.handles.animated_lines.(names{i}), Labels.x_axis(Timetrace.index2), Timetrace.mean.(names{i}).(Labels.component.(names{i}))(Timetrace.index, Timetrace.index2));
        addpoints(Timetrace.handles.animated_lines_log.(names{i}), Labels.x_axis(Timetrace.index2), abs(Timetrace.mean.(names{i}).(Labels.component.(names{i}))(Timetrace.index, Timetrace.index2)));
    else
        addpoints(Timetrace.handles.animated_lines.(names{i}), Labels.x_axis(Timetrace.index2), Timetrace.mean.(names{i})(Timetrace.index, Timetrace.index2));
        addpoints(Timetrace.handles.animated_lines_log.(names{i}), Labels.x_axis(Timetrace.index2), abs(Timetrace.mean.(names{i})(Timetrace.index, Timetrace.index2)));
    end
end

return