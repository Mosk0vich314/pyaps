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
Settings.N_input = 8;

Settings.ADC_gain = zeros(Settings.N_input, 1); % 2^N


%% Initialize
Settings = Init(Settings);

%% Initialize ADwin
Settings = Init_ADwin(Settings, Timetrace, Gate);

%% Init startV and setV
Gate.startV = Gate.initV;

%% GUI AO
fig = uifigure;
fig.Position = [300 300 1500 400];
figPos = fig.Position;
fig.Name = 'Setting Voltage';

% Plot AI
ax = uiaxes (fig, 'Position',[880 250 600 150]);
hLines = gobjects(Settings.N_input);
colors = lines(Settings.N_input);
for i =1:Settings.N_input
    hLines(i) = animatedline(ax, 'LineWidth',2, 'Color', colors(i,:));
end

%Fun
% Setup UIAxes
u = uiaxes(fig,'Position',[860 20 figPos(3)/3 figPos(4)/1.8]);
u.XTick = [];
u.YTick = [];
u.Visible = 'off';
% Show Image
cdata = imread('pic.png');
im = image(cdata,'Parent',u);
u.XLim = [0 inf];
u.YLim = [0 inf];

% Display AO
Layout.ao = uieditfield(fig);
Layout.ao.Value = 'AO';
Layout.ao.Editable = 'off';
Layout.ao.Position = [20 175  100 22];
Layout.ao.BackgroundColor = [0.3010 0.7450 0.9330];
Layout.ao.FontWeight = 'bold';

for i = 1:Settings.N_output
    Layout.ao_display(i) = uieditfield(fig, "numeric");
    Layout.ao_display(i).Value = (i);
    Layout.ao_display(i).Editable = 'off';
    Layout.ao_display(i).Position = [150+ (i-1)*75 175 75 22];
    Layout.ao_display(i).BackgroundColor = [0.3010 0.7450 0.9330];
    Layout.ao_display(i).FontWeight = 'bold';
end

% set V
Layout.sv = uieditfield(fig);
Layout.sv.Value = 'Set Voltage:';
Layout.sv.Editable = 'off';
Layout.sv.Position = [20 125 100 22];
Layout.sv.FontWeight = 'bold';


for i = 1:Settings.N_output
    Layout.rf_display(i) = uieditfield(fig, "numeric", 'ValueDisplayFormat','%.2f V' );
    Layout.rf_display(i).Value = 0;
    Layout.rf_display(i).Position = [150 + (i-1)*75 150 75 22];
    Layout.rf_display(i).Editable = 'off';
end

% current V
Layout.rf = uieditfield(fig);
Layout.rf.Value = 'Current Voltage:';
Layout.rf.Editable = 'off';
Layout.rf.Position = [20 150 100 22];
Layout.rf.FontWeight = 'bold';

for i = 1:Settings.N_output
    Layout.vf(i) = uieditfield(fig, "numeric",...
        "Limits",[-10 10],...
        "LowerLimitInclusive","on",...
        "UpperLimitInclusive","on",...
        'ValueDisplayFormat','%.2f V');
    Layout.vf(i).Value = 0;
    Layout.vf(i).Position = [150 + (i-1)*75 125 75 22];
end

% ramp rate
Layout.rr = uieditfield(fig);
Layout.rr.Value = 'Ramp Rate:';
Layout.rr.Editable = 'off';
Layout.rr.Position = [20 100 100 22];
Layout.rr.FontWeight = 'bold';

for i= 1:Settings.N_output
    Layout.rr_display(i) = uieditfield(fig,"numeric", 'ValueDisplayFormat','%.2f V/s'); % Not sure about V/s
    Layout.rr_display(i).Value = 1;
    Layout.rr_display(i).Position = [150+(i-1)*75 100 75 22];
end


%start buttons
for i = 1:Settings.N_output
    tagvalue = num2str(i);
    Layout.sb_AO(i) = uibutton(fig,'push',...
        "Text","Start",...
        "Position", [150 + (i-1)*75 50 75 22],...
        "ButtonPushedFcn",@(src, event) buttonPushed(fig, tagvalue,hLines));
    Layout.sb_AO(i).UserData = tagvalue;
end

drawnow

