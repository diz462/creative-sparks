# Bone Pore Segmentation

## Background

![Raw Image1]({{ '/assets/images/raw_image1.png' | relative_url }}){: .image-med }

I started this project during an image processing class. The image above is a cross-sectional slice from a set of HR-pQCT images.

There are two general types of bone structure. Trabecular bone is the spongy inner region. Cortical bone is the dense outer shell. The cortical compartment is defined by the mask below. Within that compartment, the darker regions in the image above, indicate bone pores. These pores reduce cortical bone density which is a primary factor in bone strength.

![Cortical Mask]({{ '/assets/images/cortical_mask_image1.png' | relative_url }}){: .image-med}

## Approach

The raw image data contains a large range of negative and positive values. Negative values indicate loss in bone density so my first thought was to use a filter that removed all positive values. Unfortunately, this was likely the original method used and wasn't very accurate (shows that negative values aren't the sole indicator for bone pores).

First, I transferred the image values defined by the cortical mask to construct an image mask.

~~~matlab
ima_mask_position_ones = find(temp_ima_mask==1);
ima_mask_position_zeros = find(temp_ima_mask==0);

ima_mask = temp_ima_mask;
ima_mask(ima_mask_position_ones) = temp_ima(ima_mask_position_ones);
ima_mask = reshape(ima_mask,M,N);
~~~

![Image Mask]({{ '/assets/images/image_mask.png' | relative_url }}){: .image-med}

Then, I mapped the values to grayscale, constructed a histogram, and applied image equalization.

### Histograms

* *Original Image Mask*
![Og Histogram]({{ '/assets/images/og_hist.png' | relative_url }}){: .image-med}

* *Equalized Image Mask*
![Eq Histogram]({{ '/assets/images/eq_hist.png' | relative_url }}){: .image-med}

This improved contrast but didn't noticibly improve the areas surrounding darker regions. Ultimately, I abandoned this idea to preserve the original values.

* *Original Image Mask*
![Image Mask]({{ '/assets/images/image_mask.png' | relative_url }}){: .image-med}

* *Equalized Image Mask*
![Eq Mask]({{ '/assets/images/eq-image-mask.png' | relative_url }}){: .image-med}

Next, I applied basic methods like Otsu's, then moved on to Canny and Laplacian of Gaussian (LoG). Otsu's missed many of the large pores but showed high potential when applied to the equalized mask using local thresholding.

~~~matlab
% Otsu
ima_bin = imbinarize(ima_mask_eq);

% Adaptive threshold
ima_adapt = adaptthresh(ima_mask_eq,0.8);
ima_bin_adapt = imbinarize(ima_mask_eq,ima_adapt);
~~~

### Otsu's Method

