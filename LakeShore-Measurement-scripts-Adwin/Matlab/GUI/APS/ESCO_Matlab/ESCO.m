classdef ESCO
    % ESCO
    properties (Access = public)
        Simulate (1,1) logical = false;        
        Identity (1,1) string  = ""
        Version (1,1) string = ""
        Address (1,1) uint8 {mustBeInteger} = NaN
        Connected (1,1) logical = false
        Status (1,1) uint16 {mustBeInteger} = NaN
        DriveMode (1,1) string {mustBeMember(DriveMode,["Off","On","Unknown"])} = "Unknown"
        Position (1,1) double {mustBeNumeric} = NaN
        StepsPerUnit (1,1) double {mustBeNumeric} = 142.222222
        Velocity (1,1) uint32 {mustBeInteger} = NaN
        Acceleration (1,1) uint32 {mustBeInteger} = NaN
        HoldCurrent (1,1) string {mustBeMember(HoldCurrent,["100%","50%","25%","0%"])} = "100%"
        MotorCurrent (1,1) string {mustBeMember(MotorCurrent,["0.2A","0.5A","0.75A","1A","1.5A","2A"])} = "2A"
        Microstepping (1,1) string {mustBeMember(Microstepping,["256","128","64","32","16","8","4","2","None"])} = "None"
        EncoderType (1,1) string {mustBeMember(EncoderType,["Software","SSI"])} = "Software"
        EndSwitch (1,1) string {mustBeMember(EndSwitch,["None","Lower","Upper","Both"])} = "None"
        EndSwitchPolarity (1,1) string {mustBeMember(EndSwitchPolarity,["Low","Inv_Lower","Inv_Upper","Inv_Both"])} = "Low"
    end
    properties (Access = private)
        Port (1,1) string = ""
        usbSerial (1,1)
        MS_Vals  = ["256","128","64","32","16","8","4","2","None"];
        HC_Vals  = ["100%","50%","25%","0%"];
        MC_Vals  = ["0.2A","0.5A","0.75A","1A","1.5A","2A"];
        ENC_Vals = ["Software","SSI"];
        ES_Vals  = ["None","Lower","Upper","Both"];
        ESP_Vals = ["Low","Inv_Lower","Inv_Upper","Inv_Both"];
    end

    methods
        % Constructor
        function obj = ESCO(port, simulate)
            % ESCO Construct an instance of this class
            if (nargin==2)
                obj.Port = port;
                obj.Simulate = simulate;
            else
                error("Specify a Port and Simulation Mode")
            end
        end
        % Connection
        function obj = Connect(obj)
            if ~obj.Simulate
                obj.usbSerial = serialport(obj.Port, 115200, ...
                        "StopBits", 1,...
                        "FlowControl","none",...
                        "DataBits",8,...
                        "Parity","none",...
                        "ByteOrder","big-endian");
                configureTerminator(obj.usbSerial,"CR/LF");
            end
            obj = Get_Address(obj);
            obj = Get_IDN(obj);
            obj = Get_Version(obj);
            obj = Set_DriveMode(obj,"On");
            obj = Get_AllSettings(obj);
            obj.Connected = true;
        end                
        function obj = Disconnect(obj)
            if ~obj.Simulate
                delete(obj.usbSerial);
                obj.Connected = false;
            end
        end
        % Genral Info
        function obj = Get_IDN(obj)
            if ~obj.Simulate
                writeline(obj.usbSerial,"*IDN?");
                obj.Identity = readline(obj.usbSerial);
            else
                obj.Identity = "Simulated Device";
            end
        end
        function obj = Get_Version(obj)
            if ~obj.Simulate
                obj.Version = CMD_Get(obj,"version");
            else
                obj.Version = "";
            end
        end
        function obj = Get_Address(obj)
            if ~obj.Simulate
                obj.Address = str2double(CMD_Get(obj,"address"));
            else
                obj.Address = 0;
            end
        end
        function obj = Set_DriveMode(obj, mode)
            if ~obj.Simulate
                if (mode=="On")
                    cmd="drive_on";
                    writeline(obj.usbSerial,cmd);
                    obj.DriveMode = "On";
                elseif (mode=="Off")
                    cmd="drive_off";
                    writeline(obj.usbSerial,cmd);
                    obj.DriveMode = "Off";
                else
                    error("Mode must be On or Off");
                    obj.DriveMode = "Unknown";
                end
            end
        end
        function obj = Get_Status(obj)
            if ~obj.Simulate
                obj.Status = str2double(CMD_Get(obj,"status"));
            else
                obj.Status = 0;
            end
        end
        % Position & Movement
        function obj = Get_Position(obj)
            if ~obj.Simulate
                steps = str2double(CMD_Get(obj,"position"));
                obj.Position = steps / obj.StepsPerUnit;
            else
                obj.Position = 0;
            end
        end
        function obj = Move_ABS(obj, value)
            if ~obj.Simulate
                % check value for integer
                obj = Get_Position(obj);
                steps = value * obj.StepsPerUnit;
                cmd="move_absolute " + num2str(steps) ;           
                writeline(obj.usbSerial,cmd);
            end
        end
        function obj = Move_REL(obj, value)
            if ~obj.Simulate
                % check value for integer
                obj = Get_Position(obj);
                steps = value * obj.StepsPerUnit;
                cmd="move_relative " + num2str(steps);            
                writeline(obj.usbSerial,cmd);
            end
        end
        function obj = Stop(obj)
            if ~obj.Simulate
                writeline(obj.usbSerial,"stop_movement");
            end
        end
        function obj = Zero_Position(obj)
            if ~obj.Simulate
                writeline(obj.usbSerial,"zero_position");
                obj = Get_Position(obj);
            end
        end
        function obj = WaitMoveDone(obj, timeout)
            % While loop with timeout & get position & get status
            % timeout is optional, default value is 60s
            arguments
                obj
                timeout (1,1) {mustBeNumeric} = 60
            end
            tStart=datetime;
            dt=0;
            obj = Get_Status(obj);
            while (bitget(obj.Status, 3) ~= 0) && (dt<timeout)
                obj = Get_Status(obj);
                obj = Get_Position(obj);
                dt=milliseconds(datetime-tStart)/1000;
                pause(0.1);
            end
            if dt>=timeout
                error("Timeout while waiting for movement done")
            end
        end
        % Settings
        function obj = Get_AllSettings(obj)
            obj = Get_Velocity(obj);
            obj = Get_Acceleration(obj);
            obj = Get_Microstepping(obj);
            obj = Get_HoldCurrent(obj);
            obj = Get_MotorCurrent(obj);
            obj = Get_EncoderType(obj);
            obj = Get_EndSwitch(obj);
            obj = Get_EndSwitchPolarity(obj);
        end        
        function obj = Set_Acceleration(obj, value)
            Setting_Set(obj,"acceleration", value);
            obj = Get_Acceleration(obj);
        end
        function obj = Get_Acceleration(obj)
            obj.Acceleration = str2double(Setting_Get(obj,"acceleration"));
        end
        function obj = Set_Velocity(obj, value)
            Setting_Set(obj,"velocity", value);
            obj = Get_Velocity(obj);
        end
        function obj = Get_Velocity(obj)
            obj.Velocity = str2double(Setting_Get(obj, "velocity"));
        end
        function obj = Set_Microstepping(obj, microsteps)
            value = find(obj.MS_Vals==microsteps)-1;
            reply = Setting_Set(obj,"microstepping",value);
        end
        function obj = Get_Microstepping(obj)
            reply = str2double(Setting_Get(obj,"microstepping"));
            obj.Microstepping = obj.MS_Vals(reply+1);
        end
        function obj = Set_HoldCurrent(obj, current)
            value = find(obj.HC_Vals==current)-1;
            reply = Setting_Set(obj,"hold_current",value);
        end
        function obj = Get_HoldCurrent(obj)
            reply = str2double(Setting_Get(obj,"hold_current"));
            obj.HoldCurrent = obj.HC_Vals(reply+1);
        end
        function obj = Set_MotorCurrent(obj, current)
            value = find(obj.MC_Vals==current)-1;
            reply = Setting_Set(obj,"microstepping",value);
        end
        function obj = Get_MotorCurrent(obj)
            reply = str2double(Setting_Get(obj,"microstepping"));
            obj.MotorCurrent = obj.MC_Vals(reply+1);
        end
        function obj = Set_EncoderType(obj, encoder)
            value = find(obj.ENC_Vals==encoder)-1;
            reply = Setting_Set(obj,"encoder_type",value);
        end
        function obj = Get_EncoderType(obj)
            reply = str2double(Setting_Get(obj,"encoder_type"));
            obj.EncoderType = obj.ENC_Vals(reply+1);
        end
        function obj = Set_EndSwitch(obj, switches)
            value = find(obj.ES_Vals==switches)-1;
            reply = Setting_Set(obj,"endswitches",value);
        end
        function obj = Get_EndSwitch(obj)
            reply = str2double(Setting_Get(obj,"endswitches"));
            obj.EndSwitch = obj.ES_Vals(reply+1);
        end
        function obj = Set_EndSwitchPolarity(obj, polarity)
            value = find(obj.ESP_Vals==polarity)-1;
            reply = Setting_Set(obj,"endswitches_polarity",value);
        end
        function obj = Get_EndSwitchPolarity(obj)
            reply = str2double(Setting_Get(obj,"endswitches_polarity"));
            obj.EndSwitchPolarity = obj.ESP_Vals(reply+1);
        end
    end

    methods (Access = private)
        function Reply = CMD_Get(obj,command)
            if ~obj.Simulate
                cmd = "get_"+command;
                writeline(obj.usbSerial,cmd);
                Reply = extractAfter(readline(obj.usbSerial),cmd);
            else
                Reply = "0";
            end
        end
        function Reply = Setting_Get(obj,seting)
            if ~obj.Simulate
                cmd="get_setting " + seting;
                writeline(obj.usbSerial,cmd);
                Reply = extractAfter(readline(obj.usbSerial),cmd);
            else
                Reply = "0";
            end
        end
        function Reply = Setting_Set(obj,setting, value)
            if ~obj.Simulate
                cmd="set_setting " + setting + " " + num2str(value);
                writeline(obj.usbSerial,cmd);
                Reply = "Set";
            else
                Reply = "0";
            end
        end
    end
end

