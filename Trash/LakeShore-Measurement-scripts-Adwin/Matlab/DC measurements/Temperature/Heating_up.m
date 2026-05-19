%% clear
clc
close all
clear
instrreset

%% Settings
Directory = 'E:\Samples\001_WARMING_UPS\';
Device = make_filename;
time_monitor = 1;           % hours
sensors = 1:2;
Labels = {'Cold finger','Sample'};

Sensor_pid = 1;
Sensor_radshield = 2;
T_set = 300;
T_threshold = 20;
heaters = [1 2];

%% Connexion
Settings.T_controller = Temperature_controller_Lakeshore336('GPIB0::8::INSTR');

%% warning for lifting needles
mydlg = warndlg('Lift probe arms before cooling down!', 'Warning');
waitfor(mydlg);

%% initialize
heater_low = 1;
heater_high = 3;

fig = figure; 
counter = 1;
T_interval = 1;
N_sensors = length(sensors);
N_heaters = length(heaters);
T = zeros(1, N_sensors);

time = zeros(1);
tic;
run = 1;

%% start heaters for low power
Settings.T_controller.set_T_setpoint(Sensor_pid, T_set);
Settings.T_controller.set_T_setpoint(Sensor_radshield, T_set);
for i=1:N_heaters
    Settings.T_controller.set_heater_range(heaters(i), heater_low);
end

%% Monitor temperature
while run
    cla;hold on
    for i=1:N_sensors
        T(counter, i) = Settings.T_controller.get_temp(sensors(i));
    end
    
    % get time
    t = toc;
    time(counter) = t;
    if t > time_monitor * 3600     
       run = 0; 
    end

    % make plot
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
    
    % change heater range if needed
    if T(counter, sensors(Sensor_pid)) > T_threshold
        for i=1:N_heaters
            Settings.T_controller.set_heater_range(heaters(i), heater_high);
        end
    end
    
    pause(T_interval)
    drawnow
    counter = counter + 1;

end
fprintf('done\n')

%% switch off heaters
for i=1:N_heaters
    Settings.T_controller.set_heater_range(heaters(i), 0);
end

%% save data
saveas(fig,sprintf('%s%s.png' , Directory, Device))
save(sprintf('%s%s.mat' , Directory, Device), 'time','sensors', 'Labels', 'T')