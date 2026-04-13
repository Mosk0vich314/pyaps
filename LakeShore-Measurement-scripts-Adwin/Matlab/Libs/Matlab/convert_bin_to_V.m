function V =  convert_bin_to_V(bins, V_range, resolution)
% converts ADC/DAC bins to voltage, given the voltage range and the resolution (in bits)
voltage = linspace(-V_range ,V_range, 2^resolution);
V = voltage(bins);
return
