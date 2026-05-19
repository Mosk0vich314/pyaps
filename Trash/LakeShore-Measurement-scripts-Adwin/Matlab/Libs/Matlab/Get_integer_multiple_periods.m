function runtime = Get_integer_multiple_periods(freq1, freq2)

if round(freq1) == freq1 && round(freq2) == freq2
    runtime = 1/ gcd(freq1, freq2);
else
    accuracy = 3; % digits for timeperiod calculation
    runtime = 1 * round(1/freq1, accuracy)*10^accuracy * round(1/freq2, accuracy);
end
