classdef Device < handle
    %Contains info on the current device layout to use in the APS app
    
    properties (Access = protected)
        Width
        Height
        Rows
        Columns
        xLine
        yLine
        xCells 
        yCells
    end
    
    methods (Access = public)
        % function obj = Device
        % 
        %     obj.Width = 100;
        %     obj.Height = 100;
        %     obj.Rows = 5;
        %     obj.Columns = 6;
        %     obj.Line = 100;
        % 
        % end
        
        function widthValue = getWidth(obj)

            widthValue = obj.Width;

        end

        function heightValue = getHeight(obj)

            heightValue = obj.Height;

        end

        function rowsValue = getRows(obj)

            rowsValue = obj.Rows;
      
        end

        function columnsValue = getColumns(obj)
            
            columnsValue = obj.Columns;

        end

        function xCellsValue = getxCells(obj)
            
            xCellsValue = obj.xCells;

        end
        
        function yCellsValue = getyCells(obj)
            
            yCellsValue = obj.yCells;

        end

        function lineValue = getxLine(obj)

            lineValue = obj.xLine;

        end

        function lineValue = getyLine(obj)

            lineValue = obj.yLine;

        end

        function obj = setWidth(obj, width)

            obj.Width = width;

        end

        function obj = setHeight(obj, height)

            obj.Height = height;

        end

        function obj = setRows(obj, rows)

            obj.Rows = rows;

        end

        function obj = setColumns(obj, columns)

            obj.Columns = columns;

        end

        function obj = setxCells(obj, xcells)

            obj.xCells = xcells;

        end

        function obj = setyCells(obj, ycells)

            obj.yCells = ycells;

        end

        function obj = setxLine(obj, xline)

            obj.xLine = xline;

        end

        function obj = setyLine(obj, yline)

            obj.yLine = yline;

        end

    end
end

