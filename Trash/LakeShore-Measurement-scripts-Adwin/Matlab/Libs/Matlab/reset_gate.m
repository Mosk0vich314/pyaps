function reset_gate(Settings, Gate)

if startsWith(Gate.process,'Sweep_AO')
    actual_gate_bin = Get_Par(24);
    Gate.ramp_rate = 1;
    Gate.process_number = 3;
end
if startsWith(Gate.process,'Fixed_AO')
    actual_gate_bin = Get_Par(40);
end

if actual_gate_bin == 0
    disp('No gate voltage is set...')
else
    
    %% ramp gate to zero
    Gate.startV = convert_bin_to_V_float(actual_gate_bin, Settings.output_min, Settings.output_max, Settings.output_resolution) * Gate.V_per_V ;
    Gate.setV = 0;
    
    switch Settings.ADwin
        case 'GoldII'
            Load_Process(sprintf('%s/%s/%s_%s.TB%1.0f', Settings.path,  Settings.ADwin, 'Fixed_AO', Settings.ADwin, 3));
        case 'ProII'
            Load_Process(sprintf('%s/%s/%s_%s.TC%1.0f', Settings.path,  Settings.ADwin, 'Fixed_AO', Settings.ADwin, 3));
    end
    
    Apply_fixed_voltage(Settings, Gate);
    
end
return
