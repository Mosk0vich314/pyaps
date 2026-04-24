classdef Device < handle
    % Device - Data container for the chip/sample layout.
    % Refactored to remove redundant Get/Set methods.
    
    properties (Access = public)
        Width   (1,1) double = 100
        Height  (1,1) double = 100
        Rows    (1,1) double = 5
        Columns (1,1) double = 6
        
        % Separation lines or offsets
        xLine   (1,1) double = 100 
        yLine   (1,1) double = 0
        
        % Cell counts/dimensions
        xCells  (1,1) double = 0
        yCells  (1,1) double = 0
    end
    
    methods
        function obj = Device(width, height, rows, cols)
            % Optional constructor to set values quickly
            % Usage: dev = Device(100, 100, 5, 6);
            if nargin > 0, obj.Width = width; end
            if nargin > 1, obj.Height = height; end
            if nargin > 2, obj.Rows = rows; end
            if nargin > 3, obj.Columns = cols; end
        end
    end
end