% store current AO voltage
Layout.currentV = zeros(Settings.N_output, 1);
for i = 1:Settings.N_output
    Layout.currentV(i) = Layout.vf(i).Value;
end

% GUI AI
% Display AI
Layout.ai = uieditfield(fig);
Layout.ai.Value = 'AI';
Layout.ai.Editable = 'off';
Layout.ai.Position = [20 275 100 22];
Layout.ai.BackgroundColor = [0.3010 0.7450 0.9330];
Layout.ai.FontWeight = 'bold';

for i = 1:Settings.N_input
    Layout.ai_display(i) = uieditfield(fig, "numeric");
    Layout.ai_display(i).Value = (i);
    Layout.ai_display(i).Editable = 'off';
    Layout.ai_display(i).Position = [150+ (i-1)*75 275 75 22];
    Layout.ai_display(i).BackgroundColor = colors(i,:);
    Layout.ai_display(i).FontWeight = 'bold';
end

Layout.ot = uieditfield(fig);
Layout.ot.Position = [20 250 100 22];
Layout.ot.Editable = 'off';
Layout.ot.Value = 'Current:';
Layout.ot.FontWeight = 'bold';

for i = 1:Settings.N_input
    Layout.ov(i) = uieditfield(fig, "numeric", 'ValueDisplayFormat','%.4e');
    Layout.ov(i).Editable = 'off';
    Layout.ov(i).Value = 0;
    Layout.ov(i).Position = [150 + (i-1)*75 250 75 22];
end

Data = struct('Layout', Layout, 'Gate', Gate, 'Settings', Settings);
guidata(fig,Data);

drawnow

%% set parameters AI
Timetrace.process_delay = round(Settings.clockfrequency / Timetrace.scanrate);
Timetrace.time_per_point = (Timetrace.points_av / Timetrace.scanrate); % 1/sampling rate
Timetrace.sampling_rate = 1 / Timetrace.time_per_point;

% set ADCs
Set_Par(10, Data.Settings.input_resolution);

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
for i = 1:Data.Settings.N_output
    Data.Gate.startV = 0;
    Data.Gate.setV = 0;
    Data.Gate.targetV = 0;
    Data.Gate.ramp_rate = 1;
    Data = Apply_voltage(Data, i, hLines);
end

%% read AI
Start_Process(2);

while Process_Status(2)
    for i = 1:Data.Settings.N_input
        Data.Layout.ov(i).Value = Get_FPar(i);
        addpoints(hLines(i), toc, Data.Layout.ov(i).Value);
    end
    drawnow
end

%% Callback buttonPushed_AO
function buttonPushed(fig, tagvalue, hLines)

% get gui data
Data = guidata(fig);

% get AO index
Data.Layout.setV = zeros(Data.Settings.N_output, 1);
Data.Layout.rampV = zeros(Data.Settings.N_output, 1);
for i = 1:Data.Settings.N_output
    Data.Layout.setV(i) = Data.Layout.vf(i).Value;
    Data.Layout.rampV(i) = Data.Layout.rr_display(i).Value;
end

%index = find(Data.Layout.setV ~=  Data.Layout.currentV);
index = find(arrayfun(@(x) isequal(x.UserData, tagvalue), Data.Layout.sb_AO))

if ~isempty(index)
    % apply volage
    Data.Gate.setV = Data.Layout.vf(index).Value;
    Data.Gate.ramp_rate = Data.Layout.rr_display(index).Value;
   Data = Apply_voltage(Data, index, hLines);
    Data.Gate.startV = Data.Gate.setV;

    Data.Layout.currentV = Data.Layout.setV;

    % store gui data
    guidata(fig, Data);

    drawnow
end


end

function Data = Apply_voltage(Data, index, hLines)

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

currentTime = 0;
% read during execution
bin_size = (Settings.output_max-Settings.output_min) / (2^Settings.output_resolution);
while Process_Status(3)
    Voltage = Settings.output_min + (Get_Par(40) * bin_size) / 2^Settings.ADC_gain(1);
    Data.Layout.rf_display(index).Value = Voltage;

    if currentTime > 40
        clearpoints(hLines(index));
        currentTime = 0;
    end

    %currentTime = currentTime + Timetrace.time_per_point;
    drawnow
end

Data.Gate = Gate;

end