* *Original Image*
![Og Otsu's]({{ '/assets/images/otsu.png' | relative_url }}){: .image-med}

* *Equalized Image*
![Og Otsu's]({{ '/assets/images/eq_otsu.png' | relative_url }}){: .image-med}

* *Equalized Image with Local Thresholding*
![Og Otsu's]({{ '/assets/images/eq_otsu_local.png' | relative_url }}){: .image-med}

### Canny Edge Detection

Canny was slightly better than the original Otsu but still not great even after adjusting high and low thresholds.

~~~matlab
canny = edge(ima_mask,'canny', 0.4, 0.5);
canny = bwareaopen(imfill(canny,'holes'),50);
~~~

* *Canny*
![Canny]({{ '/assets/images/canny.png' | relative_url }}){: .image-med}

### Laplacian of Gaussian

LoG also showed potential but needs a significant amount of additional work.

~~~matlab
lap = 4*del2(ima_mask);
kernel = [0   1   0
          1  -4   1
          0   1   0];
laplacian = conv2(lap, kernel, 'same');
~~~

* *LoG*
![LoG]({{ '/assets/images/log.png' | relative_url }}){: .image-med }

### \*Update 1\*

After looking at this again, a lot of things went wrong here.

$LoG(f) = ∇^2(G∗f)$

Where, $G$ is the Gaussian kernel, $*$ is convolution, and $∇^2$ is the Laplacian operator.

What I did:

$LoG(f) = G*(∇^2f)$

The order of operations aren't commutative, and I applied the Laplacian a second time instead of the Gaussian kernel (sorry professor:disappointed:).

#### Gaussian Blur

I applied a Gaussian blur using sigma values: 0.25, 0.75, 1.25, 1.75

~~~matlab
sigma = [0.25:0.5:1.75];

gaussian_blur = zeros(M,N,length(sigma));
for ii = 1:length(sigma)
    gaussian_blur(:,:,ii) = imgaussfilt(ima_mask_gray,sigma(ii));
end
~~~

* *Grayscale*
![grayscale]({{ '/assets/images/grayscale.jpg' | relative_url }}){: .image-lg }

* *Gaussian*
![gaussian-montage]({{ '/assets/images/gaussian-blur.jpg' | relative_url }}){: .image-montage }

#### Laplacian Operator

After further reading, del2 is a discrete Laplacian operator that uses approximations to improve performance. I was curious how it compared to conv2 which actually performs convolution using a kernel and how changing that kernel from 4 to 8 adjacent neighbors affects the sharpened image.

~~~matlab
discrete_lap = zeros(M,N,length(sigma));
for ii = 1:length(sigma)
    discrete_lap(:,:,ii) = 4*del2(gaussian_blur(:,:,ii));
end
~~~

* *Discrete Laplacian*
![discrete]({{ '/assets/images/discrete-log.jpg' | relative_url }}){: .image-montage }

~~~matlab
kernel_4n = [0  1  0
             1 -4  1
             0  1  0];

lap_4n = zeros(M,N,length(sigma)); 
for ii = 1:length(sigma)
    lap_4n(:,:,ii) = conv2(gaussian_blur(:,:,ii), kernel_4n,"same");
end             
~~~

* *4n Laplacian*
![discrete]({{ '/assets/images/discrete-log.jpg' | relative_url }}){: .image-montage }

~~~matlab
kernel_8n = [1  1  1
             1 -8  1
             1  1  1];

lap_8n = zeros(M,N,length(sigma)); 
for ii = 1:length(sigma)
    lap_8n(:,:,ii) = conv2(gaussian_blur(:,:,ii), kernel_8n,"same");
end
~~~

* *8n Laplacian*
![discrete]({{ '/assets/images/discrete-log.jpg' | relative_url }}){: .image-montage }

#### Image Sharpening

In order to sharpen the grayscale image mask, I subtracted the LoG images (subtract if center kernel is negative, add if positive).

* *Original Grayscale*
![grayscale]({{ '/assets/images/grayscale.jpg' | relative_url }}){: .image-med}

* *Sharpened Discrete*
![sharp-discrete]({{ '/assets/images/sharp-log-discrete.jpg' | relative_url }}){: .image-montage }

* *Sharpened 4n*
![sharp-4n]({{ '/assets/images/sharp-log-4n.jpg' | relative_url }}){: .image-montage }

* *Sharpened 8n*
![sharp-8n]({{ '/assets/images/sharp-log-8n.jpg' | relative_url }}){: .image-montage }

~~~matlab
% Discrete
for ii = 1:length(sigma)
    sharp_dis(:,:,ii) = ima_mask_gray - discrete_lap(:,:,ii);
end

% Convolutions
for ii = 1:length(sigma)
    sharp_4n(:,:,ii) = ima_mask_gray - lap_4n(:,:,ii);
end

for ii = 1:length(sigma)
    sharp_8n(:,:,ii) = ima_mask_gray - lap_8n(:,:,ii);
end
~~~

## Method 1

The first method I used was a multi-level thresholding algorithm.

![Construction]({{ '/assets/images/construction-sign.png' | relative_url }}){: .image-preview }
