function Settings = Init_ADwin_load_process(varargin)

Settings = varargin{1};

%% ADwin load processes
AO_24bit_Loaded = 0;
i = 2;
while i <=nargin
    structure = varargin{i};

    %% set process number
    if regexp(structure.process,'Sweep_AO')
        structure.process_number = 1;
    elseif regexp(structure.process,'Read_AI')
        structure.process_number = 2;
    elseif regexp(structure.process,'Fixed_AO')
        structure.process_number = 3;
    elseif regexp(structure.process,'Single_DO')
        structure.process_number = 5;
    elseif regexp(structure.process,'Waveform_AO')
        structure.process_number = 6;

        %% check if 24bit AO is needed
        if isfield(structure,'dV') && ~AO_24bit_Loaded
            if structure.dV < 1 * (2*Settings.input_range / 2 ^ Settings.output_resolution)  % check for 24 bit output
                structure.process = 'Fixed_AO_24bit';
                structure.process_number = 4;
                AO_24bit_Loaded = 1;
                i = i-1;
            end
        end

    else
        disp('Unknown process')
    end

    %% ADwin load processes
    switch Settings.ADwin
        case 'GoldII'
            Load_Process(regexprep(sprintf('%s/%s/%s_%s.TB%1.0f', Settings.path,  Settings.ADwin, structure.process, Settings.ADwin, structure.process_number),'\','/'));
            fprintf('%s/%s/%s_%s.TB%1.0f \n', Settings.path,  Settings.ADwin, structure.process, Settings.ADwin, structure.process_number);
        case 'ProII'
            Load_Process(regexprep(sprintf('%s/%s/%s_%s.TC%1.0f', Settings.path,  Settings.ADwin, structure.process, Settings.ADwin, structure.process_number),'\','/'));
            fprintf('%s/%s/%s_%s.TC%1.0f \n', Settings.path,  Settings.ADwin, structure.process, Settings.ADwin, structure.process_number);
    end
    i = i + 1;

end
disp('Boot successful')

return
