classdef doubleQDot < Device
    % INPUT DEVICE DIMENSIONS IN MICRONS
    methods

        function obj = doubleQDot 

            % Uncomment the following line if the Device constructor method is
            % actually defined
            % obj@Device;

            obj.Width = 1860; %um
            obj.Height = 660; %um
            obj.yLine = -320; %um
            obj.xLine = 140; %um

            obj.Rows = 2;
            obj.Columns = 1;
            obj.xCells = 7;
            obj.yCells = 14;

        end

    end
    
end
