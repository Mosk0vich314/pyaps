function Histo = Plot_Histo(Settings, Histo, figure_name)

%% intialize figure
fig = findobj('Type', 'Figure', 'Name', figure_name);
if isempty(fig)
    fig = figure('Name', figure_name);
    set(gcf,'units','normalized')
    set(fig, 'Position', Settings.plot_position)
end

%% create histogram 
log_G_breaking = Histo.current_breaking(:,1) / Settings.G0 / Histo.setV;
log_G_breaking(log_G_breaking < 0) = Histo.plot.Gmin;

Histo.Histo = Histo.Histo + hist2(Histo.Time_breaking', log10(log_G_breaking), Histo.D_array, Histo.G_array);

log_G_making = Histo.current_making(:,1) / Settings.G0 / Histo.setV;
log_G_making(log_G_making < 0) = Histo.plot.Gmin;

%% update single trace
figure(fig); 
subplot('Position',[0.10 0.1 0.3 0.85]);cla; hold on
plot(Histo.Time_breaking, log_G_breaking)
plot(Histo.Time_making, log_G_making)
set(gca,'Fontsize',20,'box','on')
set(gcf,'color','white','Inverthardcopy','off')
set(gca,'yscale','log')
set(gca,'Ytick',10.^(-10:1:10))
xlabel('Displacement (nm)')
ylabel('Conductance (G/G_0)')
set(gca,'Xlim',[Histo.plot.Xmin Histo.plot.Xmax])
set(gca,'Ylim',[Histo.plot.Gmin Histo.plot.Gmax])

%% update 2D histogram
subplot('Position',[0.40 0.1 0.4 0.85]);cla; hold on
surf(Histo.D_array, 10.^Histo.G_array, Histo.Histo,'edgecolor','interp')
view([0 90])
set(gca,'Fontsize',20,'box','on')
set(gcf,'color','white','Inverthardcopy','off')
set(gca,'yscale','log')
set(gca,'Ytick',[])
xlabel('Displacement (nm)')
set(gca,'Xlim',[Histo.plot.Xmin Histo.plot.Xmax])
set(gca,'Ylim',[Histo.plot.Gmin Histo.plot.Gmax])

idx1 = find(min(abs(Histo.G_array-3) ==abs(Histo.G_array-3)) );
idx2 = find(min(abs(Histo.G_array-6) ==abs(Histo.G_array-6)) );
c_max = max(1, max(max(Histo.Histo(idx2:idx1,:))));
set(gca,'Clim',[0 0.5*c_max])

%% update 1D histogram
subplot('Position',[0.8 0.1 0.15 0.85]);cla; hold on
hist1 = sum(Histo.Histo,2);
hist1(1) = 0; 
plot(hist1, 10.^Histo.G_array)
set(gca,'xdir','reverse')
set(gca,'Fontsize',20,'box','on')
set(gcf,'color','white','Inverthardcopy','off')
set(gca,'yscale','log')
set(gca,'Ytick',[])
set(gca,'Xtick',[])
% set(gca,'Xtick',[0 max(hist1)])
xlabel('Counts')
set(gca,'Xlim',[0 1.2*max(1, max(hist1))])
set(gca,'Ylim',[Histo.plot.Gmin Histo.plot.Gmax])

%%
drawnow

return





