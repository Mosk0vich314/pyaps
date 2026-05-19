 %% clear
clc
close all
clear
instrreset

%% Settings
Directory = 'E:\Samples\HWH\ARS_temp_cal\';
Device = '8K';%filename
time_monitor = 5;           % hours
T_interval = 1;

sensors = [1 2 3 4]; %[1 2 3 4]
Labels = {'Sample','Radshield','Arm','CCRSecond'};
Settings.get_sample_T = 'Lakeshore336'; % {'', 'Lakeshore336', 'Lakeshore325', 'Oxford_ITC'}


%% Connexion
try
switch Settings.get_sample_T
    case 'Lakeshore336'
        Settings.T_controller = Temperature_controller_Lakeshore336('COM4');
        Settings.T_sample = Settings.T_controller.get_temp(1);        
    case 'Lakeshore325'
        Settings.T_controller = Temperature_controller_Lakeshore325('GPIB0::1::INSTR');
        Settings.Settings.T_sample = Settings.T_controller.get_temp(1);
    case 'Oxford_ITC'
        Settings.T_controller = Temperature_controller_Oxford_ITC('COM8');
        Settings.T_sample = Settings.T_controller.get_temp(1);
end

catch
    errordlg('Could not connect to temperature controller')
end

%% warning for lifting needles
mydlg = warndlg('Lift probe arms before cooling down!', 'Warning');
waitfor(mydlg);

%% initialize
fig = figure; 
counter = 1;  
N_sensors = length(sensors);

T = zeros(1, N_sensors);

time = zeros(1);
tic;
run = 1;

%% Monitor temperature
while run
    cla;hold on
    for i=1:N_sensors
        T(counter, i) = Settings.T_controller.get_temp(sensors(i));
    end
    
    t = toc;
    time(counter) = t;
    if t > time_monitor * 3600     
       run = 0; 
    end

    for i=1:N_sensors
        plot(time, T(:,i),'.-','Markersize',24,'linewidth',2 )
    end
    
    xlabel('Time (s)')
    ylabel('Temperature (K)')
    leg = legend(Labels);
    set(leg,'box','off','location','best')
    set(gca,'box','on','Fontsize',20)
    set(gcf,'color','white')
    hold off
    
    pause(T_interval)
    drawnow
    counter = counter + 1;

end
fprintf('done\n')

%% save data
if ~exist(Directory,'dir')
    mkdir(Directory)
end
savefig(strcat(Directory,Device))
%saveas(fig,sprintf('%s%s.png' , Directory, Device))
save(sprintf('%s%s.mat' , Directory, Device), 'time','sensors', 'Labels', 'T')