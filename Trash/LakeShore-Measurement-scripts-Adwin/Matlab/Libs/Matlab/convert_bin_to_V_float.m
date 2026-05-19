function V =  convert_bin_to_V_float(bins, V_min, V_max,  resolution)
% converts ADC/DAC bins to voltage, given the voltage range and the resolution (in bits)
    voltage = linspace(V_min, V_max, 2^resolution);
    V = interp1(1:2^resolution,voltage,bins);
return
