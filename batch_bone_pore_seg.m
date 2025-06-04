clc
close all
clear all

%% Cortical Bone Pore Segmentation Batch Code

load('Image_set1.mat');
load('Mask_set1.mat');

image_set = Ima1;
mask_set = Mask1;

[M, N, nIma] = size(image_set);

% Choose number of random images and format into array
% samples = 5;
% rand_ima = randi([1 nIma],samples,1);

% All images from set
num_ima = size(Ima1);
rand_ima = [1:num_ima(3)]';

num_rand_ima = length(rand_ima);
temp_ima = zeros(M,N,num_rand_ima);
temp_ima_mask = zeros(M,N,num_rand_ima);

for ii=1:num_rand_ima
    temp_ima(:,:,ii) = image_set(:,:,rand_ima(ii));
    temp_ima_mask(:,:,ii) = mask_set(:,:,rand_ima(ii));
end

%% Transfer intensity information to cortical segment

ima_mask_re = zeros(M,N,num_rand_ima);
ima_mask_adjusted2 = zeros(M,N,num_rand_ima);
ima_mask_gray = zeros(M,N,num_rand_ima);
ima_mask_og = zeros(M,N,num_rand_ima);

for ii=1:num_rand_ima

    ima_mask_position_ones = find(temp_ima_mask(:,:,ii)==1);

    ima_mask = temp_ima_mask(:,:,ii);
    temp_ima2 = temp_ima(:,:,ii); % needed to index
    ima_mask(ima_mask_position_ones) = temp_ima2(ima_mask_position_ones);
    ima_mask_re(:,:,ii) = reshape(ima_mask,M,N);

    ima_mask_og(:,:,ii) = ima_mask;

    % Variable Thresholding Method 2
        % nested within loop to use same variable names from original code

    % Find minimum negative peak 
    ima_mask_inv = ima_mask*-1;

        for jj = 1:N

            [peak,pos] = findpeaks(ima_mask_inv(:,jj));
            number_peaks = length(peak);

            for kk = 1:number_peaks

                    peak2(pos(kk),jj) = peak(kk);
            end
        end

    min_peak = max(max(peak2));

    % Set background height to min negative peak value
    ima_mask_adjusted = ima_mask;
    background_height = min_peak;
    ima_mask_adjusted(ima_mask_adjusted==0) = background_height; 
    ima_mask_adjusted(ima_mask_adjusted>=background_height) = 0;
    ima_mask_adjusted(ima_mask_adjusted~=0) = 1;
     
    ima_mask_adjusted2(:,:,ii) = ima_mask_adjusted;
    ima_mask_gray(:,:,ii) = mat2gray(ima_mask);

end

%% Rescale Image Values

rescale_ima_mask = zeros(M,N,num_rand_ima);

for ii=1:num_rand_ima

    ima_mask = ima_mask_re(:,:,ii);
    min_val = min(ima_mask_re(:));
    rescale_ima_mask(:,:,ii) = ima_mask + abs(min_val);
end

%% Multilevel Threshold Method 1

r = zeros(M,N,num_rand_ima,1);
g = zeros(M,N,num_rand_ima,1);
b = zeros(M,N,num_rand_ima,1);

for ii=1:num_rand_ima

    thresh = multithresh(rescale_ima_mask(:,:,ii),2);
    labels = imquantize(rescale_ima_mask(:,:,ii),thresh);
    labelsRGB = label2rgb(labels);

    [r(:,:,ii),g(:,:,ii),b(:,:,ii)] = imsplit(labelsRGB);
end

% montage({r(:,:,1),g(:,:,1),b(:,:,1)},'Size',[1 3])
% axis equal

%% Bone Pore Isolation

% Mask edge detection
mask_g = zeros(M,N,num_rand_ima);
for ii=1:num_rand_ima

    ima_edge = temp_ima_mask(:,:,ii);
    mask_edge = edge(ima_edge,'canny');
    g_log = logical(g(:,:,ii));
    mask_g(:,:,ii) = mask_edge | g_log;
    
end
    
% figure
% imshowpair(g(:,:,1),mask_g(:,:,1),'montage');


% Remove background
bone_pores = zeros(M,N,num_rand_ima);

for ii=1:num_rand_ima

    mask_g2 = logical(mask_g(:,:,ii));
    back_fill = imfill(mask_g2,[1 1;0.5*M 0.5*N]);
    bone_pores(:,:,ii) = 1-back_fill;
end

% figure
% montage({bone_pores(:,:,1),bone_pores(:,:,2),bone_pores(:,:,3)});

%% Image Comparisons

