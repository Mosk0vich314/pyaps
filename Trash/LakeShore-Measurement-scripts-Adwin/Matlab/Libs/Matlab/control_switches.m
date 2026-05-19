function Settings = control_switches(Settings, bit_to_set, bit_value)
Clock = [];
latch = [];
data = [];
disable = [];
switch_frequency = 500;

for i = 1:Settings.N_coils
    if i == 2 * bit_to_set - 1 + bit_value
        Set_Par(47, 0); Clock = [Clock 0]; % clock
        Set_Par(48, 1); latch = [latch 1];% latch
        Set_Par(49, 1); data = [data 1];% data
        Set_Par(50, 1); disable = [disable 1];% disable
    else
        Set_Par(47, 0); Clock = [Clock 0]; % clock
        Set_Par(48, 1); latch = [latch 1];% latch
        Set_Par(49, 0); data = [data 0];% data
        Set_Par(50, 1); disable = [disable 1];% disable
    end
    pause(0.0001)
    
    if i == 2 * bit_to_set - 1 + bit_value
        Set_Par(47, 1); Clock = [Clock 1]; % clock
        Set_Par(48, 1); latch = [latch 1];% latch
        Set_Par(49, 1); data = [data 1];% data
        Set_Par(50, 1); disable = [disable 1];% disable
    else
        Set_Par(47, 1); Clock = [Clock 1]; % clock
        Set_Par(48, 1); latch = [latch 1];% latch
        Set_Par(49, 0); data = [data 0];% data
        Set_Par(50, 1); disable = [disable 1];% disable
    end
    pause(1/switch_frequency)
    
end

%%
% plot(vertcat(Clock, latch , data, disable)');

%%
Set_Par(47, 0);
Set_Par(48, 1);
Set_Par(49, 0);
Set_Par(50, 0);
pause(0.01) %(0.02)
Set_Par(47, 0);
Set_Par(48, 1);
Set_Par(49, 0);
Set_Par(50, 1);
pause(0.01) %(0.02)
