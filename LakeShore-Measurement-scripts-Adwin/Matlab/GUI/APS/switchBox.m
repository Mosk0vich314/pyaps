classdef switchBox
    properties (Access = public)


        Settings
        Switch


    end

    methods (Access = public)

        function obj = switchBox(settings)

            obj.Settings = settings;

            obj.Switch.bit = 11;
            obj.Switch.process = 'Single_DO';

            obj.Settings = Init_ADwin_load_process(obj.Settings, obj.Switch);
            Set_Processdelay(5, 100000);
            Set_Par(50, obj.Switch.bit);

        end

        function obj = startRoutine(obj)

            Start_Process(5);
            Set_Par(51, 0);
            Set_Par(51, 1);
            pause(0.01)
            Set_Par(51, 0);
            Stop_Process(5);

        end

    end

end
