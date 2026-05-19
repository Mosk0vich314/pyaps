function Density_sweep(Settings, sweep, figure_name)

%% Initialize plot
fig = findobj('Type', 'Figure', 'Name', figure_name);
if isempty(fig)
    fig = figure('Name', figure_name);
    set(gcf,'units','normalized')
    set(fig, 'Position', Settings.plot_position)
end

figure(fig); cla; hold on

if Settings.N_ADC > 1
    N_x = ceil(sqrt(Settings.N_ADC));
    N_y = ceil(Settings.N_ADC / N_x);
    
    %% make 2D histograms
    IV = cell(Settings.N_ADC, 1);
    IV_log = cell(Settings.N_ADC, 1);
    Bias = cell(Settings.N_ADC, 1);
    for i = 1:Settings.N_ADC
        IV{i} = sweep.current{i}(:);
        tmp = log10(abs(sweep.current{i}(:)));
        tmp(isinf(tmp)) = -15;
        IV_log{i} = tmp;
        Bias{i} = repmat(sweep.bias',[1 sweep.repeat])';
    end
    
    Bias_array = sweep.minV:2*sweep.dV:sweep.maxV;
    
    % get max current
    Max = -15;
    Min = 0;
    for i = 1:Settings.N_ADC
        Max = max(max(IV_log{i}), Max);
        Min = min(min(IV_log{i}), Min);
    end
    
    Current_array = linspace(floor(Min), ceil(Max), 201);
    
    histo = cell(Settings.N_ADC, 1);
    for i = 1:Settings.N_ADC
        histo{i} = hist2(Bias{i}, IV_log{i}, Bias_array, Current_array   );
    end
    
    %% make density plot
    % Gate = gate.minV:R
    cmap = parula;
    cmap(1,:)=[ 1 1 1];
    for i = 1:Settings.N_ADC
        subplot(N_x, N_y, i)
        surf(Bias_array, Current_array, histo{i},'edgecolor','interp')
        colormap(cmap)
        set(gca,'Fontsize',20,'box','on')
        set(gcf,'color','white','Inverthardcopy','off')
        ylabel(Settings.Labels.Y_1D)
        xlabel(Settings.Labels.X_1D)
        set(gca,'xlim',[Bias_array(1) Bias_array(end)])
        set(gca,'ylim',[Current_array(1) Current_array(end)])
        view([0 90])
    end
    
    drawnow
    
else
    
    %% make 2D histograms of IVs
    tmp1 = sweep.data1{1}(:);
    tmp2 = sweep.data2{1}(:);
    tmp1(isinf(tmp1)) = -15;
    tmp2(isinf(tmp2)) = -15;
    IV_log1 = -abs(log10(tmp1));
    IV_log2 = -abs(log10(tmp2));
    Bias1 = repmat(sweep.Bias1',[1 sweep.repeat])';
    Bias2 = repmat(sweep.Bias2',[1 sweep.repeat])';
    
    Bias_array = sweep.minV:sweep.dV:sweep.maxV;
    
    Current_array = linspace(floor(min(min(IV_log1),min(IV_log2))), ceil(max(max(IV_log1),max(IV_log2) )), 201);
    
    histo1 = hist2(Bias1, IV_log1, Bias_array, Current_array);
    histo2 = hist2(Bias2, IV_log2, Bias_array, Current_array);
    
    %% make 2D histograms of derivative
    der1 = sweep.data_der1{1}(:);
    der2 = sweep.data_der2{1}(:);
    Bias1 = repmat(sweep.Bias_der1',[1 sweep.repeat])';
    Bias2 = repmat(sweep.Bias_der2',[1 sweep.repeat])';
    
    Bias_array = sweep.minV:sweep.dV:sweep.maxV;
    
    der_array = linspace(0, max(max(der1),max(max(der2))), 201);
    
    histo_der1 = hist2(Bias1, der1, Bias_array, der_array);
    histo_der2 = hist2(Bias2, der2, Bias_array, der_array);
    
    %% plot histograms
    subplot(2, 2, 1)
    cmap = parula;
    cmap(1,:)=[ 1 1 1];
    surf(Bias_array, Current_array, histo1,'edgecolor','interp')
    colormap(cmap)
    set(gca,'Fontsize',20,'box','on','linewidth',2)
    set(gcf,'color','white','Inverthardcopy','off')
    ylabel(Settings.Labels.Y_1D)
    xlabel(Settings.Labels.X_1D)
    set(gca,'xlim',[Bias_array(1) Bias_array(end)])
    set(gca,'ylim',[Current_array(1) Current_array(end)])
    view([0 90])
    
    subplot(2, 2, 3)
    surf(Bias_array, Current_array, histo2,'edgecolor','interp')
    colormap(cmap)
    set(gca,'Fontsize',20,'box','on','linewidth',2)
    set(gcf,'color','white','Inverthardcopy','off')
    ylabel(Settings.Labels.Y_1D)
    xlabel(Settings.Labels.X_1D)
    set(gca,'xlim',[Bias_array(1) Bias_array(end)])
    set(gca,'ylim',[Current_array(1) Current_array(end)])
    view([0 90])
    
    subplot(2, 2, 2)
    surf(Bias_array, der_array, histo_der1,'edgecolor','interp')
    colormap(cmap)
    set(gca,'Fontsize',20,'box','on','linewidth',2)
    set(gcf,'color','white','Inverthardcopy','off')
    xlabel(Settings.Labels.X_1D)
    ylabel('dI/dV (S)')
    set(gca,'xlim',[Bias_array(1) Bias_array(end)])
    set(gca,'ylim',[der_array(1) der_array(end)])
    view([0 90])
    
    subplot(2, 2, 4)
    surf(Bias_array, der_array, histo_der2,'edgecolor','interp')
    colormap(cmap)
    set(gca,'Fontsize',20,'box','on','linewidth',2)
    set(gcf,'color','white','Inverthardcopy','off')
    xlabel(Settings.Labels.X_1D)
    ylabel('dI/dV (S)')
    set(gca,'xlim',[Bias_array(1) Bias_array(end)])
    set(gca,'ylim',[der_array(1) der_array(end)])
    view([0 90])
    
end

