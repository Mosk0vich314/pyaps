classdef StepperMotor < handle
    % StepperMotor - Improved Controller for ESCO Motors
    % Includes unit conversion, address verification, and status parsing.
    
    properties (Access = public)
        PortName string
        Address (1,1) double = 1 % Default Address
        Name string = "Motor"
        ConversionFactor double = 1.0; % Units per Step (mm or degrees)
        EncoderRatio double = 1.0; % Encoder Ratio
    end
    
    % Configurable Hardware Settings
    properties (Access = public)
        MotorCurrent    double = 3;  % 3 = 1A
        HoldCurrent     double = 0;  % 0 = 0%
        Microstepping   double = 0;  % 0 = 256
        Velocity        double = 100000;
        Acceleration    double = 5000;
        EncoderType     double = 2;  % 2 = Quadrature
        LimitLower      double = 0;  % 0 = None
        LimitUpper      double = 0;  % 0 = None
        HomeSwitch      double = 0;  % 0 = None
        HomingDir       double = 0;  % 0=Pos, 1=Neg
    end

    properties (Access = private)
        serialObj
        terminator = 'CR/LF';
        baudRate = 115200;
        timeout = 2;
    end

    methods
        function obj = StepperMotor(varargin)
            % Constructor supports two modes:
            % 1. obj = StepperMotor(comPort)  -> Legacy/Simple mode
            % 2. obj = StepperMotor(name, comPort, address) -> Full mode
            
            if nargin == 1
                % Legacy mode: StepperMotor('COM3')
                obj.Name = "Motor";
                obj.PortName = varargin{1};
                obj.Address = 1; % Default
            elseif nargin == 3
                % Full mode: StepperMotor("X", "COM7", 1)
                obj.Name = varargin{1};
                obj.PortName = varargin{2};
                obj.Address = varargin{3};
            else
                error('Invalid arguments. Use StepperMotor(port) or StepperMotor(name, port, address).');
            end

            try
                obj.serialObj = serialport(obj.PortName, obj.baudRate);
                obj.serialObj.Timeout = obj.timeout;
                configureTerminator(obj.serialObj, obj.terminator);
                flush(obj.serialObj);
            catch ME
                error('Failed to open %s for %s. Check connection.', obj.PortName, obj.Name);
            end
            
            pause(0.2);
            fprintf('--- Connecting to %s (%s)...', obj.Name, obj.PortName);
            
            % Check Communication & Address
            idn = obj.get_id();
            if isempty(idn)
                delete(obj.serialObj);
                error(' Device %s not responding.', obj.Name);
            end
            
            % Verify Address
            if obj.Address >= 0
                addr = obj.get_address();
                if addr ~= obj.Address
                    warning('Address Mismatch on %s! Expected %d, got %d.', obj.Name, obj.Address, addr);
                else
                    fprintf(' Connected (Addr: %d).\n', addr);
                end
            else
                fprintf(' Connected (Address check skipped).\n');
            end
            
            % Auto-Enable Drive (As requested)
            obj.drive_on();
        end

        function delete(obj)
            if ~isempty(obj.serialObj) && isvalid(obj.serialObj)
                try
                    obj.stop_movement(); 
                    obj.drive_off(); 
                catch
                end
                delete(obj.serialObj);
                fprintf('--- Port %s (%s) closed.\n', obj.PortName, obj.Name);
            end
        end

        % --- Configuration ---
        function apply_settings(obj)
            try
                obj.set_setting('motor_current', obj.MotorCurrent);
                obj.set_setting('hold_current',  obj.HoldCurrent);
                obj.set_setting('microstepping', obj.Microstepping);
                obj.set_setting('velocity',      obj.Velocity);
                obj.set_setting('acceleration',  obj.Acceleration);
                obj.set_setting('encoder_type',  obj.EncoderType);
                obj.set_setting('set_es_lower',  obj.LimitLower);
                obj.set_setting('set_es_upper',  obj.LimitUpper);
                obj.set_setting('set_home',      obj.HomeSwitch);
                
                % Note: EncoderRatio setting requires specific firmware support command
                % obj.set_setting('encoder_ratio', obj.EncoderRatio);
                
                fprintf('--- Settings applied to %s.\n', obj.Name);
            catch ME
                warning('Failed to apply settings to %s: %s', obj.Name, ME.message);
            end
        end

        % --- Movement (Calibrated Units) ---
        
        % Primary Methods (Millimeters)
        function move_relative_mms(obj, mms)
            % Converts mm to steps using ConversionFactor
            steps = round(mms / obj.ConversionFactor);
            obj.move_relative(steps);
        end

        function move_absolute_mms(obj, mms)
            % Converts mm to steps using ConversionFactor
            steps = round(mms / obj.ConversionFactor);
            obj.move_absolute(steps);
        end
        
        % Aliases for Rotation (Degrees)
        % These do the exact same math, but allow semantic clarity for Rot stage
        function move_relative_degrees(obj, deg)
            steps = round(deg / obj.ConversionFactor);
            obj.move_relative(steps);
        end
        
        function move_absolute_degrees(obj, deg)
            steps = round(deg / obj.ConversionFactor);
            obj.move_absolute(steps);
        end
        
        % --- Basic Commands ---
        function idn = get_id(obj)
            idn = obj.sendCommand('*IDN?', 'query');
        end
        
        function addr = get_address(obj)
            resp = obj.sendCommand('get_address', 'query');
            addr = str2double(resp);
        end

        function ver = get_version(obj)
            ver = obj.sendCommand('get_version', 'query');
        end
        
        function volts = get_voltages(obj)
             volts = obj.sendCommand('get_voltages', 'query');
        end

        % --- Status ---
        function status = get_status_parsed(obj)
            resp = obj.sendCommand('get_status', 'query');
            val = str2double(resp);
            
            status = struct();
            status.Raw = val;
            status.Undervoltage       = bitget(val, 1);
            status.CommError          = bitget(val, 2);
            status.Moving             = bitget(val, 3);
            status.MovingDir          = bitget(val, 4);
            status.MotorError         = bitget(val, 5);
            status.OvertempPre        = bitget(val, 6);
            status.Overtemp           = bitget(val, 7);
            status.OpenCable          = bitget(val, 8);
            status.ShortCircuit       = bitget(val, 9);
            status.Stall              = bitget(val, 10);
            status.UpperLimitHit      = bitget(val, 11);
            status.LowerLimitHit      = bitget(val, 12);
            status.HomeSwitchHit      = bitget(val, 13);
        end

        function pos = get_position(obj)
            resp = obj.sendCommand('get_position', 'query');
            steps = str2double(resp);
            % Return position in calibrated UNITS (mm or degrees)
            pos = steps * obj.ConversionFactor;
        end

        % --- Hardware Commands ---
        function move_absolute(obj, steps)
            obj.sendCommand(sprintf('move_absolute %d', steps), 'set');
        end

        function move_relative(obj, steps)
            obj.sendCommand(sprintf('move_relative %d', steps), 'set');
        end
        
        function move_velocity(obj, direction)
            if (ischar(direction) || isstring(direction))
                if strcmpi(direction, 'negative') || direction == "-"
                    cmd = "const_v-";
                else
                    cmd = "const_v+";
                end
            else
                if direction == 1
                    cmd = "const_v-";
                else
                    cmd = "const_v+";
                end
            end
            obj.sendCommand(cmd, 'set');
        end

        function home(obj, direction)
            if nargin < 2
                direction = obj.HomingDir;
            end
            obj.sendCommand(sprintf('home %d', direction), 'set');
        end

        function stop_movement(obj)
            obj.sendCommand('stop_movement', 'set');
        end
        
        function zero_position(obj)
            obj.sendCommand('zero_position', 'set');
        end
        
        function set_output(obj, state)
            obj.sendCommand(sprintf('set_output1 %d', state), 'query'); 
        end

        % --- System ---
        function drive_on(obj)
            obj.sendCommand('drive_on', 'set');
        end

        function drive_off(obj)
            obj.sendCommand('drive_off', 'set');
        end
        
        function set_setting(obj, name, val)
            obj.sendCommand(sprintf('set_setting %s %d', name, val), 'set');
        end

        function val = get_setting(obj, name)
            resp = obj.sendCommand(sprintf('get_setting %s', name), 'query');
            val = str2double(resp);
        end
    end
    
    methods (Access = private)
        function ok = check_communication(obj)
            resp = obj.sendCommand('*IDN?', 'query', true);
            ok = ~isempty(resp) && ~contains(resp, 'Error');
        end

        function response = sendCommand(obj, cmd, type, silent)
            if nargin < 4, silent = false; end
            
            response = '';
            try
                flush(obj.serialObj);
                writeline(obj.serialObj, cmd);
                
                if strcmpi(type, 'query')
                    response = readline(obj.serialObj);
                    response = strtrim(response);
                    if startsWith(response, cmd), response = extractAfter(response, cmd); end
                    response = strtrim(response);
                else
                    pause(0.05); 
                    if obj.serialObj.NumBytesAvailable > 0
                        readline(obj.serialObj);
                    end
                end
            catch ME
                if ~silent
                    warning('Serial Error on "%s": %s', cmd, ME.message);
                end
            end
        end
    end
end