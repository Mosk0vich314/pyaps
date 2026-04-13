%% clear
clc
clear
close all

%% settings

%% get list
list = dir('*.jpg');
N_files = numel(list);

%% read first file
im = imread(sprintf('%s/%s',list(1).folder ,list(1).name));
[nY, nX, ~] = size(im);

Image_data = zeros(nY, nX, 3, N_files,'uint8');
Image_data_red = zeros(nY, nX, N_files,'uint8');
Image_data_green = zeros(nY, nX, N_files,'uint8');
Image_data_blue = zeros(nY, nX, N_files,'uint8');
Image_data_marked = zeros(nY, nX, 3, N_files,'uint8');

idx_Y = 32;
idx_X = 157;
linewidth = 2;

counter = 1;
for idx_files = 1:N_files
    im = imread(sprintf('%s/%s',list(idx_files).folder ,list(idx_files).name));

    % add line
    % im_marked = im;
    % im_marked(idx_Y-linewidth:idx_Y+linewidth,:,1) = 255;
    % im_marked(:,idx_X-linewidth:idx_X+linewidth,1) = 255;
    % im_marked(idx_Y-linewidth:idx_Y+linewidth,:,2) = 0;
    % im_marked(:,idx_X-linewidth:idx_X+linewidth,2) = 0;
    % im_marked(idx_Y-linewidth:idx_Y+linewidth,:,3) = 255;
    % im_marked(:,idx_X-linewidth:idx_X+linewidth,3) = 255;

    Image_data(:,:,:,idx_files) = im;
    % Image_data_marked(:,:,:,idx_files) = im_marked;

    Image_data_red(:,:,idx_files) = adapthisteq(im(:,:,1));
    Image_data_green(:,:,idx_files) = adapthisteq(im(:,:,2));
    Image_data_blue(:,:,idx_files) = adapthisteq(im(:,:,3));

end

%%
Centers = cell(N_files, 1);
Radii = cell(N_files, 1);
close all
for idx_files = 1:N_files
    figure; hold on
    % [Centers{idx_files}, Radii{idx_files}] = imfindcircles(Image_data_red(:,:,idx_files),[10 500],'ObjectPolarity','bright');
    [Centers{idx_files}, Radii{idx_files}] = imfindcircles(Image_data_red(:,:,idx_files),[35 50],'ObjectPolarity','bright','Sensitivity',0.95);

    imshow(Image_data_red(:,:,idx_files))
    viscircles(Centers{idx_files}, Radii{idx_files},'EdgeColor','b');

end

%% plot images
figure
imshow(imtile(reshape(Image_data, [nY nX 3 N_files])));
