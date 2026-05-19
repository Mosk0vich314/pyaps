%%
clear
close all
clc

%% Replotting Stability diagrams
directory = 'E:\Samples\flaa_AngEvap_22\9AGNR_annealed\9K\Stability';
filetype = '*.mat';

list = ls([directory '\' filetype]);

%% load

[N_files, ~] = size(list)

for i=1:N_files
    load(sprintf('%s/%s', directory, list(i,:)));

    if ischar(Settings.sample)
        tmp{1} = Settings.sample;
        Settings.sample = tmp;
    end
    
    IV.clim_lin = []; %[-1e-11 1e-11 0 5e-11] 
    IV.clim_log = [-13 -8 -12 -6]; %[-13 -11 -12 -9]
      
    IV = split_data_sweep(Settings, IV);
    Settings.plot_position = [0.02 0.06 0.96 0.85];
    Surf_stability(Settings, IV, Gate, 'Stability diagram')
    fig = findobj('Name','Stability diagram');
    for j=1:Settings.N_ADC
        saveas(figure(j), sprintf('%s/plots_logfixed/%s_%s_%s.png', Settings.save_dir, Settings.filename, Settings.sample{j}, Settings.type))
    end
    close all
end    

