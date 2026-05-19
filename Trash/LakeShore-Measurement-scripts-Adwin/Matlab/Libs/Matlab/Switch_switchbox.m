function Switch_switchbox(Settings, Switches)

switches = 1:Settings.N_switches;
states =   zeros(1,Settings.N_switches);

Set_Par(43, Settings.switchbox.clock_bit);
Set_Par(44, Settings.switchbox.latch_bit);
Set_Par(45, Settings.switchbox.data_bit);
Set_Par(46, Settings.switchbox.disable_bit);

Set_Par(47, 0); % clock
Set_Par(48, 1); % latch
Set_Par(49, 0); % data
Set_Par(50, 1); % disable

%% run
Set_Processdelay(Switches.process_number, 1000);
Start_Process(Switches.process_number);
for i = 1:Settings.N_switches
    control_switches(Settings, switches(i), states(i));
end
Stop_Process(5);