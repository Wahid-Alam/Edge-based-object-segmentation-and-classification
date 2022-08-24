clear; close all;  

  

%% Import and display original image  

I = imread('washers.png');   

figure(1); imshow(I,[]); title('Original Image')   

  

% Separate the image into each color channel as the color inputs   

r_input = I(:,:,1);   

g_input = I(:,:,2);   

b_input = I(:,:,3);   

  

figure(2);   

gray_image = rgb2gray(I); 

subplot(2,2,1); imshow(gray_image,[]); title('All Channels')   

subplot(2,2,2); imshow(r_input,[]); title('Red Channel')   

subplot(2,2,3); imshow(g_input,[]); title('Green Channel')   

subplot(2,2,4); imshow(b_input,[]); title('Blue Channel')   

  

%% Median Filter to get rid of lines in background   

r_filtered = medfilt2(r_input, [15 15]);     

g_filtered = medfilt2(g_input, [15 15]);     

b_filtered = medfilt2(b_input, [15 15]);    

  

im_filtered(:,:,1) = r_filtered;  % Recombines filtered channels into single filtered image 

im_filtered(:,:,2) = g_filtered; 

im_filtered(:,:,3) = b_filtered; 

gray_filtered = rgb2gray(im_filtered); 

  

figure(3);    

subplot(2,2,1); imshow(gray_filtered,[]); title('Median Filtered All Channel')  

subplot(2,2,2); imshow(r_filtered,[]); title('Median Filtered Red Channel')   

subplot(2,2,3); imshow(g_filtered,[]); title('Median Filtered Green Channel')   

subplot(2,2,4); imshow(b_filtered,[]); title('Median Filtered Blue Channel')   

  

%% Canny edge detection   

r_im = double(r_filtered);  % Converts to double for edge detection algorithm 

g_im = double(g_filtered);   

b_im = double(b_filtered);  

gray_im = double(gray_filtered); 

  

gray_edge = edge(gray_im,'canny',0.5,10);  

red_edge = edge(r_im,'canny',0.5,10);   

green_edge = edge(g_im,'canny',0.5,10);    

blue_edge = edge(b_im,'canny',0.5,10);    

  

% figure(4)   

% subplot(2,2,1); imshow(gray_edge); title('Gray Canny Edge')  

% subplot(2,2,2); imshow(red_edge); title('Red Canny Edge')   

% subplot(2,2,3); imshow(green_edge); title('Green Canny Edge')   

% subplot(2,2,4); imshow(blue_edge); title('Blue Canny Edge')   

  

figure(4); imshow(gray_edge); title('Gray Canny Edge')  

  

%% Dilate Image 

se = strel('line',10,15); 

G = imdilate(gray_edge,se); 

figure(5); imshow(G,[]); title('Dilated Edges') 

  

bc = gray_filtered-g_filtered; 

figure(6); imshow(bc,[]); title('Brightened Color Distinction for Classification')  % Makes the red washers really bright and easily distinguishable 

  

%% Hough Transform for cirlce detection   

[pre_centers_i,pre_radii_i] = imfindcircles(G,[61 150],'Method','TwoStage', 'EdgeThreshold',0.25, 'Sensitivity', 0.9); % Inner circles 

[centers_o,radii_o] = imfindcircles(G,[151 250],'Method','TwoStage', 'EdgeThreshold',0.2, 'Sensitivity', 0.9); % Outer circles 

num_washers = length(centers_o);    % Determines how many washers are in the image 

  

centers = [pre_centers_i;centers_o]; 

radii = [pre_radii_i;radii_o]; 

radius = radii; center = centers; 

radius = cat(1,radius,radii); center = cat(1,center,centers);  

  

% Table that list center, inner radius, outer radius, and class for each washer 

washer_list{1,1} = 'Numebr'; 

washer_list{1,2} = 'Type'; 

washer_list{1,3} = 'X Center'; 

