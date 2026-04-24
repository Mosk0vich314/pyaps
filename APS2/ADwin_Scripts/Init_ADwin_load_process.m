function Settings = Init_ADwin_load_process(varargin)
    % Init_ADwin_load_process - Loads specific processes (TB/TC files) onto ADwin.
    %
    % Usage: Settings = Init_ADwin_load_process(Settings, ConfigStruct1, ConfigStruct2, ...)
    %
    % Inputs:
    %   Settings - Main settings struct (must contain 'ADwin' and 'path')
    %   ConfigStruct - Struct with 'process' name (e.g., 'Sweep_AO')

    Settings = varargin{1};

    AO_24bit_Loaded = 0;
    i = 2;
    
    while i <= nargin
        structure = varargin{i};

        %% 1. Map Process Name to Number
        if contains(structure.process, 'Sweep_AO')
            structure.process_number = 1;
        elseif contains(structure.process, 'Read_AI')
            structure.process_number = 2;
        elseif contains(structure.process, 'Fixed_AO')
            structure.process_number = 3;
        elseif contains(structure.process, 'Single_DO')
            structure.process_number = 5;
        elseif contains(structure.process, 'Waveform_AO')
            structure.process_number = 6;

            % Special Case: Check if 24bit AO is needed (for higher precision)
            if isfield(structure, 'dV') && ~AO_24bit_Loaded
                % Calculate resolution step size
                resolution_step = (2 * Settings.input_range) / (2 ^ Settings.output_resolution);
                
                if structure.dV < resolution_step
                    structure.process = 'Fixed_AO_24bit';
                    structure.process_number = 4;
                    AO_24bit_Loaded = 1;
                    i = i - 1; % Re-evaluate this structure with new process name
                    continue;
                end
            end
        else
            warning('Unknown ADwin process: %s', structure.process);
            i = i + 1;
            continue;
        end

        %% 2. Load Process File
        % Construct file path: Path/ADwinType/ProcessName_ADwinType.TBx
        % e.g., "C:/MyScripts/GoldII/Sweep_AO_GoldII.TB1"
        
        % Normalize path separators
        basePath = strrep(sprintf('%s/%s/%s_%s', ...
            Settings.path, ...
            Settings.ADwin, ...
            structure.process, ...
            Settings.ADwin), '\', '/');
            
        try
            switch Settings.ADwin
                case 'GoldII'
                    filePath = sprintf('%s.TB%1.0f', basePath, structure.process_number);
                    Load_Process(filePath);
                    fprintf('Loaded Process: %s\n', filePath);
                    
                case 'ProII'
                    filePath = sprintf('%s.TC%1.0f', basePath, structure.process_number);
                    Load_Process(filePath);
                    fprintf('Loaded Process: %s\n', filePath);
            end
        catch ME
            warning('Failed to load process file: %s. Error: %s', filePath, ME.message);
        end
        
        i = i + 1;
    end
end