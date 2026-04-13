% MATLAB script to generate a heatmap from resistance data in an Excel file
% with Excel-like axis labeling

% Clear all variables and close figures
clear all;
close all;
clc;

% Specify the file name (update this to your file name)
filename = 'Pd12nm_1-Resistance - 04V.xlsx';  % Replace with the path to your Excel file

% Read the data from the Excel file
% You can specify the sheet and range if needed
data = xlsread(filename);

% Determine the number of rows and columns in the data
[num_rows, num_cols] = size(data);

% Create row and column labels similar to Excel (A1, A2, B1, B2, etc.)
% Generate column letters (A, B, C, ...)
col_labels = arrayfun(@(x) char(x + 64), 1:num_cols, 'UniformOutput', false);
% Generate row numbers (1, 2, 3, ...)
row_labels = arrayfun(@num2str, (1:num_rows)', 'UniformOutput', false);

% Combine the row and column labels to create Excel-like labels
excel_labels = strcat(repmat(col_labels, num_rows, 1), repmat(row_labels, 1, num_cols));

% Create a heatmap using the resistance data
figure;
h = heatmap(data);

% Set custom axis tick labels to match Excel cell names
h.XDisplayLabels = col_labels;  % Column labels (A, B, C, ...)
h.YDisplayLabels = row_labels;  % Row labels (1, 2, 3, ...)

% Set heatmap title and axis labels
title('Resistance Data Heatmap');

% Optional: customize the color map
colormap('hot');

% Display color bar to show the scale of resistance values
colorbar;

% Save the figure if needed
saveas(gcf, 'Resistance_heatmap_with_labels.png');  % Save as an image file
