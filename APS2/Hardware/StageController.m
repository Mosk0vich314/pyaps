classdef StageController < handle
    % StageController - Manages the 4 ESCO Stepper Motors
    % Configuration Hardcoded from MAC_Setup_v1.0_current20260107.xml
    
    properties (Access = public)
        MotorX
        MotorY
        MotorZ
        MotorRot
        
        IsConnected (1,1) logical = false
    end
    
    methods (Static)
        function Config = GetDefaultConfig()
            % Returns the master configuration struct for all axes.
            % Used by MotorTest.m to sync settings.
            Config = struct();
            
            % --- MOTOR X ---
            Config.X.Port="COM5"; Config.X.Addr=1;
            Config.X.Conv=3.98438e-6; Config.X.EncRatio=-6.42; 
            Config.X.HomeDir=1; Config.X.LimL=4; Config.X.LimU=2; Config.X.HomeSw=4;
            Config.X.EncType=2;
            
            % --- MOTOR Y ---
            Config.Y.Port="COM6"; Config.Y.Addr=2;
            Config.Y.Conv=3.98438e-6; Config.Y.EncRatio=-6.42; 
            Config.Y.HomeDir=1; Config.Y.LimL=4; Config.Y.LimU=0; Config.Y.HomeSw=4;
            Config.Y.EncType=2;
            
            % --- MOTOR Z ---
            Config.Z.Port="COM8"; Config.Z.Addr=3;
            Config.Z.Conv=9.75e-6;    Config.Z.EncRatio=2.56261; 
            Config.Z.HomeDir=1; Config.Z.LimL=3; Config.Z.LimU=1; Config.Z.HomeSw=3;
            Config.Z.EncType=2;
            
            % --- MOTOR ROT ---
            Config.Rot.Port="COM7"; Config.Rot.Addr=0;
            Config.Rot.Conv=3.9062e-5; Config.Rot.EncRatio=1.0; 
            Config.Rot.HomeDir=0; Config.Rot.LimL=0; Config.Rot.LimU=0; Config.Rot.HomeSw=2;
            Config.Rot.EncType=0;
        end
    end
    
    methods
        function obj = StageController(OverrideConfig)
            % Constructor: StageController(OverrideConfig)
            
            fprintf('--- StageController: Initializing 4 Motors...\n');
            
            % Get Defaults
            C = StageController.GetDefaultConfig();
            
            % Apply Overrides if provided
            if nargin > 0 && ~isempty(OverrideConfig)
                if isfield(OverrideConfig, 'X'), C.X.Port = OverrideConfig.X.Port; C.X.Addr = OverrideConfig.X.Addr; end
                if isfield(OverrideConfig, 'Y'), C.Y.Port = OverrideConfig.Y.Port; C.Y.Addr = OverrideConfig.Y.Addr; end
                if isfield(OverrideConfig, 'Z'), C.Z.Port = OverrideConfig.Z.Port; C.Z.Addr = OverrideConfig.Z.Addr; end
                if isfield(OverrideConfig, 'Rot'), C.Rot.Port = OverrideConfig.Rot.Port; C.Rot.Addr = OverrideConfig.Rot.Addr; end
                fprintf('   (Using detected/overridden ports)\n');
            end
            
            try
                obj.MotorX = obj.InitAxis("X", C.X);
                obj.MotorY = obj.InitAxis("Y", C.Y);
                obj.MotorZ = obj.InitAxis("Z", C.Z);
                obj.MotorRot = obj.InitAxis("Rot", C.Rot);
                
                obj.IsConnected = true;
                fprintf('--- StageController: All 4 Motors Ready.\n');
            catch ME
                fprintf(2, 'StageController Init Failed: %s\n', ME.message);
                obj.delete(); 
                obj.IsConnected = false;
                rethrow(ME);
            end
        end
        
        function delete(obj)
            if ~isempty(obj.MotorX), delete(obj.MotorX); end
            if ~isempty(obj.MotorY), delete(obj.MotorY); end
            if ~isempty(obj.MotorZ), delete(obj.MotorZ); end
            if ~isempty(obj.MotorRot), delete(obj.MotorRot); end
        end
        
        % Relative moves
        function MoveX(obj, dist), obj.Move(obj.MotorX, dist); end
        function MoveY(obj, dist), obj.Move(obj.MotorY, dist); end
        function MoveZ(obj, dist), obj.Move(obj.MotorZ, dist); end
        function MoveTheta(obj, angle), obj.Move(obj.MotorRot, angle); end

        % Absolute moves (target position from last ZeroXY call)
        function MoveToX(obj, pos), obj.MoveAbs(obj.MotorX, pos); end
        function MoveToY(obj, pos), obj.MoveAbs(obj.MotorY, pos); end
        function MoveToZ(obj, pos), obj.MoveAbs(obj.MotorZ, pos); end

        function ZeroXY(obj)
            % Sets current XY position as the absolute origin (call when aligned on ref device)
            if ~isempty(obj.MotorX), obj.MotorX.zero_position(); end
            if ~isempty(obj.MotorY), obj.MotorY.zero_position(); end
        end

        function pos = GetPositionX(obj), pos = obj.MotorX.get_position(); end
        function pos = GetPositionY(obj), pos = obj.MotorY.get_position(); end
        function pos = GetPositionZ(obj), pos = obj.MotorZ.get_position(); end

        function Stop(obj)
            if ~isempty(obj.MotorX), try obj.MotorX.stop_movement(); catch, end; end
            if ~isempty(obj.MotorY), try obj.MotorY.stop_movement(); catch, end; end
            if ~isempty(obj.MotorZ), try obj.MotorZ.stop_movement(); catch, end; end
            if ~isempty(obj.MotorRot), try obj.MotorRot.stop_movement(); catch, end; end
        end
    end
    
    methods (Access = private)
        function m = InitAxis(~, name, Cfg)
            m = StepperMotor(name, Cfg.Port, Cfg.Addr);
            m.ConversionFactor = Cfg.Conv;
            m.EncoderRatio = Cfg.EncRatio;
            m.HomingDir = Cfg.HomeDir;
            m.LimitLower = Cfg.LimL;
            m.LimitUpper = Cfg.LimU;
            m.HomeSwitch = Cfg.HomeSw;
            m.EncoderType = Cfg.EncType;
            m.apply_settings();
            m.drive_on();
        end
        
        function Move(~, motorObj, val)
             if ~isempty(motorObj)
                 if ismethod(motorObj, 'move_relative_mms')
                     if contains(motorObj.Name, "Rot")
                         motorObj.move_relative_degrees(val);
                     else
                         motorObj.move_relative_mms(val);
                     end
                 else
                     motorObj.move_relative_units(val);
                 end

                 tic;
                 while toc < 10
                     s = motorObj.get_status_parsed();
                     if ~s.Moving, break; end
                     pause(0.05);
                 end
             end
        end

        function MoveAbs(~, motorObj, val)
            if ~isempty(motorObj)
                if contains(motorObj.Name, "Rot")
                    motorObj.move_absolute_degrees(val);
                else
                    motorObj.move_absolute_mms(val);
                end

                tic;
                while toc < 10
                    s = motorObj.get_status_parsed();
                    if ~s.Moving, break; end
                    pause(0.05);
                end
            end
        end
    end
end