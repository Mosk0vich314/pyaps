function timeMeasurementHours = calculate_measurement_time_AC(Settings, Lockin, Gate)

timeMeasurement = 0;
for j = 1:length(Settings.Temperatures)
    for i = 1:length(Lockin.dev1.frequency_array)
        if Lockin.dev1.frequency_array(i) < Lockin.dev2.frequency
            TC = 10/ (Lockin.dev1.frequency_array(i)*2);
        else
            TC = 10/ (Lockin.dev2.frequency);
        end
        waitTimePoint = TC * 6.6;
        runtimePoint = 0.2;
        timeMeasurement = Gate.points* (waitTimePoint + runtimePoint) + timeMeasurement;
    end
end
timeMeasurementHours = (timeMeasurement / 3600) * numel(Settings.Heaters);