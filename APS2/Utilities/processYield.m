function gapOpening = processYield(folderPath, sampleName)
    % processYield - Analyzes measurement files to determine yield.
    %
    % Usage: yield = processYield('C:/Data', 'SampleA')
    %
    % Inputs:
    %   folderPath - Path to the directory containing .mat files
    %   sampleName - String prefix of the sample name to analyze
    %
    % Outputs:
    %   gapOpening - Logical array indicating which devices exceeded the threshold.

    % Get a list of all matching .mat files
    filePattern = fullfile(folderPath, ['*' sampleName '-*.mat']);
    files = dir(filePattern);
    numFiles = length(files);
    
    % Initialize output (assume max sample number might be larger than numFiles)
    % We'll grow this array dynamically or you could set a fixed size if known.
    gapOpening = false(1, numFiles); 

    if numFiles == 0
        warning('No files found for sample: %s in %s', sampleName, folderPath);
        return;
    end

    % Loop over each file
    for k = 1:numFiles
        fileName = files(k).name;
        
        % Robust regex to extract sample number (handles 'Name-123_IV.mat')
        tokens = regexp(fileName, [sampleName '-(\d+)_IV'], 'tokens');
        
        if isempty(tokens)
            continue; % Skip files that don't match the expected numbering format
        end
        
        sampleNumber = str2double(tokens{1}{1});
        
        try
            % Load the .mat file (only the 'IV' struct to save memory)
            data = load(fullfile(folderPath, fileName), 'IV');
            
            % Check structure validity
            if isfield(data, 'IV') && isfield(data.IV, 'current')
                currentCellArray = data.IV.current;
                
                % Check threshold
                exceedsThreshold = false(size(currentCellArray));
                for i = 1:numel(currentCellArray)
                    % Using 1nA (1e-9) as the threshold logic from original code
                    if mean(abs(currentCellArray{i})) > 1e-9
                        exceedsThreshold(i) = true;
                    end
                end
                
                % Store result at the specific index corresponding to sample number
                gapOpening(sampleNumber) = any(exceedsThreshold);
            else
                fprintf('Warning: Invalid data structure in %s\n', fileName);
            end
        catch ME
            fprintf('Error processing file %s: %s\n', fileName, ME.message);
        end
    end
end