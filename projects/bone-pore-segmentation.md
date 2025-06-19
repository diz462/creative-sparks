# Bone Pore Segmentation

## Background

![Raw Image1]({{ '/assets/images/raw_image1.png' | relative_url }}){: .image-med }

I started this project during an image processing class. The image above is a cross-sectional slice from a set of HR-pQCT images.

There are two general types of bone structure. Trabecular bone is the spongy inner region. Cortical bone is the dense outer shell. The cortical compartment is defined by the mask below. Within that compartment, the darker regions in the image above, indicate bone pores. These pores reduce cortical bone density which is a primary factor in bone strength.

![Cortical Mask]({{ '/assets/images/cortical_mask_image1.png' | relative_url }}){: .image-med}

## Approach

The raw image data contains a large range of negative and positive values. Negative values indicate loss in bone density so my first thought was to use a filter that removed all positive values. Unfortunately, this was likely the original method that was used and wasn't very accurate (shows that negative values aren't the sole indicator for bone pores).

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

### Otsu's

* *Original Image*
![Og Otsu's]({{ '/assets/images/otsu.png' | relative_url }}){: .image-med}

* *Equalized Image*
![Og Otsu's]({{ '/assets/images/eq_otsu.png' | relative_url }}){: .image-med}

* *Equalized Image with Local Thresholding*
![Og Otsu's]({{ '/assets/images/eq_otsu_local.png' | relative_url }}){: .image-med}

Canny edge detection was slightly better than the original Otsu but still not great even after adjusting high and low thresholds.

~~~matlab
canny = edge(ima_mask,'canny', 0.4, 0.5);
canny = bwareaopen(imfill(canny,'holes'),50);
~~~

* *Canny*
![Canny]({{ '/assets/images/canny.png' | relative_url }}){: .image-med}

LoG also showed potential but needs a significant amount of additional work.

* *LoG*
![LoG]({{ '/assets/images/log.png' | relative_url }}){: .image-med }

## Method 1

The first method I used was a multi-level thresholding algorithm.

![Construction]({{ '/assets/images/construction-sign.png' | relative_url }}){: .image-preview }
