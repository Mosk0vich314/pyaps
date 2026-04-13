function gapOpening = processYield(folderPath, sampleName)
    % Get a list of all .mat files in the specified folder
    filePattern = fullfile(folderPath, ['*' sampleName '-*.mat']);
    files = dir(filePattern);
    numFiles = length(files);

    % Loop over each file
    for k = 1:numFiles
        fileName = files(k).name;
        
        % Extract the sample number from the file name
        tokens = regexp(fileName, [sampleName '-(\d+)_IV'], 'tokens');
        sampleNumber = str2double(tokens{1}{1});
        
        % Load the .mat file
        data = load(fullfile(folderPath, fileName));
        
        % Access the 'IV' class and the 'current' cell array
        if isfield(data, 'IV') && isfield(data.IV, 'current')
            currentCellArray = data.IV.current;
            
            % Check if the max current in any cell exceeds the threshold
            exceedsThreshold = false(size(currentCellArray));
            for i = 1:numel(currentCellArray)
                if mean(abs(currentCellArray{i})) > 1e-9
                    exceedsThreshold(i) = true;
                end
            end
            
            % Store results
            gapOpening(sampleNumber) = exceedsThreshold;
        else
            warning('IV class or current array not found in %s', fileName);
        end
    end

end


