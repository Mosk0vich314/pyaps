%% clear
clc
clear
close all

%% settings
filepath = 'C:\EmpaDaten\APS_Data\Camera_test_2021_12_10';
Row_names = {'A','F','K','P','U'};
Columns = 1:6:19;

%% import data
N_columns = numel(Columns);
N_rows = numel(Row_names);

im = imread(sprintf('%s/%s%02d.png',filepath,Row_names{1} ,Columns(1)));
im = imresize(im,0.25);
[nY, nX, ~] = size(im);

Image_data = zeros(nY, nX, 3, N_columns, N_rows,'uint8');
Image_data_marked = zeros(nY, nX, 3, N_columns, N_rows,'uint8');

idx_Y = 77;
idx_X = 262;
linewidth = 2;

counter = 1;
for i = 1:N_columns
    for j = 1:N_rows
        im = imread(sprintf('%s/%s%02d.png',filepath,Row_names{j} ,Columns(i)));
        im = imresize(im,0.25);
        
        % add line
        im_marked = im;
        im_marked(idx_Y-linewidth:idx_Y+linewidth,:,1) = 255;
        im_marked(:,idx_X-linewidth:idx_X+linewidth,1) = 255;
        im_marked(idx_Y-linewidth:idx_Y+linewidth,:,1) = 0;
        im_marked(:,idx_X-linewidth:idx_X+linewidth,1) = 0;
        im_marked(idx_Y-linewidth:idx_Y+linewidth,:,1) = 255;
        im_marked(:,idx_X-linewidth:idx_X+linewidth,1) = 255;
        
        Image_data(:,:,:,i,j) = im;
        Image_data_marked(:,:,:,i,j) = im_marked;
    end
end




%% plot images
figure
imshow(imtile(reshape(Image_data_marked, [nY nX 3 N_columns *N_rows])));

%% get transformation using imregcorr function
Transformations = cell(N_columns, N_rows);
Image_data_trans = zeros(size(Image_data),'uint8');
Image_data_trans_marked = zeros(size(Image_data),'uint8');



fixed = Image_data(:,:,:,1,1);

fixedHisteq = cat(3, histeq(fixed(:,:,1)), histeq(fixed(:,:,2)), histeq(fixed(:,:,3)));

imshowpair(fixed,fixedHisteq,'montage')


Rfixed = imref2d(size(fixed));

for i = 1:N_columns
    for j = 1:N_rows
        [i j]
        
        %% get transformation
        moving = Image_data(:,:,:,i,j);

        movingHisteq = cat(3, histeq(moving(:,:,1)), histeq(moving(:,:,2)), histeq(moving(:,:,3)));
        moving = movingHisteq;
        tform = imregcorr(moving, fixed, 'translation');
        
        %% apply transformation
        im = imwarp(Image_data(:,:,:,i,j), tform,'OutputView',Rfixed);
        Transformations{i,j} = tform;
        
        %% add green line
        im_marked = im;
        im_marked(idx_Y-linewidth:idx_Y+linewidth,:,1) = 255;
        im_marked(:,idx_X-linewidth:idx_X+linewidth,1) = 255;
        im_marked(idx_Y-linewidth:idx_Y+linewidth,:,1) = 0;
        im_marked(:,idx_X-linewidth:idx_X+linewidth,1) = 0;
        im_marked(idx_Y-linewidth:idx_Y+linewidth,:,1) = 255;
        im_marked(:,idx_X-linewidth:idx_X+linewidth,1) = 255;
        
        %% save
        Image_data_trans(:,:,:,i,j) = im;
        Image_data_trans(:,:,:,i,j) = im_marked;
        
    end
end

%% plot corrected images
figure
imshow(imtile(reshape(Image_data_trans, [nY nX 3 N_columns *N_rows])));
