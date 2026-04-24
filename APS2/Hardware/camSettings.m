classdef camSettings
    properties (Access = public)
        % Default Settings (Fallback if XML is missing)
        Video = struct( ...
            "DeviceID", 1, ...
            "VidResX", 1280, "VidResY", 720, ...
            "ExposureMode", "manual", ...
            "Exposure", -5, ...
            "Brightness", 128, ...
            "WhiteBalanceMode", "auto", ...
            "Saturation", 32, ...
            "CHC", struct("Xl", 0, "Xc", 0, "Xr", 0, "Yt", 0, "Yc", 0, "Yb", 0));     
    end

    methods
        function obj = camSettings()
            % Load Settings from File
            obj = Load_Settings(obj, "camSettings.xml");
        end

        function obj = Load_Settings(obj, Path)
            if isfile(Path)
                try
                    Data = readstruct(Path);        % Read File
                    obj = Parse_Settings(obj, Data);% Parse Data
                catch
                    disp('Error reading camSettings.xml. Using defaults.');
                end
            end
        end

        function obj = Save_Settings(obj, Path)
            Data = Format_Settings(obj);            
            writestruct(Data, Path);                 
        end
    end

    methods (Access = private)
        function obj = Parse_Settings(obj, Data)
            % Overwrite defaults with data from XML
            % We map fields manually to ensure structure integrity
            if isfield(Data, 'Video')
                f = fieldnames(Data.Video);
                for i = 1:length(f)
                    obj.Video.(f{i}) = Data.Video.(f{i});
                end
            end
        end

        function Data = Format_Settings(obj)
            Data = struct("Video", obj.Video);
        end
    end
end