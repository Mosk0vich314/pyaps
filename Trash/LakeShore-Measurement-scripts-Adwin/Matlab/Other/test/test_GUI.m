%% clear
clear
close all hidden
clc
tic

%% Settings
Settings.save_dir = 'C:\Samples\test';
Settings.sample = '1MOhm'; %A2-GatetoGate G0b Test_100MOhm_50ohm_termination
Settings.ADC = {1e6, 'off', 'off', 'off', 'off', 'off', 'off', 'off', 'off'};
Settings.auto = ''; % FEMTO
Settings.ADC_gain = [0 0 0 0 0 0 0 0]; % 2^N
Settings.get_sample_T = 'Oxford_ITC'; % {'', 'Lakeshore336', 'Lakeshore325', 'Oxford_ITC'}
Settings.type = 'IV';
Settings.ADwin = 'GoldII'; % GoldII or ProII
Settings.res4p = 0;     % 4 point measurement
Settings.T = 0.01;   %;

Gate.initV = 0;          % V
Gate.targetV = 1;            % V
Gate.endV = 0;            % V
Gate.ramp_rate = 1;       % V/s
Gate.V_per_V = 1;          % V/V0
Gate.output = 3;            % AO channel
Gate.process_number = 3;
Gate.process = 'Fixed_AO';

% ADwin
Timetrace.scanrate = 45000;       % Hz
Timetrace.points_av = 1 * Timetrace.scanrate / 50;        % points
Timetrace.settling_time = 0;      % ms
Timetrace.settling_time_autoranging = 0;      % ms
Timetrace.clim = [];
Timetrace.process = 'Read_AI_single_value_multi';

Settings.N_output = 8;
Settings.N_input = 2;

%% Initialize
Settings = Init(Settings);

%% Initialize ADwin
Settings = Init_ADwin(Settings, Timetrace, Gate);

%% Init startV and setV
Gate.startV = Gate.initV;

%% GUI AO
fig = uifigure;
fig.Position = [300 500 1500 500];
fig.Name = 'Setting Voltage';

% set V
Layout.sv = uieditfield(fig);
Layout.sv.Value = 'Set Voltage:';
Layout.sv.Editable = 'off';
Layout.sv.Position = [20 125 100 22];

for i = 1:Settings.N_output
    Layout.rf_display(i) = uieditfield(fig, "numeric", 'ValueDisplayFormat','%.2f V' );
    Layout.rf_display(i).Value = 0;
    Layout.rf_display(i).Position = [150 + (i-1)*50 150 50 22];
    Layout.rf_display(i).Editable = 'off';
end

% current V
Layout.rf = uieditfield(fig);
Layout.rf.Value = 'Current Voltage:';
Layout.rf.Editable = 'off';
Layout.rf.Position = [20 150 100 22];

for i = 1:Settings.N_output
    Layout.vf(i) = uieditfield(fig, "numeric", 'ValueDisplayFormat','%.2f V');
    Layout.vf(i).Value = 0;
    Layout.vf(i).Position = [150 + (i-1)*50 125 50 22];
end

for i = 1:Settings.N_output
    Layout.sb_AO(i) = uibutton(fig,'push',...
        "Text","Start",...
        "Position", [150 + (i-1)*50 50 50 22],...
        "ButtonPushedFcn",@(src, event) buttonPushed(fig));
end

drawnow

% store current AO voltage
Layout.currentV = zeros(Settings.N_output, 1);
for i = 1:Settings.N_output
    Layout.currentV(i) = Layout.vf(i).Value;
end

% save data to GUI
Data = struct('Layout',Layout,'Gate',Gate,'Settings',Settings);
guidata(fig, Data);

%% GUI AI
Layout.ot = uieditfield(fig);
Layout.ot.Position = [150 250 100 22];
Layout.ot.Editable = 'off';
Layout.ot.Value = 'Current:';

