function Histo = Plot_MCBJ_breaking_trace(Settings, Histo, Bias, Plot, figure_name)

%% define figure
fig = findobj('Type', 'Figure', 'Name', figure_name);
if isempty(fig)

    figure("Name",figure_name,'units','normalized','Position',Settings.plot_position);
    set(gcf,'color','white','Inverthardcopy','off')

    % create arrays
    Histo.d_array = linspace(Plot.xmin, Plot.xmax, Plot.nDbins);
    Histo.G_array = linspace(log10(Plot.Gmin), log10(Plot.Gmax), Plot.nGbins);
    Histo.Histo = zeros(Plot.nGbins, Plot.nDbins);

    % single trace
    subplot('Position',[0.10 0.1 0.25 0.85])
    set(gca,'fontsize',20,'box','on')
    xlabel('Displacement (nm)')
    ylabel('Conductance (G_0)')
    Histo.handles.h_breaking = animatedline('Color','red','LineWidth',1.5);
    Histo.handles.h_making = animatedline('Color','blue','LineWidth',1.5);
    set(gca,'yscale','log')
    set(gca,'ylim',[Plot.Gmin Plot.Gmax])
    set(gca,'Ytick',10.^(-10:1:10))

    % 2D histogram
    Histo.handles.histo2D_ax = subplot('Position',[0.40 0.1 0.35 0.85]);
    Histo.handles.histo2D = surf(Histo.d_array, 10.^Histo.G_array, Histo.Histo, 'edgecolor','interp');
    view([0 90])
    set(gca,'Fontsize',20,'box','on','Linewidth', 3)
    set(gca,'yscale','log')
    set(gca,'Ytick',10.^(-10:1:10))
    xlabel('Displacement (nm)')
    set(gca,'ylim',[Plot.Gmin Plot.Gmax])
    set(gca,'xlim',[Plot.xmin Plot.xmax])
    cmap = readmatrix('cmap.dat');
    clim([0 1])
    colormap(cmap);
    % set(gca,'TickDir','out')

    % 1D histogram
    Histo.handles.histo1D_ax = subplot('Position',[0.8 0.1 0.15 0.85]);
    Histo.handles.histo1D = plot(sum(Histo.Histo,2), 10.^Histo.G_array);
    set(gca,'xdir','reverse')
    set(gca,'Fontsize',20,'box','on')
    set(gca,'yscale','log')
    set(gca,'Ytick',10.^(-10:1:10))
    % set(gca,'Xtick',[])
    xlabel('Counts')
    set(gca,'ylim',[Plot.Gmin Plot.Gmax])
    set(gca,'xlim',[0 1])

    title(sprintf('%01d',Histo.index))
else
    %% clear points
    clearpoints(Histo.handles.h_breaking);
    clearpoints(Histo.handles.h_making);

end

%% run breaking trace
previous_counter_breaking = 0;
previous_counter_making = 0;

while Process_Status(7)

    %% get data breaking
    if Get_Par(60) == 1 || Get_Par(60) == 2 || Get_Par(60) == 3
        current_counter_breaking = Get_Par(2);
        temp_G = GetData_Double(2, previous_counter_breaking + 1, current_counter_breaking - previous_counter_breaking)';
        temp_d = GetData_Double(4, previous_counter_breaking + 1, current_counter_breaking - previous_counter_breaking)';

        conductance = temp_G / Bias.targetV / Settings.G0;
        displacement = Histo.V_per_V * convert_bin_to_V_float(temp_d, Settings.output_min, Settings.output_max, Settings.output_resolution);

        addpoints(Histo.handles.h_breaking, displacement, conductance);

        previous_counter_breaking = current_counter_breaking;
    end

    %% get data making
    if Get_Par(60) == 4
        current_counter_making = Get_Par(3);

        temp_G = GetData_Double(3, previous_counter_making + 1, current_counter_making - previous_counter_making)';
        temp_d = GetData_Double(5, previous_counter_making + 1, current_counter_making - previous_counter_making)';

        conductance = temp_G / Bias.targetV / Settings.G0;
        displacement = Histo.V_per_V * convert_bin_to_V_float(temp_d, Settings.output_min, Settings.output_max, Settings.output_resolution);

        addpoints(Histo.handles.h_making, displacement, conductance);

        previous_counter_making = current_counter_making;
    end

    %% update plot
    drawnow

end

%% get status
Histo.status = Get_Par(62);

%% get final data
switch Histo.status
    case 2
        conductance_breaking = GetData_Double(2, 1, Get_Par(2)-1)' / Bias.targetV / Settings.G0;
        displacement_breaking = Histo.V_per_V * Plot.V_to_nm * convert_bin_to_V_float(GetData_Double(4, 1, Get_Par(2)-1)', Settings.output_min, Settings.output_max, Settings.output_resolution);

        data_breaking = [displacement_breaking conductance_breaking];
        Histo.data_breaking{Histo.index} = data_breaking;
        try
            conductance_making = GetData_Double(3, 1, Get_Par(3)-1)' / Bias.targetV / Settings.G0;
            displacement_making = Histo.V_per_V * Plot.V_to_nm * convert_bin_to_V_float(GetData_Double(5, 1, Get_Par(3)-1)', Settings.output_min, Settings.output_max, Settings.output_resolution);
            Histo.data_making{Histo.index} = data_making;
            data_making = [displacement_making conductance_making];
        catch
            disp('No data making')
        end

        %% shift breaking trace
        breaking_idx = find(conductance_breaking > 0.1, 1,'last');

        %% create histogram
        if ~isempty(breaking_idx)
            Histo.Histo = Histo.Histo + hist2(displacement_breaking - displacement_breaking(breaking_idx), log10(abs(conductance_breaking)), Histo.d_array, Histo.G_array);
        else
            disp('Cannot find break point')
        end

        %% plot 2D histo
        Histo.handles.histo2D.ZData = Histo.Histo;
        %
        idx1 = find(min(abs(Histo.G_array--2)) == abs(Histo.G_array--2) );
        idx2 = find(min(abs(Histo.G_array--6)) == abs(Histo.G_array--6) );
        c_max = max(1, max(max(Histo.Histo(idx2:idx1,:))));
        set(Histo.handles.histo2D_ax,'Clim',[0 0.75*c_max])

        %% update 1D histogram
        hist1 = sum(Histo.Histo, 2);
        hist1(1) = 0;
        Histo.handles.histo1D.XData = hist1;
        set(Histo.handles.histo1D_ax,'xlim',[0 1.25*max(hist1)]);


    case 3
        disp('Cannot break')
    case 4
        disp('Cannot Make')

end

return