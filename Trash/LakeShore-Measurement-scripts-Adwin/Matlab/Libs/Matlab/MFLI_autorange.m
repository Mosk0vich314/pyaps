function MFLI_autorange(Lockin, N_devices)

for k = 1:N_devices
    Lockin.(Lockin.device_names{k}).dev.autorange;
end