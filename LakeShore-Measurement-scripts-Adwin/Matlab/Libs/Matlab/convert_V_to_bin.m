function [bins, voltage_new]  =  convert_V_to_bin(V, V_min, V_max, resolution)

    % converts ADC/DAC voltage to bin number, given the voltage range and the resolution (in bits)
    voltage = linspace(V_min, V_max, 2^resolution);
    bins = zeros(size(V));
    voltage_new = zeros(size(V));
    for i=1:length(V)
        idx = find(min(abs(V(i)-voltage))==abs(V(i)-voltage));
        bins(i) = idx(1);
        voltage_new(i) = voltage(idx(1));
    end

return
