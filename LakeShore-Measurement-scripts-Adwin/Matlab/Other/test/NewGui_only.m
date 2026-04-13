%% GUI

fig = uifigure;
fig.Name = 'Setting Voltage';

rf = uieditfield(fig);
rf.Value = 'Current Voltage:';
rf.Editable = 'off';
rf.Position = [20 350 100 22];

sv = uieditfield(fig);
sv.Value = 'Set Voltage:';
sv.Editable = 'off';
sv.Position = [20 300 100 22];

ot = uieditfield(fig);
ot.Value = 'Current:';
ot.Editable = 'off';
ot.Position = [20 250 100 22];

in_1 = uieditfield(fig);
in_1.Value = 'Input 1:';
in_1.Editable = 'off';
in_1.Position = [150 390 50 22];

in_2 = uieditfield(fig);
in_2.Value = 'Input 2:';
in_2.Editable = 'off';
in_2.Position = [200 390 50 22];

in_3 = uieditfield(fig);
in_3.Value = 'Input 3:';
in_3.Editable = 'off';
in_3.Position = [250 390 50 22];

in_4 = uieditfield(fig);
in_4.Value = 'Input 4:';
in_4.Editable = 'off';
in_4.Position = [300 390 50 22];

in_5 = uieditfield(fig);
in_5.Value = 'Input 5:';
in_5.Editable = 'off';
in_5.Position = [350 390 50 22];

in_6 = uieditfield(fig);
in_6.Value = 'Input 6:';
in_6.Editable = 'off';
in_6.Position = [400 390 50 22];

in_7 = uieditfield(fig);
in_7.Value = 'Input 7:';
in_7.Editable = 'off';
in_7.Position = [450 390 50 22];

in_8 = uieditfield(fig);
in_8.Value = 'Input 8:';
in_8.Editable = 'off';
in_8.Position = [500 390 50 22];

in_9 = uieditfield(fig);
in_9.Value = 'Input 9:';
in_9.Editable = 'off';
in_9.Position = [550 390 50 22];

in_10 = uieditfield(fig);
in_10.Value = 'Input 10:';
in_10.Editable = 'off';
in_10.Position = [600 390 50 22];

in_11 = uieditfield(fig);
in_11.Value = 'Input 11:';
in_11.Editable = 'off';
in_11.Position = [650 390 50 22];

in_12 = uieditfield(fig);
in_12.Value = 'Input 12:';
in_12.Editable = 'off';
in_12.Position = [700 390 50 22];

in_13 = uieditfield(fig);
in_13.Value = 'Input 13:';
in_13.Editable = 'off';
in_13.Position = [750 390 50 22];

in_14 = uieditfield(fig);
in_14.Value = 'Input 14:';
in_14.Editable = 'off';
in_14.Position = [800 390 50 22];

in_15 = uieditfield(fig);
in_15.Value = 'Input 15:';
in_15.Editable = 'off';
in_15.Position = [850 390 50 22];

in_16 = uieditfield(fig);
in_16.Value = 'Input 16:';
in_16.Editable = 'off';
in_16.Position = [900 390 50 22];

rf1_display = uieditfield(fig, "numeric", 'ValueDisplayFormat','%.2f V' );
rf1_display.Value = 0;
rf1_display.Position = [150 350 50 22];
rf1_display.Editable = 'off';

rf2_display = uieditfield(fig, "numeric", 'ValueDisplayFormat','%.2f V' );
rf2_display.Value = 0;
rf2_display.Position = [200 350 50 22];
rf2_display.Editable = 'off';

rf3_display = uieditfield(fig, "numeric", 'ValueDisplayFormat','%.2f V' );
rf3_display.Value = 0;
rf3_display.Position = [250 350 50 22];
rf3_display.Editable = 'off';

rf4_display = uieditfield(fig, "numeric", 'ValueDisplayFormat','%.2f V' );
rf4_display.Value = 0;
rf4_display.Position = [300 350 50 22];
rf4_display.Editable = 'off';

rf5_display = uieditfield(fig, "numeric", 'ValueDisplayFormat','%.2f V' );
rf5_display.Value = 0;
rf5_display.Position = [350 350 50 22];
rf5_display.Editable = 'off';

