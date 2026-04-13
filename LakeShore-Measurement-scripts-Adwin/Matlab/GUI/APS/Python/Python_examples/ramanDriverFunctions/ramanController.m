classdef ramanController

    properties
        Value
    end

     properties (Transient)
        Stepper
     end

    methods
        function obj = ramanController

            obj.Stepper.blue = StepperMotor('COM8');
            obj.Stepper.green = StepperMotor('COM6');
            obj.Stepper.red = StepperMotor('COM5');

        end

        %% identify device
        function output = move(obj, x, y)
            command = sprintf('python move.py %1.3f %1.3f',x,y);
            disp(command)
            [~, output] = system(command);
            output = strtrim(output);
        end

        function output = takeImage(obj, saveName)
            command = sprintf('python takeImage.py %s',saveName);
            disp(command)
            [~, output]= system(command);
            output = strtrim(output);
        end

        function output = autoFocus(obj)
            command = 'python autoFocus.py';
            disp(command)
            [~, output]= system(command);
            output = strtrim(output);
        end

        function output = autoSave(obj, saveName)
            command = sprintf('python autoSave.py %s',saveName);
            disp(command)
            [~, output]= system(command);
            output = strtrim(output);
        end

        function output = checkActivity(obj)
            command = 'python checkActivity.py';
            disp(command)
            [~, output]= system(command);
            output = strtrim(output);
        end

        function output = takeDepthScan(obj, saveName, intTime, width, depth, points, lines, centerX, centerY, centerZ, rotation, power)
            command = sprintf('python takeDepthScan.py %s %1.3f %1.3f %1.3f %d %d %1.3f %1.3f %1.3f %1.3f %1.3f', saveName, intTime, width, depth, points, lines, centerX, centerY, centerZ, rotation, power);
            disp(command)
            [~, output]= system(command);
            output = strtrim(output);
        end

        function output = takeAreaScan(obj, saveName, intTime, width, height, points, lines, centerX, centerY, centerZ, rotation, power)
            command = sprintf('python takeAreaScan.py %s %1.3f %1.3f %1.3f %d %d %1.3f %1.3f %1.3f %1.3f %1.3f', saveName, intTime, width, height, points, lines, centerX, centerY, centerZ, rotation, power);
            disp(command)
            [~, output]= system(command);
            output = strtrim(output);
        end

        function output = saveData(obj, saveName)
            command = sprintf('python saveData.py %s', saveName);
            disp(command)
            [~, output]= system(command);
            output = strtrim(output);
        end
 
        %% Polarization with Stepper motor
        function set_polariation_blue(obj, degree)
            obj.Stepper.blue.set_polariation(degree)
        end
        function set_polariation_green(obj, degree)
            obj.Stepper.green.set_polariation(degree)
        end
        function set_polariation_red(obj, degree)
            obj.Stepper.red.set_polariation(degree)
        end

    end

end

