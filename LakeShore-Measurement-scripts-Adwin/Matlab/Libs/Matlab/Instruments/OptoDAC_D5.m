classdef OptoDAC_D5 < handle
    
    properties (SetAccess = private)
        serial_address
    end
    
    properties (Transient)
        device
        error
    end
    
    methods
        
        function OptoDAC = OptoDAC_D5(address)
            OptoDAC.serial_address = address;
            try
                OptoDAC.device = serialport(OptoDAC.serial_address, 115200, 'Parity','odd','DataBits',8,'StopBits',1,'Timeout',1);
                OptoDAC.error = 0;
            catch
                OptoDAC.error = 1;
            end
            if OptoDAC.error ~= 0
                errordlg('Could not connect to OptoDAC')
            end
        end
        
        %% identify device
        function output = identify(OptoDAC)
            pattern = [4 0 3 4];
            write(OptoDAC.device, pattern,'uint8');
            output = read(OptoDAC.device, 3, 'uint8');
            OptoDAC.error = output(2);
            output = output(3);
            
        end
        
        %% send continous
        function send_continous(OptoDAC)
            pattern = [7 0 2 3 1 0 0];
            write(OptoDAC.device, pattern,'uint8');
            output = read(OptoDAC.device, 2, 'uint8');
            OptoDAC.error = output(2);
        end
        
        %% Set DAC
        function set_DAC(OptoDAC, DACno,  voltage)
            bin = convert_V_to_bin(voltage, -2, 2, 16)-1;
            if bin < 0
                bin = 0;
            end
            if bin > 65535
                bin = 65535;
            end
            
            byte16  = dec2bin(bin, 16);
            dataH = bin2dec(byte16(1:8));
            dataL = bin2dec(byte16(9:16));
            pattern = [7 0 2 1 DACno dataH dataL];
            try
                write(OptoDAC.device, pattern,'uint8');
                output = read(OptoDAC.device, 2, 'uint8');
                OptoDAC.error = output(2);
            catch
                OptoDAC.error = 1;
            end
            if OptoDAC.error ~= 0
                errordlg('Could not connect to OptoDAC')
            end
        end
        
        %% Read DAC
        function output = read_DAC(OptoDAC)
            pattern = [4 0 34 2];
            try
                write(OptoDAC.device, pattern,'uint8');
                output = read(OptoDAC.device, 36, 'uint8');
                
                OptoDAC.error = output(4);
                output_bytes = output(5:36);
                output_bytes = reshape(output_bytes, [2 16])';
                output = zeros(16, 1);
                for i = 1:16
                    output(i) = bin2dec([dec2bin(output_bytes(i, 1), 8) dec2bin(output_bytes(i, 2), 8)]) + 1;
                    output(i) = convert_bin_to_V(output(i), 2, 16);
                end
                
            catch
                OptoDAC.error = 1;
            end
            if OptoDAC.error ~= 0
                errordlg('Could not connect to OptoDAC')
            end
            
        end
    end
    
end

