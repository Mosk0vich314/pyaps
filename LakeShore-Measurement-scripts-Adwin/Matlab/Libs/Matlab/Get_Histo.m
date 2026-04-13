function Histo = Get_Histo(Settings, Histo)

pause(0.1);

run = true;
while run
    run = Process_Status(Histo.process_number);
    pause(0.01);
end

%% get current data breaking
Histo.Breaking_length = Get_Par(31)- 1;
Histo.current_breaking = zeros(Histo.Breaking_length, 4);
array = 2:5;
for i = 1:Settings.N_ADC
    if ~strcmp(Settings.ADC{i},'off')
        Histo.current_breaking(:,i) = GetData_Double(array(i), 1, Histo.Breaking_length);
    end
end

Histo.Time_breaking = (0:Histo.Breaking_length - 1) * Histo.time_per_point;

%% get current data making
Histo.Making_length = Get_Par(32)- 1;
Histo.current_making = zeros(Histo.Making_length, 4);
array = 7:10;
for i = 1:Settings.N_ADC
    if ~strcmp(Settings.ADC{i},'off')
        Histo.current_making(:,i) = GetData_Double(array(i), 1, Histo.Making_length);
    end
end

Histo.Time_making = (0:Histo.Making_length - 1) * Histo.time_per_point;

