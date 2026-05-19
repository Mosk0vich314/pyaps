%%
clc
clear
close all

search_string = '*stability.mat';
directory = 'E:\Samples\Pads2102\Posttransfer\9K_2nd - Copy\Stability\';
list = dir([directory search_string]) ;
N_files = length(list);

for i = 1:N_files
    load([directory list(i).name])
    
    filename = sprintf('%s_%s_%s', Settings.filename, Settings.sample, Settings.type);
    Save_data_dat(Settings, IV, Gate, filename, 'current'); 
    
end