%  http://qtwork.tudelft.nl/~schouten/ivvi/doc-d5/rs232linkformat.txt
% RS232 PROTOCOL
% -----------------------
% BAUTRATE 	115200
% DATA BITS	8
% PARITY 		ODD
% STOPBITS	1
%
%
%
%
% 				Descriptor data PC-> MC
%
% Byte	Name			RAM	Description				value
% --------------------------------------------------------------------------------------------------------
% 1	Descriptor size		$200 	Size of this descriptor			4 (action 2,4)
% 										7 (action 1,3)
% 										11 (action 5)
% 2	Error			$201 						0
% 3	Data out size		$202 	Number of bytes that has to be 		2 (action 1,3,5)
% 					send by the MC after receiving 		3 (action 4)
% 					descriptor				34 (action 2)
%
% 4	Action			$203 						1= set Dac value
% 										2= request DAC data
% 										3= continues send data to DAC
% 						   				   (For testing fibre pulse)
% 										4= ask for Program version
% 										5= set bits interface
%
% 5	Dac nr			$204 	Nr of DAC to be updated			1 to 16
% 6	DataH			$205 	High byte to DAC			0 to $ff
% 7	DataL			$206 	Low byte to DAC				0 to $ff
% 8	data bit 24-31		$207	interfaceBit24_31			0 to $ff
% 9	data bit 16-23 		$208	interfaceBit16_23			0 to $ff
% 10	data bit 08-15		$209	interfaceBit08_15			0 to $ff
% 11	data bit 00-07		$20A	interfaceBit00_07			0 to $ff
% -----------------------------------------------------------------------------------------------------------
%
%
%
%
%
% 				Descriptor data MC-> PC
%
% Byte	Name			Size	RAM	Description
% -----------------------------------------------------------------------------------------------------------
% 1	Descriptor size		1	$100 	Size of this descriptor
% 2	Error			1	$101 	0b00000000 = no Error detected
% 						0b00000001 =
% 						0b00000010 =
% 						0b00000100 =
% 						0b00001000 =
% 						0b00010000 =
% 						0b00100000 = WatchDog reset detected (32)
% 							     (AFTER POWERINGUP OR RESTARTING THE MC
% 							     BY THE WATCHDOC THIS ERROR IS GENERATED)
% 						0b01000000 = DAC does not exist(64)
% 						0b10000000 = WrongAction (128)
%
% 3	High byte DAC1		2	$102 	Last send value to DAC1 read from RAM MC
% 4	Low byte DAC1			$103 	Last send value to DAC2 read from RAM MC
% 5	High byte DAC2		2	$104 	Last send value to DAC3 read from RAM MC
% 6	Low byte DAC2			$105 	Last send value to DAC4 read from RAM MC
% 7	High byte DAC3		2	$106 	Last send value to DAC5 read from RAM MC
% 8	Low byte DAC3			$107 	Last send value to DAC6 read from RAM MC
% 9	High byte DAC4		2	$108 	Last send value to DAC7 read from RAM MC
% 10	Low byte DAC4			$109 	Last send value to DAC8 read from RAM MC
% 11	High byte DAC5		2	$10A 	Last send value to DAC1 read from RAM MC
% 12	Low byte DAC5			$10B 	Last send value to DAC2 read from RAM MC
% 13	High byte DAC6		2	$10C 	Last send value to DAC3 read from RAM MC
% 14	Low byte DAC6			$10D 	Last send value to DAC4 read from RAM MC
% 15	High byte DAC7		2	$10E 	Last send value to DAC5 read from RAM MC
% 16	Low byte DAC7			$10F 	Last send value to DAC6 read from RAM MC
% 17	High byte DAC8		2	$110 	Last send value to DAC7 read from RAM MC
% 18	Low byte DAC8			$111 	Last send value to DAC8 read from RAM MC
% 19	High byte DAC9		2	$112 	Last send value to DAC1 read from RAM MC
% 20	Low byte DAC9			$113 	Last send value to DAC2 read from RAM MC
% 21	High byte DAC10		2	$114 	Last send value to DAC3 read from RAM MC
% 22	Low byte DAC10			$115 	Last send value to DAC4 read from RAM MC
% 23	High byte DAC11		2	$116 	Last send value to DAC5 read from RAM MC
% 24	Low byte DAC11			$117 	Last send value to DAC6 read from RAM MC
% 25	High byte DAC12		2	$118 	Last send value to DAC7 read from RAM MC
% 26	Low byte DAC12			$119 	Last send value to DAC8 read from RAM MC
% 27	High byte DAC13		2	$11A 	Last send value to DAC1 read from RAM MC
% 28	Low byte DAC13			$11B 	Last send value to DAC2 read from RAM MC
% 29	High byte DAC14		2	$11C 	Last send value to DAC3 read from RAM MC
% 30	Low byte DAC14			$11D 	Last send value to DAC4 read from RAM MC
% 31	High byte DAC15		2	$11E 	Last send value to DAC5 read from RAM MC
% 32	Low byte DAC15			$11F 	Last send value to DAC6 read from RAM MC
% 33	High byte DAC16		2	$120 	Last send value to DAC7 read from RAM MC
% 34	Low byte DAC16			$121 	Last send value to DAC8 read from RAM MC
%
%
%
%
%
%
%
%
%
%
%
% -----------------------------------------------------------------------------------------------------------
%
%