washer_list{1,4} = 'Y Center'; 

washer_list{1,5} = 'Inner Radius'; 

washer_list{1,6} = 'Outer Radius'; 

  

% Plots 

figure(7); imshow(G,[]); title('')   % Shows original image   

viscircles(center,radius ,'EdgeColor','b')    % Detected cirlce overlay    

  

%% Matches Centers and Radii for Each Washer 

I2O_order = dsearchn(pre_centers_i,centers_o);  % Order to convert inner centers to outer center list 

for itr = 1:length(centers_o) 

    centers_i(itr,1) = pre_centers_i(I2O_order(itr),1); %#ok<*SAGROW> 

    centers_i(itr,2) = pre_centers_i(I2O_order(itr),2); 

    radii_i(itr,1) = pre_radii_i(I2O_order(itr),1); 

     

    washer_list{itr+1,1} = itr; 

    washer_list{itr+1,3} = centers_o(itr,1); 

    washer_list{itr+1,4} = centers_o(itr,2); 

    washer_list{itr+1,5} = radii_i(itr); 

    washer_list{itr+1,6} = radii_o(itr); 

end 

  

%% Create Segmentation mask from detected circles 

[rows, cols] = size(G); 

seg = zeros(size(G)); 

washer_list{1,7} = 'Median RB Val'; 

for itr2 = 1:num_washers 

    ro = radii_o(itr2); % Outer radius 

    ri = radii_i(itr2); % Inner radius 

    xc = centers_o(itr2,1); % x center 

    yc = centers_o(itr2,2); % y center 

    mask_intensity = 1/itr2;    % Assigns a different value to each mask, and all vals in a mask will be uniform 

     

    % Determine if point is inside or outside circle 

    for x = 1:cols 

        for y = 1:rows 

            if (x-xc)^2 + (y-yc)^2 <= ro^2  % Inside of large circle 

                if (x-xc)^2 + (y-yc)^2 >= ri^2  % Outside of small circle, so it's in the ring 

                    seg(y,x) = mask_intensity;   

                end 

            end 

        end 

    end 

     

    % Now find median color value in each washer 

    mask_pts = find(seg == mask_intensity); 

    mask_colors = bc(mask_pts); % All values of red & blue components 

    washer_color = median(mask_colors); % Median value of that mask 

    washer_list{itr2+1,7} = washer_color;   % Saves color of each washer to the composite variable 

end 

figure(9); imshow(seg,[]); impixelinfo 

  

%% Washer Classification  

for itr3 = 1:num_washers 

    if washer_list{itr3+1,7} > 5 % Bright color response = Type B 

    % Type B - Sort out B washers by color since it's the easiest to sort first 

%        I1 = insertText(I, round(centers_o(itr3,:)), ['B ',num2str(itr3)], 'FontSize', 36, 'BoxColor', 'green', 'BoxOpacity', 0.8);    % Adds washer # to text 

       I1 = insertText(I, round(centers_o(itr3,:)), 'B ', 'FontSize', 40, 'BoxColor', 'green', 'BoxOpacity', 0.8); 

        I=I1;  

        type = 'B'; 

    elseif (radii_o(itr3)/radii_i(itr3) < 2)    % Radius of inner and outer circle are similar for A, very different for C 

    % Type A 

       I1 = insertText(I, round(centers_o(itr3,:)), 'A ', 'FontSize', 40, 'BoxColor', 'green', 'BoxOpacity', 0.8);  

        I=I1;  

        type = 'A'; 

    else 

    % Type C 

       I1 = insertText(I, round(centers_o(itr3,:)), 'C ', 'FontSize', 40, 'BoxColor', 'green', 'BoxOpacity', 0.8); 

        I=I1;  

        type = 'C'; 

    end   

    washer_list{itr3+1,2} = type; 

end   

  

figure(8);imshow(I1, []); xlabel('Detected Image')  