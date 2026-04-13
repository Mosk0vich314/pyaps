function Timetrace = Realtime_timetrace_3D(Settings, Timetrace, Labels, figure_name)

%% get plots
names = fieldnames(Labels.titles);
N_plots = numel(names);

%% make axes
dX = Labels.x_axis(2) - Labels.x_axis(1);
dY = Labels.y_axis(2) - Labels.y_axis(1);

%% start figure
fig = findobj('Type', 'Figure', 'Name', figure_name);
Fontsize = 12;

if isempty(fig)
    fig = figure('Name', figure_name);
    set(gcf,'units','normalized')
    set(fig, 'Position', Settings.plot_position)
    Timetrace.handles = guidata(fig);

    % init
    t = tiledlayout(3, N_plots);
    Timetrace.handles.ax = [];
    Timetrace.handles.animated_lines = [];

    % 1D plots
    for i = 1:N_plots
        Timetrace.handles.ax.lines.(names{i}) = nexttile(t); hold on
        set(gca,'fontsize',Fontsize,'box','on')
        set(gcf,'Color','white')
        xlabel(Labels.y_axis_label)
        ylabel(Labels.titles.(names{i}))
        set(gca,'xlim',[min(Labels.y_axis)*1.05 max(Labels.y_axis)*1.05]);
        Timetrace.handles.animated_lines.(names{i}) = animatedline('LineWidth',1.5,'Parent',Timetrace.handles.ax.lines.(names{i}));
    end

    % 2D plots
    for i = 1:N_plots
        Timetrace.handles.ax.surf.(names{i}) = nexttile(t); hold on
        set(gca,'fontsize',Fontsize,'box','on')
        set(gcf,'Color','white')
        xlabel(Labels.x_axis_label)
        ylabel(Labels.y_axis_label)

        set(gca,'xlim',[min(Labels.x_axis)-dX/2 max(Labels.x_axis)+dX/2]);
        set(gca,'ylim',[min(Labels.y_axis)-dY/2 max(Labels.y_axis)+dY/2]);
        title(Labels.titles.(names{i}))

        set(gca,'ydir','normal')
        colormap(Timetrace.handles.ax.surf.(names{i}), brewermap(256,'RdBu'))
        view([0 90])
        colorbar(Timetrace.handles.ax.surf.(names{i}))

    end

    % 2D plots log
    for i = 1:N_plots
        Timetrace.handles.ax.surf_log.(names{i}) = nexttile(t); hold on
        set(gca,'fontsize',Fontsize,'box','on')
        set(gcf,'Color','white')
        xlabel(Labels.x_axis_label)
        ylabel(Labels.y_axis_label)

        set(gca,'xlim',[min(Labels.x_axis)-dX/2 max(Labels.x_axis)+dX/2]);
        set(gca,'ylim',[min(Labels.y_axis)-dY/2 max(Labels.y_axis)+dY/2]);
        title(Labels.titles.(names{i}))

        set(gca,'ydir','normal')
        colormap(Timetrace.handles.ax.surf_log.(names{i}), inferno(256))
        view([0 90])
        colorbar(Timetrace.handles.ax.surf_log.(names{i}))

    end

else

    %% clear lines
    if Timetrace.index2 == 1
        Timetrace.handles.animated_lines = [];

        % 1D plots
        for i = 1:N_plots
            cla(Timetrace.handles.ax.lines.(names{i}));
            Timetrace.handles.animated_lines.(names{i}) = animatedline('LineWidth',1.5,'Parent',Timetrace.handles.ax.lines.(names{i}));
        end

    end
end

%% make update line plots
for i = 1:N_plots
    if isstruct(Timetrace.mean.(names{i}))
        addpoints(Timetrace.handles.animated_lines.(names{i}), Labels.y_axis(Timetrace.index2), Timetrace.mean.(names{i}).(Labels.component.(names{i}))(Timetrace.index, Timetrace.index2));
    else
        addpoints(Timetrace.handles.animated_lines.(names{i}), Labels.y_axis(Timetrace.index2), Timetrace.mean.(names{i})(Timetrace.index, Timetrace.index2));
    end
end

%% update 3D plots
if Timetrace.index2 == Timetrace.repeat2
    for i = 1:N_plots
        cla(Timetrace.handles.ax.surf.(names{i}));
        if isstruct(Timetrace.mean.(names{i}))
            imagesc(Labels.x_axis, Labels.y_axis, Timetrace.mean.(names{i}).(Labels.component.(names{i}))','Parent',Timetrace.handles.ax.surf.(names{i}))
        else
            imagesc(Labels.x_axis, Labels.y_axis, Timetrace.mean.(names{i})','Parent',Timetrace.handles.ax.surf.(names{i}))
        end
    end
end

%% update 3D plots log
if Timetrace.index2 == Timetrace.repeat2
    for i = 1:N_plots
        cla(Timetrace.handles.ax.surf_log.(names{i}));
        if isstruct(Timetrace.mean.(names{i}))
            imagesc(Labels.x_axis, Labels.y_axis, log10(abs(Timetrace.mean.(names{i}).(Labels.component.(names{i}))')),'Parent',Timetrace.handles.ax.surf_log.(names{i}))
        else
            imagesc(Labels.x_axis, Labels.y_axis, log10(abs(Timetrace.mean.(names{i})')),'Parent',Timetrace.handles.ax.surf_log.(names{i}))
        end
    end
end

return