rf6_display = uieditfield(fig, "numeric", 'ValueDisplayFormat','%.2f V' );
rf6_display.Value = 0;
rf6_display.Position = [400 350 50 22];
rf6_display.Editable = 'off';

rf7_display = uieditfield(fig, "numeric", 'ValueDisplayFormat','%.2f V' );
rf7_display.Value = 0;
rf7_display.Position = [450 350 50 22];
rf7_display.Editable = 'off';

rf8_display = uieditfield(fig, "numeric", 'ValueDisplayFormat','%.2f V' );
rf8_display.Value = 0;
rf8_display.Position = [500 350 50 22];
rf8_display.Editable = 'off';

rf9_display = uieditfield(fig, "numeric", 'ValueDisplayFormat','%.2f V' );
rf9_display.Value = 0;
rf9_display.Position = [550 350 50 22];
rf9_display.Editable = 'off';

rf10_display = uieditfield(fig, "numeric", 'ValueDisplayFormat','%.2f V' );
rf10_display.Value = 0;
rf10_display.Position = [600 350 50 22];
rf10_display.Editable = 'off';

rf11_display = uieditfield(fig, "numeric", 'ValueDisplayFormat','%.2f V' );
rf11_display.Value = 0;
rf11_display.Position = [650 350 50 22];
rf11_display.Editable = 'off';

rf12_display = uieditfield(fig, "numeric", 'ValueDisplayFormat','%.2f V' );
rf12_display.Value = 0;
rf12_display.Position = [700 350 50 22];
rf12_display.Editable = 'off';

rf13_display = uieditfield(fig, "numeric", 'ValueDisplayFormat','%.2f V' );
rf13_display.Value = 0;
rf13_display.Position = [750 350 50 22];
rf13_display.Editable = 'off';

rf14_display = uieditfield(fig, "numeric", 'ValueDisplayFormat','%.2f V' );
rf14_display.Value = 0;
rf14_display.Position = [800 350 50 22];
rf14_display.Editable = 'off';

rf15_display = uieditfield(fig, "numeric", 'ValueDisplayFormat','%.2f V' );
rf15_display.Value = 0;
rf15_display.Position = [850 350 50 22];
rf15_display.Editable = 'off';

rf16_display = uieditfield(fig, "numeric", 'ValueDisplayFormat','%.2f V' );
rf16_display.Value = 0;
rf16_display.Position = [900 350 50 22];
rf16_display.Editable = 'off';

sv1_display = uieditfield(fig, "numeric", 'ValueDisplayFormat','%.2f V');
sv1_display.Value = 0;
sv1_display.Position = [150 300 50 22];

sv2_display = uieditfield(fig, "numeric", 'ValueDisplayFormat','%.2f V');
sv2_display.Value = 0;
sv2_display.Position = [200 300 50 22];

sv3_display = uieditfield(fig, "numeric", 'ValueDisplayFormat','%.2f V');
sv3_display.Value = 0;
sv3_display.Position = [250 300 50 22];

sv4_display = uieditfield(fig, "numeric", 'ValueDisplayFormat','%.2f V');
sv4_display.Value = 0;
sv4_display.Position = [300 300 50 22];

sv5_display = uieditfield(fig, "numeric", 'ValueDisplayFormat','%.2f V');
sv5_display.Value = 0;
sv5_display.Position = [350 300 50 22];

sv6_display = uieditfield(fig, "numeric", 'ValueDisplayFormat','%.2f V');
sv6_display.Value = 0;
sv6_display.Position = [400 300 50 22];

sv7_display = uieditfield(fig, "numeric", 'ValueDisplayFormat','%.2f V');
sv7_display.Value = 0;
sv7_display.Position = [450 300 50 22];

sv8_display = uieditfield(fig, "numeric", 'ValueDisplayFormat','%.2f V');
sv8_display.Value = 0;
sv8_display.Position = [500 300 50 22];

sv9_display = uieditfield(fig, "numeric", 'ValueDisplayFormat','%.2f V');
sv9_display.Value = 0;
sv9_display.Position = [550 300 50 22];

sv10_display = uieditfield(fig, "numeric", 'ValueDisplayFormat','%.2f V');
sv10_display.Value = 0;
sv10_display.Position = [600 300 50 22];

