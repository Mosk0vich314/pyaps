classdef BaseMeasurement < handle
    % BaseMeasurement - Parent class for all experiment types.
    % Handles common tasks: ADwin Init, Data Saving, plotting setup.
    
    properties (Access = public)
        Settings struct
        Data struct % Generic container for measurement data (IV, Gate, etc.)
        SaveDir string
        Filename string
    end
    
    methods
        function obj = BaseMeasurement(settings)
            % Constructor: Store settings and prepare
            obj.Settings = settings;
            
            % Ensure ADwin is ready (Boot if needed)
            try
                % Assuming Init_ADwin_boot_only is on path
                obj.Settings = Init_ADwin_boot_only(obj.Settings);
            catch ME
                warning('ADwin Boot Failed: %s', ME.message);
            end
        end
        
        function Run(obj)
            % Abstract method - Children must implement this
            error('Run method must be implemented by the child class');
        end
        
        function Save(obj, suffix)
            % Common saving logic
            if nargin < 2, suffix = ""; end
            
            % Generate Timestamped Filename
            timestamp = char(datetime('now', 'Format', 'yyyyMMdd_HHmmss'));
            obj.Filename = sprintf('%s_%s_%s_%s', ...
                obj.Settings.filename, ...
                obj.Settings.sample, ...
                obj.Settings.type, ...
                timestamp);
            
            if suffix ~= ""
                obj.Filename = obj.Filename + "_" + suffix;
            end
            
            fullPath = fullfile(obj.Settings.save_dir, obj.Filename);
            
            % Save the entire object or just the data structs
            Settings = obj.Settings;
            Data = obj.Data; 
            
            save(fullPath + ".mat", 'Settings', 'Data');
            fprintf('Data saved to: %s.mat\n', fullPath);
            
            % Save Figure if it exists
            figHandle = findobj('Type', 'figure', 'Name', obj.Settings.type);
            if ~isempty(figHandle)
                saveas(figHandle, fullPath + ".png");
                saveas(figHandle, fullPath + ".fig");
            end
        end
    end
    
    methods (Access = protected)
        function InitADwinProcess(obj, configStruct)
            % Helper to load specific ADwin processes
            % Wraps Init_ADwin_load_process
            try
                obj.Settings = Init_ADwin_load_process(obj.Settings, configStruct);
            catch ME
                warning('ADwin Process Load Failed: %s', ME.message);
            end
        end
    end
end