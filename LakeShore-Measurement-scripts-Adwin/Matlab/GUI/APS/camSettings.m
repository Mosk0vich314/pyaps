classdef camSettings
    properties (Access = public)
        % Motor = struct("Connected", false, "SerialLock", false, "Simulate", true, ...
        %                 "Velocity", 50000, "Acceleration", 5000);
        Video = struct("Adaptor", "winvideo", "DeviceID", "3", "Format", "MJPG_1024x576", ...
            "Simulate", false,...
            "VidResX", 1024, "VidResY", 576, ...
            "DsplResX", 0, "DsplResY", 0, ...
            "CHC", struct("Xl", 0, "Xc", 0, "Xr", 0, "Yt", 0, "Yc", 0, "Yb", 0));     
        % Webcam: DeviceID=1, Format=MJPG_1024x576
        % TIS   : DeviceID=2, Format=RGB32_1920x1200
        % Just check matlab built-in Image acquisition app
    end

    methods
        function obj = camSettings()
            % Load Settings from File
            obj = Load_Settings(obj, "camSettings.xml");
        end

        function obj = Load_Settings(obj,Path)
            Data = readstruct(Path);                % Read File
            obj = Parse_Settings(obj, Data);        % Parse Data
        end

        function obj = Save_Settings(obj, Path)
            Data = Format_Settings(obj);            % Format settings into Text/JSON/XML
            writestruct(Data,Path);                 % Write File
        end
    end

    methods (Access = private)
        function obj = Parse_Settings(obj, Data)
            % Parse Settings from XML Data
            % obj.Motor = Data.Motor;
            obj.Video = Data.Video;
        end

        function Data = Format_Settings(obj)
            % Put all Settings into one STRUCT
            Data = struct("Video", obj.Video);
        end

    end

end