sv11_display = uieditfield(fig, "numeric", 'ValueDisplayFormat','%.2f V');
sv11_display.Value = 0;
sv11_display.Position = [650 300 50 22];

sv12_display = uieditfield(fig, "numeric", 'ValueDisplayFormat','%.2f V');
sv12_display.Value = 0;
sv12_display.Position = [700 300 50 22];

sv13_display = uieditfield(fig, "numeric", 'ValueDisplayFormat','%.2f V');
sv13_display.Value = 0;
sv13_display.Position = [750 300 50 22];

sv14_display = uieditfield(fig, "numeric", 'ValueDisplayFormat','%.2f V');
sv14_display.Value = 0;
sv14_display.Position = [800 300 50 22];

sv15_display = uieditfield(fig, "numeric", 'ValueDisplayFormat','%.2f V');
sv15_display.Value = 0;
sv15_display.Position = [850 300 50 22];

sv16_display = uieditfield(fig, "numeric", 'ValueDisplayFormat','%.2f V');
sv16_display.Value = 0;
sv16_display.Position = [900 300 50 22];

ot1_display = uieditfield(fig, "numeric", 'ValueDisplayFormat','%.2f');
ot1_display.Editable = 'off';
ot1_display.Value = 0;
ot1_display.Position = [150 250 50 22];

ot2_display = uieditfield(fig, "numeric", 'ValueDisplayFormat','%.2f');
ot2_display.Editable = 'off';
ot2_display.Value = 0;
ot2_display.Position = [200 250 50 22];

ot3_display = uieditfield(fig, "numeric", 'ValueDisplayFormat','%.2f');
ot3_display.Editable = 'off';
ot3_display.Value = 0;
ot3_display.Position = [250 250 50 22];

ot4_display = uieditfield(fig, "numeric", 'ValueDisplayFormat','%.2f');
ot4_display.Editable = 'off';
ot4_display.Value = 0;
ot4_display.Position = [300 250 50 22];

ot5_display = uieditfield(fig, "numeric", 'ValueDisplayFormat','%.2f');
ot5_display.Editable = 'off';
ot5_display.Value = 0;
ot5_display.Position = [350 250 50 22];

ot6_display = uieditfield(fig, "numeric", 'ValueDisplayFormat','%.2f');
ot6_display.Editable = 'off';
ot6_display.Value = 0;
ot6_display.Position = [400 250 50 22];

ot7_display = uieditfield(fig, "numeric", 'ValueDisplayFormat','%.2f');
ot7_display.Editable = 'off';
ot7_display.Value = 0;
ot7_display.Position = [450 250 50 22];

ot8_display = uieditfield(fig, "numeric", 'ValueDisplayFormat','%.2f');
ot8_display.Editable = 'off';
ot8_display.Value = 0;
ot8_display.Position = [500 250 50 22];

ot9_display = uieditfield(fig, "numeric", 'ValueDisplayFormat','%.2f');
ot9_display.Editable = 'off';
ot9_display.Value = 0;
ot9_display.Position = [550 250 50 22];

ot10_display = uieditfield(fig, "numeric", 'ValueDisplayFormat','%.2f');
ot10_display.Editable = 'off';
ot10_display.Value = 0;
ot10_display.Position = [600 250 50 22];

ot11_display = uieditfield(fig, "numeric", 'ValueDisplayFormat','%.2f');
ot11_display.Editable = 'off';
ot11_display.Value = 0;
ot11_display.Position = [650 250 50 22];

ot12_display = uieditfield(fig, "numeric", 'ValueDisplayFormat','%.2f');
ot12_display.Editable = 'off';
ot12_display.Value = 0;
ot12_display.Position = [700 250 50 22];

ot13_display = uieditfield(fig, "numeric", 'ValueDisplayFormat','%.2f');
ot13_display.Editable = 'off';
ot13_display.Value = 0;
ot13_display.Position = [750 250 50 22];

ot14_display = uieditfield(fig, "numeric", 'ValueDisplayFormat','%.2f');
ot14_display.Editable = 'off';
ot14_display.Value = 0;
ot14_display.Position = [800 250 50 22];

