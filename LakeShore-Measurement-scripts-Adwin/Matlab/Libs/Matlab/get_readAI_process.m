function [Settings, structure] = get_readAI_process(Settings, structure)

%% get ADC configuration
Settings.N_ADC = 0;
Settings.ADC_idx = 0;
for i = 1:length(Settings.ADC)
    if isnumeric(Settings.ADC{i})
        Settings.N_ADC = Settings.N_ADC + 1;
        Settings.ADC_idx(Settings.N_ADC) = i;
    end
end

Settings.N_ADC_pairs = ceil(Settings.ADC_idx(end)/2);

%% select process
switch Settings.ADwin
    case 'GoldII'
        if Settings.N_ADC == 1
            structure.process = 'Read_AI_single';
        end
        if Settings.N_ADC == 2
            switch Settings.auto
                case 'BPI'
                    structure.process = 'Read_AI_dual_auto_BPI';
                otherwise
                    structure.process = 'Read_AI_dual';
            end
        end
        if Settings.N_ADC > 2
            structure.process = 'Read_AI_multi';
        end

    case 'ProII'
        structure.process = 'Read_AI_multi';
end

return