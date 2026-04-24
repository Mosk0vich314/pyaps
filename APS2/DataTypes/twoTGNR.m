classdef twoTGNR < Device
    % INPUT DEVICE DIMENSIONS IN MICRONS
    methods

        function obj = twoTGNR

            % Uncomment the following line if the Device constructor method is
            % actually defined
            % obj@Device;

            obj.Width = 400; %um
            obj.Height = 200; %um
            obj.xLine = 200; %um
            obj.yLine = 200; %um

            obj.Rows = 5;
            obj.Columns = 3;
            obj.xCells = 4;
            obj.yCells = 5;

        end

    end
    
end
