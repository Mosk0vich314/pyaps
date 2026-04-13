% Load the data
% Assume your data is in two arrays: bias_voltage and current
% Replace 'your_bias_voltage_data' and 'your_current_data' with your actual data variables
bias_voltage = IV.bias;
current = IV.current{1, 1};

% Plot the I-V curve
figure;
plot(bias_voltage, current, 'b-');
xlabel('Bias voltage (V)');
ylabel('Current (A)');
title('I-V Curve of Semiconducting Graphene Nanoribbon');
grid on;
hold on;

% Calculate the derivative of the current with respect to bias voltage
dI_dV = diff(current) ./ diff(bias_voltage);

% Filter out infinite and NaN values in the derivative
valid_indices = isfinite(dI_dV);
filtered_dI_dV = dI_dV(valid_indices);
filtered_bias_voltage = bias_voltage(valid_indices);

% Smooth the derivative to reduce noise
avg_dI_dV = movmean(filtered_dI_dV, 5);

% Identify the region where the derivative is approximately constant
threshold = std(avg_dI_dV) * 0.1;
linear_region = abs(avg_dI_dV - mean(avg_dI_dV)) < threshold;

% Expand the linear region mask to match the size of the original data arrays
% linear_region = [linear_region, false] | [false, linear_region];
% linear_region = linear_region & isfinite(dI_dV);

linear_bias_voltage = bias_voltage(linear_region);
linear_current = current(linear_region);

% Perform linear regression on the linear region
p = polyfit(linear_bias_voltage, linear_current, 1);
slope = p(1);
intercept = p(2);

% Calculate the resistance
resistance = 1 / slope;

% Plot the linear fit
fit_line = slope * linear_bias_voltage + intercept;
plot(linear_bias_voltage, fit_line, 'r--', 'LineWidth', 2);
legend('I-V Curve', 'Linear Fit');

% Display the calculated resistance
disp(['Calculated Resistance: ', num2str(resistance), ' Ohms']);

% Save the plot
saveas(gcf, 'IV_curve_with_fit.png');
