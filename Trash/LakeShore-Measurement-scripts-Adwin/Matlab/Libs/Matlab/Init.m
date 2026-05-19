function Settings = Init(varargin)

Settings = varargin{1};
Settings.plot_position = [0.02 0.06 0.96 0.85];

%% create directory
if ~exist(Settings.save_dir,'dir')
    mkdir(Settings.save_dir);
end

%% add paths
idx = regexp(pwd,'(Matlab\\)');
tmp = pwd;
addpath(genpath([tmp(1:idx-1) 'Matlab\Libs\']));
Settings.path = [tmp(1:idx-1) 'Matlab\Libs\ADwin_script'];
addpath(genpath(Settings.path));

%% Set plot labels
if isfield(Settings,'type')
    if strcmp(Settings.type,'IV')
        if Settings.res4p == 1
            Settings.Labels.Y_1D = 'Conductance (A/V)';
        else
            Settings.Labels.Y_1D = 'Current (A)';
        end
        Settings.Labels.X_1D = 'Bias voltage (V)';
        Settings.Labels.X_2D = '# IV';
        Settings.Labels.Y_2D = 'Bias voltage (V)';
        Settings.fixed_voltage = 'Gate';
    end
    if strcmp(Settings.type,'Stability')
        if Settings.res4p == 1
            Settings.Labels.Y_1D = 'Conductance (A)';
        else
            Settings.Labels.Y_1D = 'Current (A)';
        end
        Settings.Labels.X_1D = 'Bias voltage (V)';
        Settings.Labels.X_2D = 'Gate voltage (V)';
        Settings.Labels.Y_2D = 'Bias voltage (V)';
        Settings.fixed_voltage = 'Gate';
    end
    if strcmp(Settings.type,'Gatesweep')
        if Settings.res4p == 1
            Settings.Labels.Y_1D = 'Conductance (A/V)';
        else
            Settings.Labels.Y_1D = 'Current (A)';
        end
        Settings.Labels.X_1D = 'Gate voltage (V)';
        Settings.Labels.X_2D = 'Bias voltage (V)';
        Settings.Labels.Y_2D = 'Gate voltage (V)';
        Settings.fixed_voltage = 'Voltage';
    end
    if strcmp(Settings.type,'VI')
        Settings.Labels.Y_1D = 'Voltage (V)';
        Settings.Labels.X_1D = 'Current (A)';
        Settings.Labels.X_2D = '# VI';
        Settings.Labels.Y_2D = 'Voltage (V)';
        Settings.fixed_voltage = 'Gate';
    end
    if strcmp(Settings.type,'Gatesweep I bias')
        Settings.Labels.X_1D = 'Gate voltage (V)';
        Settings.Labels.Y_1D = 'Resistance (Ohm)';
        Settings.Labels.X_2D = 'Bias voltage (V)';
        Settings.Labels.Y_2D = 'Gate voltage (V)';
        Settings.fixed_voltage = 'Current';
    end
    if strcmp(Settings.type,'Stability Ibias')
        Settings.Labels.X_1D = 'Bias current (A)';
        Settings.Labels.Y_1D = 'Voltage (V)';
        Settings.Labels.X_2D = 'Gate voltage (V)';
        Settings.Labels.Y_2D = 'Bias current (A)';
        Settings.fixed_voltage = 'Gate';
    end
    if strcmp(Settings.type,'DualGatesweep')
        Settings.Labels.X_1D = 'Gate 1 voltage (V)';
        Settings.Labels.Y_1D = 'Current (A)';
        Settings.Labels.X_2D = 'Gate 2 voltage (V)';
        Settings.Labels.Y_2D = 'Gate 1 voltage (V)';
        Settings.fixed_voltage = 'Bias';
    end
    if strcmp(Settings.type,'Thermopower')
        Settings.fixed_voltage = 'Gate';
    end
    if strcmp(Settings.type,'Thermocurrent')
        Settings.Labels.X_1D = 'Gate voltage (V)';
        Settings.Labels.Y_1D = 'Thermocurrent (A)';
        Settings.Labels.X_2D = 'Heater current (A)';
        Settings.Labels.Y_2D = 'Gate voltage (V)';
        Settings.fixed_voltage = 'I_source';
    end
    if strcmp(Settings.type,'Thermometer_current')
        Settings.fixed_voltage = 'I_source';
    end
    if strcmp(Settings.type,'EB')
        Settings.Labels.X_1D = 'Samples';
        Settings.Labels.Y_1D = 'Resistance (Ohm)';
        Settings.Labels.X_2D = 'Bias voltage (V)';
        Settings.Labels.Y_2D = 'Gate voltage (V)';
        Settings.fixed_voltage = 'Bias';
    end
    if strcmp(Settings.type,'TEP_Timetraces')
        Settings.Labels.X_1D = 'Bias voltage (V)';
        Settings.Labels.Y_1D = 'Current (A)';
        Settings.Labels.X_2D = 'Gate voltage (V)';
        Settings.Labels.Y_2D = 'Bias voltage (V)';
        Settings.fixed_voltage = 'Gate';
    end
    if strcmp(Settings.type,'TEP_Timetraces_IV')
        Settings.Labels.X_1D = 'Bias voltage (V)';
        Settings.Labels.Y_1D = 'Current (A)';
        Settings.Labels.X_2D = 'Gate voltage (V)';
        Settings.Labels.Y_2D = 'Bias voltage (V)';
        Settings.fixed_voltage = 'IV';
    end
    if strcmp(Settings.type,'Stability4p_Timetraces')
        Settings.Labels.X_1D = 'Bias voltage (V)';
        Settings.Labels.Y_1D = 'Current (A)';
        Settings.Labels.X_2D = 'Gate voltage (V)';
        Settings.Labels.Y_2D = 'Bias voltage (V)';
        Settings.fixed_voltage = 'Gate';
    end
    if strcmp(Settings.type,'Histogram')
        Settings.Labels.X_1D = 'Actuation voltage (V)';
        Settings.Labels.Y_1D = 'Conductance (G_0)';
    end
end

%% set warning off
warning off

%% get sample temperature
Settings = Init_T_controller(Settings);

%% create constants
Settings.G0 = 7.74809173e-5;                                          % conductance quantum

%% create timestamp
Settings.timestamp_start = datetime;

%% fix save_dir path
Settings.save_dir = regexprep(Settings.save_dir,'\','/');

%% create filename
Settings.filename = make_filename;

return
