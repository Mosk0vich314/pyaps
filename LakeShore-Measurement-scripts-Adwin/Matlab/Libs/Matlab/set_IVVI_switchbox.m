function resistance = set_IVVI_switchbox(Switchbox, index)

counter = 1;
done = 0;
while counter < 20 && done == 0
    try
        [~, resistance, ~] = Switchbox.device.set_resistance_Ohm(Switchbox.resistance_values(index));

        if Switchbox.resistance_values(index) == resistance
            done = 1;
        end
    catch
        Switchbox = rmfield(Switchbox,'device');
        Switchbox.device = IVVI_USB_switch_box(Switchbox.address);
        counter = counter + 1;
    end
end

return

