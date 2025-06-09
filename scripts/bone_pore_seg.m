% BONE_PORE_SEG_FINAL  - MATLAB code for bone pore segmentation project.
%    
%    This code performs segmentation of bone pores using multithresholding and
%    variable adjusted thresholding method.

clc
clear all
close all

%% Bone Pore Segmentation Project

load('Data2.mat');

[M, N, nIma] = size(Ima1);

temp_ima = Ima1(:,:,1);
temp_ima_mask = Mask1(:,:,1);

figure
imagesc(temp_ima);
axis equal;
colorbar

figure
imagesc(temp_ima);
axis equal;
colormap("gray");


figure
imagesc(temp_ima_mask);
axis equal;
colormap("gray");
%% Transfer intensity information to segmented area


ima_mask_position_ones = find(temp_ima_mask==1);
ima_mask_position_zeros = find(temp_ima_mask==0);

ima_mask = temp_ima_mask;
ima_mask(ima_mask_position_ones) = temp_ima(ima_mask_position_ones);
ima_mask = reshape(ima_mask,M,N);


figure
imagesc(ima_mask);
axis equal
colorbar

surf(ima_mask);
colorbar

figure
mesh(ima_mask);
colorbar

figure
contour(ima_mask);
set(gca,'ydir','reverse')
colorbar

%% Conversion to uint16
min_val = min(ima_mask(:));
rescale_ima_mask = ima_mask + abs(min_val);
% rescale_ima_mask = reshape(ima_mask,M,N);
% ima_mask_ui16 = uint16(ima_mask);

thresh = multithresh(rescale_ima_mask,2);
labels = imquantize(rescale_ima_mask,thresh);
labelsRGB = label2rgb(labels);

figure
imagesc(labelsRGB)
title("Segmented Image")
axis equal


[r,g,b] = imsplit(labelsRGB);
montage({r,g,b},'Size',[1 3])
axis equal
mask_edge = edge(temp_ima_mask,'canny');
g = logical(g);
mask_g = mask_edge | g;
mask_g = imfill(mask_g,[1 1;0.5*M 0.5*N]);
bone_pores = 1-mask_g;

figure
imshow(g);
figure
imshowpair(bone_pores,mask_g,'montage');
%% Hole Punch

figure
surf(ima_mask)
hold on
imagesc(ima_mask)
colorbar

ima_mask_inv = ima_mask*-1;
figure
surf(ima_mask_inv)
peak2 = zeros(M,N);

for ii = 1:N
[peak,pos] = findpeaks(ima_mask_inv(:,ii));
number_peaks = length(peak);
    for jj = 1:number_peaks
        peak2(pos(jj),ii) = peak(jj);
    end
end

min_peak = max(max(peak2));

ima_mask_adjusted = ima_mask;
background_height = min_peak;
ima_mask_adjusted(ima_mask_adjusted==0) = background_height; 
figure
surf(ima_mask_adjusted)

ima_mask_adjusted(ima_mask_adjusted>=background_height) = 0;
ima_mask_adjusted(ima_mask_adjusted~=0) = 255;

figure
imshow(ima_mask_adjusted)

%% Comparisons

ima_mask_gray = mat2gray(ima_mask);
figure
imshow(ima_mask_gray)

figure
imshowpair(ima_mask_gray,bone_pores);
axis equal
title("Method 1")

figure
imshowpair(ima_mask_gray,ima_mask_adjusted);
axis equal
title("Method 2")

figure
imshowpair(bone_pores,ima_mask_adjusted);
axis equal
title("Method 1 vs 2")
