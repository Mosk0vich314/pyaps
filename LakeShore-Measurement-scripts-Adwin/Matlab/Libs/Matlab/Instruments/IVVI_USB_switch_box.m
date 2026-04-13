classdef IVVI_USB_switch_box < handle

    properties (SetAccess = private)
        serial_address
    end

    properties (Transient)
        device
        resistance_values
    end

    methods

        function Resistor_box = IVVI_USB_switch_box(address)
            address = upper(address);
            Resistor_box.serial_address = address;
            Resistor_box.device = serialport(address,9600,'StopBits',1,'Parity','none','DataBits',8);
            set(Resistor_box.device,'Timeout',2)

        end

        %% set resistance position
        function set_resistance_pos(Resistor_box, value)
            fopen(Resistor_box.device);
            str = sprintf('bin/set %01d', value);
            fprintf(Resistor_box.device, str);
        end

        %% set resistance Ohm
        function [pos, resistance, resistance_str] = set_resistance_Ohm(Resistor_box, value)

            idx = find(min(abs(Resistor_box.resistance_values - value)) == abs(Resistor_box.resistance_values - value)) - 1;

            pos = idx + 1;

            resistance = Resistor_box.resistance_values(idx + 1);

            fopen(Resistor_box.device);
            str = sprintf('bin/set %01d', idx);
            fprintf(Resistor_box.device, str);
            strtrim(fscanf(Resistor_box.device)); % read useless line
            resistance_str = strtrim(fscanf(Resistor_box.device));
        end

        %% get resistance pos
        function output = get_resistance_pos(Resistor_box)

            fopen(Resistor_box.device);
            fprintf(Resistor_box.device, 'bin/get_pos');
            strtrim(fscanf(Resistor_box.device));
            output = str2double(strtrim(fscanf(Resistor_box.device)));
        end

        %% get resistance Ohm
        function output = get_resistance_Ohm(Resistor_box)
            fopen(Resistor_box.device);
            fprintf(Resistor_box.device, 'bin/get_res');
            strtrim(fscanf(Resistor_box.device));
            strtrim(fscanf(Resistor_box.device));
            output = strtrim(fscanf(Resistor_box.device));

        end

        %% get resistance Ohm list
        function array = get_resistance_Ohm_list(Resistor_box)
            fopen(Resistor_box.device);
            fprintf(Resistor_box.device, 'bin/get_res_all');
            strtrim(fscanf(Resistor_box.device));
            string = strtrim(fscanf(Resistor_box.device));
            array = str2double(strsplit(string, ','))';
            Resistor_box.resistance_values = array;
        end



    end
end