for i = 1:Settings.N_input
    Layout.ov(i) = uieditfield(fig, "numeric", 'ValueDisplayFormat','%.4e');
    Layout.ov(i).Editable = 'off';
    Layout.ov(i).Value = 0;
    Layout.ov(i).Position = [150 + (i-1)*50 250 50 22];
end

drawnow

%% set parameters AI
Timetrace.process_delay = round(Settings.clockfrequency / Timetrace.scanrate);
Timetrace.time_per_point = (Timetrace.points_av / Timetrace.scanrate); % 1/sampling rate
Timetrace.sampling_rate = 1 / Timetrace.time_per_point;

% set ADCs
Set_Par(10, Settings.input_resolution);

% set addresses
Set_Par(5,Settings.AI_address);
Set_Par(6,Settings.AO_address);
Set_Par(7,Settings.DIO_address);

% Inputs timetrace
Set_Par(21, Timetrace.points_av);

% set ADC gains
SetData_Double(11, Settings.ADC_gain, 1);

% run measurement
Set_Processdelay(2, Timetrace.process_delay);

%% reset all outputs
for i = 1:Settings.N_output
    Data.Gate.startV = 0;
    Data.Gate.setV = 0;
    Data = Apply_voltage(Data, i);
end

%% read AI
Start_Process(2);
while Process_Status(2)
    for i = 1:Settings.N_input
        Layout.ov(i).Value = Get_FPar(i);
    end
    drawnow
end

%% Callback buttonPushed_AO1
function buttonPushed(fig)

% get gui data
Data = guidata(fig);

% get AO index
Data.Layout.setV = zeros(Data.Settings.N_output, 1);
for i = 1:Data.Settings.N_output
    Data.Layout.setV(i) = Data.Layout.vf(i).Value;
end

index = find(Data.Layout.setV ~=  Data.Layout.currentV)

if ~isempty(index)
    % apply volage
    Data.Gate.setV = Data.Layout.vf(index).Value;
    %Data.Gate.ramp_rate = Data.Layout.vf(index).Value;
    Data = Apply_voltage(Data, index);
    Data.Gate.startV = Data.Gate.setV;

    Data.Layout.currentV = Data.Layout.setV;

    % store gui data
    guidata(fig, Data);

end
end

function Data = Apply_voltage(Data, index)

Settings = Data.Settings;
Gate = Data.Gate;

% set output number
Set_Par(9, index);

% set ramp rate by adjusting process delay
Gate.max_frequency =  Gate.ramp_rate / ((Settings.output_max - Settings.output_min) / (2^Settings.output_resolution)) / Gate.V_per_V;
Gate.time_per_point = 1 / Gate.max_frequency;
[Gate.process_delay, ~]  =  get_delays(Gate.max_frequency, 0, Settings.clockfrequency);
Set_Processdelay(3, Gate.process_delay);

% set startV bin
[Gate.startV_bin, Gate.startV_new] = convert_V_to_bin(Gate.startV / Gate.V_per_V, Settings.output_min, Settings.output_max, Settings.output_resolution);
Gate.startV_new = Gate.startV_new * Gate.V_per_V;
Gate.startV_bin = Gate.startV_bin - 1;
Set_Par(41, Gate.startV_bin);

% set setV bin
[Gate.setV_bin, Gate.setV_new] = convert_V_to_bin(Data.Gate.setV / Gate.V_per_V, Settings.output_min, Settings.output_max, Settings.output_resolution);
Gate.setV_new = Gate.setV_new * Gate.V_per_V;
Gate.setV_bin = Gate.setV_bin - 1;
Set_Par(42, Gate.setV_bin);

% start process
Start_Process(3);

% read during execution
bin_size = (Settings.output_max-Settings.output_min) / (2^Settings.output_resolution);
while Process_Status(3)
    Voltage = Settings.output_min + (Get_Par(40) * bin_size) / 2^Settings.ADC_gain(1);
    Data.Layout.rf_display(index).Value = Voltage;
    drawnow
end

end