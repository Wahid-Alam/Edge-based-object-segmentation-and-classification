# Edge-based-object-segmentation-and-classification
## project description:
In this group project, we implement segmentation and classification in two stages. In part 1, we write the script to segment and classify washers for a given image by the instructor. Next, we generalize our algorithm to implement on several other images contaminated with different orientation, depth and hand-written backgrounds. 
## Results:
### representative input images:
  <img src="input_images.png" width="500" title="input images">
  
### Algorithm:
<img src="algorithm.png" width="300" title="algorithm">

### Edge segmentation:
<img src="segmented_washers.png" alt="nothing" width="500" title="segmented washers">

### classification by color and shape:
<img src="classified_washers.png" alt="nothing" width="500" title="classified washers">

## Description of the scripts:
`/part_1/part_1.m:` well-commented script to perform all the steps of the algorithm on the image __/part_1/washers.png__
`/part_2/part_2.m:` generalized version of `part_1.m` and works on all the images in __/part_2__
