classdef SCU < handle
    % SCU
    properties (Access = public)
        frequency
        amplitude
        stage
        probes
        stepFactorX = 0.507
        stepFactorY = 0.524
        corrFactorX = 1.162
        corrFactorY = 0.862
    end

    methods (Access = public)
        % Constructor
        function obj = SCU
            obj.amplitude = 100;
            obj.frequency = 1000;
            obj.stage = py.pylablib.devices.SmarAct.SCU3D(0);
            obj.probes = py.pylablib.devices.SmarAct.SCU3D(1);
            % SCU Construct an instance of this class
        end

    end

    methods (Access = private)

        function move_stage(obj, steps, axis)

            obj.stage.move_macrostep(axis, steps, obj.amplitude, obj.frequency);
            pause(abs(steps/50));

        end

        function move_probes(obj, steps, axis)
            
            obj.probes.move_macrostep(axis, steps, obj.amplitude, obj.frequency);
            % pause(abs(steps/100));
        end

     end

    methods (Access = public)

        function obj = setAmplitude(obj, amplitude)

            obj.amplitude = amplitude;

        end

        function amplitudeValue = getAmplitude(obj)

            amplitudeValue = obj.amplitude;

        end

        function obj = setFrequency(obj, frequency)

            obj.frequency = frequency;

        end

        function frequencyValue = getFrequency(obj)

            frequencyValue = obj.frequency;

        end

        function move_x(obj, steps)

            axis = 'x';
            steps = steps * obj.stepFactorX;

            if steps < 0 
                steps = steps * obj.corrFactorX;
            end

            move_stage(obj, -steps, axis);

        end

        function move_y(obj, steps)

            axis = 'y';
            steps = steps * obj.stepFactorY;

            if steps > 0 
                steps = steps * obj.corrFactorY;
            end
            move_stage(obj, steps, axis);
            
        end

        function move_theta(obj, steps)

            axis = 'z';
            move_stage(obj, -steps, axis);
            
        end

        function move_leftProbe(obj, steps)

            axis = 'x';
            move_probes(obj, steps, axis);
            
        end

        function move_rightProbe(obj, steps)

            axis = 'y';
            move_probes(obj, steps, axis);

        end

        function emergencyStop(obj)

            obj.stage.stop();
            obj.probes.stop();

        end
    end
end