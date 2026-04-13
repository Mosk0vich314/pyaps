function Structure = Generate_voltage_array(Settings, Structure)

bin_size = (Settings.output_max - Settings.output_min) / 2^Settings.output_resolution;
dV_bin = ceil( (Structure.maxV - Structure.minV) / Structure.points  / bin_size / Structure.V_per_V );

if strcmpi(Structure.sweep_dir,'up')
    Structure.voltage = Structure.minV / Structure.V_per_V: dV_bin * bin_size :Structure.maxV / Structure.V_per_V + dV_bin * bin_size;
else
    Structure.voltage = Structure.maxV / Structure.V_per_V: -dV_bin * bin_size :Structure.minV / Structure.V_per_V - dV_bin * bin_size;
end

Structure.voltage = Structure.voltage * Structure.V_per_V;
Structure.dV = abs(Structure.voltage(2) - Structure.voltage(1)) ;


return