% for ii=1:num_rand_ima
% for ii=17
% 
%     diff = abs(ima_mask_adjusted2(:,:,ii)-bone_pores(:,:,ii));
% 
% 
%     figure
%     tiled = tiledlayout(3,4,'TileSpacing','none','Padding','compact');
%     title(tiled,"Image "+rand_ima(ii));
%     annotation('textbox',[.73 .45 .1 .2],'String', ...
%     ['Green indicates areas included only in Method 1. Pink indicates areas included' ...
%     ' only in Method 2. White indicates areas shared by both methods.'], ...
%     'EdgeColor','none');
% 
%     nexttile(5)
%     imagesc(ima_mask_og(:,:,ii));
%     axis off;
%     axis image;
% 
%     nexttile(1)
%     imshowpair(ima_mask_gray(:,:,ii),bone_pores(:,:,ii));
%     axis image;
%     title("Method 1",'Units','normalized','Position',[0.18 0.88],'Color','g','FontSize',8);
% 
%     nexttile(9)
%     imshowpair(ima_mask_gray(:,:,ii),ima_mask_adjusted2(:,:,ii));
%     axis image;
%     title("Method 2",'Units','normalized','Position',[0.18 0.05],'Color','g','FontSize',8);
% 
%     nexttile(7)
%     imshowpair(bone_pores(:,:,ii),ima_mask_adjusted2(:,:,ii));
%     axis image;
%     title("Method 1 vs 2");
% 
%     nexttile(6)
%     imshowpair(ima_mask_gray(:,:,ii),diff);
%     axis image;
%     title("Method 1 vs 2 Differences"); 
% 
% 
% end



%% Filtered Image Comparisons

% Method 1
figure
tiled = tiledlayout(3,4,'TileSpacing','none','Padding','compact');
title(tiled,"Image "+rand_ima(ii),"Filter Pixel Volume = "+pixel_volume);

nexttile(6)
imshowpair(ima_mask_gray(:,:,ii),diff_bone_pore(:,:,ii));
axis image;
title("Method 1 vs Filtered Differences");

nexttile(7)
imshowpair(bone_pores(:,:,ii),bone_pores_filt(:,:,ii));
axis image;
title("Method 1 vs Filtered");

nexttile(5)
imagesc(ima_mask_og(:,:,ii));
axis off;
axis image;

nexttile(1)
imshowpair(ima_mask_gray(:,:,ii),bone_pores(:,:,ii));
axis image;
title("Method 1");

nexttile(9)
imshowpair(ima_mask_gray(:,:,ii),bone_pores_filt(:,:,ii));
axis image;
title("Method 1 Filtered",'Units','normalized','Position',[0.18 0.05],'Color','g','FontSize',8);


% Method 2
figure
tiled = tiledlayout(3,4,'TileSpacing','none','Padding','compact');
title(tiled,"Image "+rand_ima(ii),"Filter Pixel Volume = "+pixel_volume);

nexttile(1)
imshowpair(ima_mask_gray(:,:,ii),ima_mask_adjusted2(:,:,ii));
axis image;
title("Method 2");

nexttile(5)
imagesc(ima_mask_og(:,:,ii));
axis off;
axis image;

nexttile(6)
imshowpair(ima_mask_gray(:,:,ii),diff_image_mask_adjusted(:,:,ii));
axis image;
title("Method 2 vs Filtered Differences");

nexttile(7)
imshowpair(ima_mask_adjusted2(:,:,ii),ima_mask_adjusted2_filt(:,:,ii));
axis image;
title("Method 2 vs Filtered");

nexttile(9)
imshowpair(ima_mask_gray(:,:,ii),ima_mask_adjusted2_filt(:,:,ii));
axis image;
title("Method 2 Filtered",'Units','normalized','Position',[0.18 0.05],'Color','g','FontSize',8);

% Method 1 vs 2 filtered image comparisons
diff_filtered = abs(ima_mask_adjusted2_filt(:,:,ii)-bone_pores_filt(:,:,ii));

figure
tiled = tiledlayout(3,3,'TileSpacing','none','Padding','compact');
title(tiled,"Image "+rand_ima(ii));

nexttile(2)
imshowpair(ima_mask_gray(:,:,ii),bone_pores_filt(:,:,ii));
axis image;
title("Method 1 Filtered");

nexttile(6)
imshowpair(bone_pores_filt(:,:,ii),ima_mask_adjusted2_filt(:,:,ii));
axis image;
title("Method 1 vs 2 Filtered");

nexttile(4)
imshowpair(ima_mask_gray(:,:,ii),diff_filtered);
axis image;
title("Method 1 vs 2 Filtered Differences");

nexttile(5)
imagesc(ima_mask_og(:,:,ii));
axis off;
axis image;

nexttile(8)
imshowpair(ima_mask_gray(:,:,ii),ima_mask_adjusted2_filt(:,:,ii));
axis image;
title("Method 2 Filtered",'Units','normalized','Position',[0.18 0.05],'Color','g','FontSize',8);



