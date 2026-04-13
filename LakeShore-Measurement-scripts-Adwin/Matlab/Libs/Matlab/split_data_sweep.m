function sweep = split_data_sweep(Settings, sweep)

%% split IVs
sweep.maxV = max(sweep.bias);
sweep.minV = min(sweep.bias);

idx_max = find(sweep.bias == sweep.maxV);
idx_min = find(sweep.bias == sweep.minV);

sweep.Bias1 = (sweep.minV:sweep.dV:sweep.maxV)';
sweep.Bias2 = (sweep.minV:sweep.dV:sweep.maxV)';
sweep.Bias_der1 = (linspace(sweep.minV, sweep.maxV, length(sweep.Bias1)-1))';
sweep.Bias_der2 = (linspace(sweep.minV, sweep.maxV, length(sweep.Bias2)-1))';

%% initialize derivative
sweep.data1 = cell(Settings.N_ADC,1);
sweep.data2 = cell(Settings.N_ADC,1);
sweep.data_der1 = cell(Settings.N_ADC,1);
sweep.data_der2 = cell(Settings.N_ADC,1);

[~, N_measurements] = size(sweep.current{1});

for index = 1:Settings.N_ADC
    sweep.data_der1{index} = zeros(N_measurements, length(sweep.Bias_der1));
    sweep.data_der2{index} = zeros(N_measurements, length(sweep.Bias_der2));
end
sweep.data1 = cell(Settings.N_ADC,1);
sweep.data2 = cell(Settings.N_ADC,1);

%% take derivative
for index = 1:Settings.N_ADC
    
    data = sweep.current{index};
    
    if sweep.minV < sweep.startV
        sweep.data1{index} = flipud(data(idx_max(end):idx_min(1),:));
        sweep.data2{index} = data( [idx_min(end):end-1 1:idx_max(1)], :);
    else
        sweep.data1{index} = flipud(data(idx_max(end):idx_min(end),:));
        sweep.data2{index} = data( idx_min(1):idx_max(1) , :);
    end
    
    for i = 1:sweep.repeat
        sweep.data_der1{index}(i,:) = diff(sweep.data1{index}(:, i)) ./ (sweep.dV * sign(diff(sweep.Bias1)));
        sweep.data_der2{index}(i,:) = diff(sweep.data2{index}(:, i)) ./ (sweep.dV * sign(diff(sweep.Bias2)));
    end
    
end