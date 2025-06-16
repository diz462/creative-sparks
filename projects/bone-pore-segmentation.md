# Background

![Raw Image1]({{ '/assets/images/raw_image1.png' | relative_url }}){: .image-preview }

I started this project during an image processing class. The image above is a cross-sectional slice from a set of HR-pQCT images. 

![Cortical Mask]({{ '/assets/images/cortical_mask_image1.png' | relative_url }}){: .image-preview }

There are two main types of bone structure. Trabecular bone is the spongy inner region. Cortical bone is the dense exterior shell. The cortical compartment is defined by the image above. Within that compartment, the darker regions are bone pores, and they reduce cortical bone density which is a primary factor in bone strength.

# Approach

My approach was to try several different segmentation techniques and continue working on the ones with the highest potential. I started with thresholding like Otsu's, then moved on to Canny and Laplacian of Gaussian (LoG). Otsu's had the worst results but the highest potential due to thresholding working as a pseudo filter. Canny was slightly better with adjustments, while LoG showed high potential. 

![Canny]({{ '/assets/images/canny.png' | relative_url }}){: .image-preview }
![LoG]({{ '/assets/images/log.png' | relative_url }}){: .image-preview }
