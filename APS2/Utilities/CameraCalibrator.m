function CameraCalibrator
    % CAMERA CALIBRATOR TOOL
    % A standalone app to tune webcam settings interactively.
    
    close all; clc;
    
    % 1. CONNECT TO CAMERA
    try
        cam = webcam(1);
    catch ME
        errordlg(['Camera not found: ' ME.message]);
        return;
    end
    
    % 2. CREATE UI WINDOW
    fig = uifigure('Name', 'Camera Calibrator', 'Position', [100, 100, 1000, 600]);
    
    % Layout: Grid (Left = Video, Right = Controls)
    gl = uigridlayout(fig, [1, 2]);
    gl.ColumnWidth = {'2x', '1x'};
    
    % Panel for Video
    pVideo = uipanel(gl, 'Title', 'Preview');
    ax = uiaxes(pVideo, 'Position', [10 10 600 500]);
    ax.XTick = []; ax.YTick = [];
    
    % Panel for Controls (Scrollable)
    pControls = uipanel(gl, 'Title', 'Settings', 'Scrollable', 'on');
    
    % 3. START PREVIEW
    % Create placeholder image
    res = cam.Resolution;
    splitRes = sscanf(res, '%dx%d');
    W = splitRes(1); H = splitRes(2);
    hImage = image(ax, zeros(H,W,3,'uint8'));
    ax.XLim = [0 W]; ax.YLim = [0 H];
    ax.YDir = 'reverse';
    preview(cam, hImage);
    
    % 4. DYNAMICALLY GENERATE CONTROLS
    % We look at every property the camera has and make a slider/dropdown for it.
    
    props = properties(cam);
    yPos = 20; % Start position for controls
    
    % List of properties we care about
    targetProps = {'Brightness', 'Contrast', 'Hue', 'Saturation', ...
                   'Sharpness', 'Gamma', 'WhiteBalance', 'BacklightCompensation', ...
                   'Gain', 'Exposure', 'Focus', 'Zoom', 'Pan', 'Tilt'};
               
    % List of "Mode" properties (Auto/Manual switches)
    modeProps = {'ExposureMode', 'WhiteBalanceMode', 'FocusMode'};
    
    % A. GENERATE MODE SWITCHES FIRST (e.g. Turn off Auto Exposure)
    for i = 1:length(modeProps)
        pName = modeProps{i};
        if isprop(cam, pName)
            lbl = uilabel(pControls, 'Text', pName, 'Position', [10, yPos, 120, 22], 'FontWeight', 'bold');
            
            % Create Dropdown
            dd = uidropdown(pControls, 'Position', [140, yPos, 100, 22]);
            dd.Items = {'auto', 'manual'}; % Most cameras use these
            
            % Try to set current value
            try
                currVal = cam.(pName);
                if ismember(currVal, dd.Items)
                    dd.Value = currVal;
                end
            catch
            end
            
            % Callback
            dd.ValueChangedFcn = @(src, event) updateMode(cam, pName, src.Value);
            
            yPos = yPos + 40;
        end
    end
    
    % B. GENERATE SLIDERS FOR VALUES
    for i = 1:length(targetProps)
        pName = targetProps{i};
        if isprop(cam, pName)
            % Check available range if possible (MATLAB webcam doesn't always give ranges easily)
            % We use standard generic ranges and catch errors if out of bounds.
            
            lbl = uilabel(pControls, 'Text', pName, 'Position', [10, yPos, 120, 22]);
            
            % Create Slider
            sld = uislider(pControls, 'Position', [140, yPos+7, 120, 3]);
            
            % Get Current Value
            try
                currVal = cam.(pName);
                sld.Value = double(currVal);
            catch
                currVal = 0;
            end
            
            % Create Value Edit Field (for precise typing)
            numField = uieditfield(pControls, 'numeric', 'Position', [280, yPos, 50, 22]);
            numField.Value = double(currVal);
            
            % Set Limits based on property type (Heuristics)
            if contains(pName, 'Exposure')
                sld.Limits = [-13 0]; % Logarithmic exposure usually negative
            elseif contains(pName, 'Gain')
                sld.Limits = [0 255];
            elseif contains(pName, 'WhiteBalance')
                sld.Limits = [2000 10000]; % Temp in Kelvin
            elseif contains(pName, 'Focus')
                sld.Limits = [0 255]; % Macro to infinity
            else
                sld.Limits = [0 255]; % Standard 8-bit range
            end
            
            % Callbacks
            sld.ValueChangedFcn = @(src, event) updateCam(cam, pName, src.Value, numField);
            numField.ValueChangedFcn = @(src, event) updateCam(cam, pName, src.Value, sld);
            
            yPos = yPos + 50;
        end
    end
    
    % 5. EXPORT BUTTON
    btnPrint = uibutton(pControls, 'Text', 'PRINT XML SETTINGS', ...
        'Position', [10, yPos+20, 320, 50], ...
        'BackgroundColor', [0 1 0], 'FontWeight', 'bold', ...
        'ButtonPushedFcn', @(src, event) printSettings(cam));

    % HELPER FUNCTIONS (NESTED)
    
    function updateMode(cam, prop, val)
        try
            cam.(prop) = val;
            disp(['Set ' prop ' to ' val]);
        catch ME
            uialert(fig, ME.message, 'Error');
        end
    end

    function updateCam(cam, prop, val, syncObj)
        try
            cam.(prop) = val;
            syncObj.Value = val; % Sync the slider/editfield
        catch ME
            % Ignore range errors silently, just don't update
        end
    end

    function printSettings(cam)
        fprintf('\n\n--- COPY THIS INTO camSettings.xml ---\n');
        fprintf('<Video>\n');
        fprintf('    <DeviceID>1</DeviceID>\n');
        fprintf('    <VidResX>1280</VidResX>\n');
        fprintf('    <VidResY>720</VidResY>\n');
        
        props = properties(cam);
        for k = 1:length(props)
            p = props{k};
            % Skip read-only or irrelevant properties
            if strcmp(p, 'Name') || strcmp(p, 'Resolution') || strcmp(p, 'AvailableResolutions')
                continue;
            end
            
            val = cam.(p);
            if ischar(val)
                fprintf('    <%s>%s</%s>\n', p, val, p);
            elseif isnumeric(val)
                fprintf('    <%s>%d</%s>\n', p, val, p);
            end
        end
        fprintf('</Video>\n');
        fprintf('--------------------------------------\n');
        uialert(fig, 'Settings printed to Command Window!', 'Success');
    end

end