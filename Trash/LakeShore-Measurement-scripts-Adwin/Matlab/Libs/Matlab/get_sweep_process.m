function [Settings, structure] = get_sweep_process(Settings, structure)

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
Settings.auto = upper(Settings.auto);
switch Settings.ADwin
    case 'GoldII'
        if Settings.N_ADC == 1
            switch Settings.auto
                case 'FEMTO'
                    structure.process = 'Sweep_AO_read_AI_single_auto_FEMTO';
                case 'BASEL'
                    structure.process = 'Sweep_AO_read_AI_single_auto_BASEL';
                otherwise
                    structure.process = 'Sweep_AO_read_AI_single';
            end
        end
        if Settings.N_ADC == 2
            structure.process = 'Sweep_AO_read_AI_dual';
        end
        if Settings.N_ADC > 2
            structure.process = 'Sweep_AO_read_AI_multi';
        end
        
    case 'ProII'
        structure.process = 'Sweep_AO_read_AI_multi';
        if Settings.N_ADC == 1 && strcmp(Settings.auto, 'FEMTO')
            structure.process = 'Sweep_AO_read_AI_single_auto_FEMTO';
        end
        if Settings.N_ADC == 2 && strcmp(Settings.auto, 'FEMTO') && Settings.res4p == 0
            structure.process = 'Sweep_AO_read_AI_dual_auto_FEMTO';
        end
        if Settings.N_ADC == 3 && strcmp(Settings.auto, 'FEMTO') && Settings.res4p == 0
            structure.process = 'Sweep_AO_read_AI_triple_auto_FEMTO';
        end
end

