function ramp_lockin(Lockin, amplitude_actualV, setV, ramp_rate, channel)

arguments
    Lockin
    amplitude_actualV
    setV
    ramp_rate
    channel = 1
end

dV_tot = abs(setV - amplitude_actualV);
dt_tot = dV_tot / ramp_rate;

N_points = ceil(dt_tot * 5); % max 5 point per second
N_points = max(N_points, 1);

dV = dV_tot / N_points;      % 1 mV
dt = dV / ramp_rate;

if amplitude_actualV < setV
    amps = amplitude_actualV:dV:setV;
else
    amps = amplitude_actualV:-dV:setV;
end

for i = 1:length(amps)
    Lockin.dev.set_amplitude(amps(i), channel);
    pause(dt)
end

Lockin.dev.set_amplitude(setV, channel)
