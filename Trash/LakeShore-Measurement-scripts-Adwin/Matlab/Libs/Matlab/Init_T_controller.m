function Settings = Init_T_controller(Settings)

warning off
instrreset
warning on

%% get sample temperature
try
    switch Settings.get_sample_T

        case ''
            Settings.T_sample = 0;
        case 'Lakeshore336'
            Settings.T_controller_address = 'COM5';
            Settings.T_controller = Temperature_controller_Lakeshore336(Settings.T_controller_address);
            Settings.T_sample = Settings.T_controller.get_temp(1);
        case 'Lakeshore325'
            Settings.T_controller_address = 'GPIB0::1::INSTR';
            Settings.T_controller = Temperature_controller_Lakeshore325(Settings.T_controller_address);
            Settings.Settings.T_sample = Settings.T_controller.get_temp(1);
        case 'Oxford_ITC'
            Settings.T_controller_address = 'COM12';
            Settings.T_controller = Temperature_controller_Oxford_ITC(Settings.T_controller_address);
            Settings.T_sample = Settings.T_controller.get_temp(1);
    end

catch
    errordlg('Could not connect to temperature controller')
end