ot15_display = uieditfield(fig, "numeric", 'ValueDisplayFormat','%.2f');
ot15_display.Editable = 'off';
ot15_display.Value = 0;
ot15_display.Position = [850 250 50 22];

ot16_display = uieditfield(fig, "numeric", 'ValueDisplayFormat','%.2f');
ot16_display.Editable = 'off';
ot16_display.Value = 0;
ot16_display.Position = [900 250 50 22];

sb_1 = uibutton(fig,'push',...
    "Text","Start",...
    "Position", [150 200 50 22],...
    "ButtonPushedFcn",@(src, event) buttonPushed1(sv1_display));

sb_2 = uibutton(fig,'push',...
    "Text","Start",...
    "Position", [200 200 50 22],...
    "ButtonPushedFcn",@(src, event) buttonPushed2(sv2_display));

sb_3 = uibutton(fig,'push',...
    "Text","Start",...
    "Position", [250 200 50 22],...
    "ButtonPushedFcn",@(src, event) buttonPushed3(sv3_display));

sb_4 = uibutton(fig,'push',...
    "Text","Start",...
    "Position", [300 200 50 22],...
    "ButtonPushedFcn",@(src, event) buttonPushed4(sv4_display));

sb_5 = uibutton(fig,'push',...
    "Text","Start",...
    "Position", [350 200 50 22],...
    "ButtonPushedFcn",@(src, event) buttonPushed5(sv5_display));

sb_6 = uibutton(fig,'push',...
    "Text","Start",...
    "Position", [400 200 50 22],...
    "ButtonPushedFcn",@(src, event) buttonPushed6(sv6_display));

sb_7 = uibutton(fig,'push',...
    "Text","Start",...
    "Position", [450 200 50 22],...
    "ButtonPushedFcn",@(src, event) buttonPushed7(sv7_display));

sb_8 = uibutton(fig,'push',...
    "Text","Start",...
    "Position", [500 200 50 22],...
    "ButtonPushedFcn",@(src, event) buttonPushed8(sv8_display));

sb_9 = uibutton(fig,'push',...
    "Text","Start",...
    "Position", [550 200 50 22],...
    "ButtonPushedFcn",@(src, event) buttonPushed9(sv9_display));

sb_10 = uibutton(fig,'push',...
    "Text","Start",...
    "Position", [600 200 50 22],...
    "ButtonPushedFcn",@(src, event) buttonPushed10(sv10_display));

sb_11 = uibutton(fig,'push',...
    "Text","Start",...
    "Position", [650 200 50 22],...
    "ButtonPushedFcn",@(src, event) buttonPushed11(sv11_display));

sb_12 = uibutton(fig,'push',...
    "Text","Start",...
    "Position", [700 200 50 22],...
    "ButtonPushedFcn",@(src, event) buttonPushed12(sv12_display));

sb_13 = uibutton(fig,'push',...
    "Text","Start",...
    "Position", [750 200 50 22],...
    "ButtonPushedFcn",@(src, event) buttonPushed13(sv13_display));

sb_14 = uibutton(fig,'push',...
    "Text","Start",...
    "Position", [800 200 50 22],...
    "ButtonPushedFcn",@(src, event) buttonPushed14(sv14_display));

sb_15 = uibutton(fig,'push',...
    "Text","Start",...
    "Position", [850 200 50 22],...
    "ButtonPushedFcn",@(src, event) buttonPushed15(sv15_display));

sb_16 = uibutton(fig,'push',...
    "Text","Start",...
    "Position", [900 200 50 22],...
    "ButtonPushedFcn",@(src, event) buttonPushed16(sv16_display));

global data;
data = struct('targetV', 0);

%% Callback data

function updateData1(sv1_display, data)
    global data
    data.targetV(1) = sv1_display.Value;
    disp(['New targetV: ' num2str(data.targetV)]);
end

function buttonPushed1(sv1_display)
    global data
    updateData1(sv1_display, data);
    %disp('Button Pushed');
end

function updateData2(sv2_display, data)
    global data
    data.targetV(2) = sv2_display.Value;
    disp(['New targetV: ' num2str(data.targetV)]);
end

function buttonPushed2(sv2_display)
    global data
    updateData2(sv2_display, data);
    %disp('Button Pushed');
end

function updateData3(sv3_display, data)
    global data
    data.targetV(3) = sv3_display.Value;
    disp(['New targetV: ' num2str(data.targetV)]);
end

function buttonPushed3(sv3_display)
    global data
    updateData3(sv3_display, data);
    %disp('Button Pushed');
end

function updateData4(sv4_display, data)
    global data
    data.targetV(4) = sv4_display.Value;
    disp(['New targetV: ' num2str(data.targetV)]);
end

function buttonPushed4(sv4_display)
    global data
    updateData4(sv4_display, data);
    %disp('Button Pushed');
end

function updateData5(sv5_display, data)
    global data
    data.targetV(5) = sv5_display.Value;
    disp(['New targetV: ' num2str(data.targetV)]);
end

function buttonPushed5(sv5_display)
    global data
    updateData5(sv5_display, data);
    %disp('Button Pushed');
end

function updateData6(sv6_display, data)
    global data
    data.targetV(6) = sv6_display.Value;
    disp(['New targetV: ' num2str(data.targetV)]);
end

function buttonPushed6(sv6_display)
    global data
    updateData6(sv6_display, data);
    %disp('Button Pushed');
end

function updateData7(sv7_display, data)
    global data
    data.targetV(7) = sv7_display.Value;
    disp(['New targetV: ' num2str(data.targetV)]);
end

function buttonPushed7(sv7_display)
    global data
    updateData7(sv7_display, data);
    %disp('Button Pushed');
end

function updateData8(sv8_display, data)
    global data
    data.targetV(8) = sv8_display.Value;
    disp(['New targetV: ' num2str(data.targetV)]);
end

function buttonPushed8(sv8_display)
    global data
    updateData8(sv8_display, data);
    %disp('Button Pushed');
end

function updateData9(sv9_display, data)
    global data
    data.targetV(9) = sv9_display.Value;
    disp(['New targetV: ' num2str(data.targetV)]);
end

function buttonPushed9(sv9_display)
    global data
    updateData9(sv9_display, data);
    %disp('Button Pushed');
end

function updateData10(sv10_display, data)
    global data
    data.targetV(10) = sv10_display.Value;
    disp(['New targetV: ' num2str(data.targetV)]);
end

function buttonPushed10(sv10_display)
    global data
    updateData10(sv10_display, data);
    %disp('Button Pushed');
end

function updateData11(sv11_display, data)
    global data
    data.targetV(11) = sv11_display.Value;
    disp(['New targetV: ' num2str(data.targetV)]);
end

function buttonPushed11(sv11_display)
    global data
    updateData11(sv11_display, data);
    %disp('Button Pushed');
end

function updateData12(sv12_display, data)
    global data
    data.targetV(12) = sv12_display.Value;
    disp(['New targetV: ' num2str(data.targetV)]);
end

function buttonPushed12(sv12_display)
    global data
    updateData12(sv12_display, data);
    %disp('Button Pushed');
end

function updateData13(sv13_display, data)
    global data
    data.targetV(13) = sv13_display.Value;
    disp(['New targetV: ' num2str(data.targetV)]);
end

function buttonPushed13(sv13_display)
    global data
    updateData13(sv13_display, data);
    %disp('Button Pushed');
end

function updateData14(sv14_display, data)
    global data
    data.targetV(14) = sv14_display.Value;
    disp(['New targetV: ' num2str(data.targetV)]);
end

function buttonPushed14(sv14_display)
    global data
    updateData14(sv14_display, data);
    %disp('Button Pushed');
end

function updateData15(sv15_display, data)
    global data
    data.targetV(15) = sv15_display.Value;
    disp(['New targetV: ' num2str(data.targetV)]);
end

function buttonPushed15(sv15_display)
    global data
    updateData15(sv15_display, data);
    %disp('Button Pushed');
end

function updateData16(sv16_display, data)
    global data
    data.targetV(16) = sv16_display.Value;
    disp(['New targetV: ' num2str(data.targetV)]);
end

function buttonPushed16(sv16_display)
    global data
    updateData16(sv16_display, data);
    %disp('Button Pushed');
end
