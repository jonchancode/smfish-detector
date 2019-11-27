function processImage(img_path, save_intermediate_images)
% Processes one image

%% General ellipse detection

% Load the image and convert to single precision floating point image
byte_img = imread(img_path);
single_img = im2single(byte_img);

% Histogram analysis
% figure(2);
% [pixel_count, gray_levels] = imhist(byte_img, 256);
% pixel_count(1) = 0;
% bar(gray_levels, pixel_count);


% Run DoH to detect strong blobs and PCA to get a coarse estimate of an
% ellipse outlining the cell
covdet_frames = vl_covdet(single_img, 'method', 'Hessian');
keypoints = covdet_frames(1:2, :)';  % First 2 rows
[coarse_principal_components, coarse_keypoints_covariance] = principalComponentAnalysis(keypoints);
keypoint_mean = mean(keypoints);

% Detect outlier blobs according to their distance from the ellipse. Throw
% away any detections beyond a certain threshold.
% Note, we scale the threshold based on the axes of the ellipse (i.e.
% threshold is greater on the long axis).
outlier_indices = [];
for i = 1:size(keypoints, 1)
   keypoint = keypoints(i,:);
   
   % Compute a ray from the center of the ellipse to the given keypoint
   keypoint_ray = keypoint - keypoint_mean;
   
   % Compute the angle between the ray and the biggest component
   % PCA always computes components ordered from largest to smallest, so
   % first component is the largest one.
   largest_component = coarse_principal_components(:,1);
   angle_in_radians = acos(keypoint_ray * largest_component(:,1) / (norm(keypoint_ray) * norm(largest_component)));
   
   % Compute the length of the vector from the center of the ellipse to the
   % edge of the ellipse given this angle.
   % Let major/minor axes, (a, b), be the length of the principal
   % components.
   % TODO: Bug! Something is wrong with the principal component lengths.
   % They're a few orders of magnitude bigger than they should be...
   a = sqrt(norm(coarse_principal_components(:,1)));
   b = sqrt(norm(coarse_principal_components(:,2)));
   % TODO: Need to verify whether this ray to ellipse edge math is right...
   ray_to_edge_of_ellipse = [a * cos(angle_in_radians), b * sin(angle_in_radians)];
   ray_to_edge_of_ellipse_length = norm(ray_to_edge_of_ellipse);
   
   % Consider the keypoint an outlier if it exceeds some factor of the
   % ray_to_edge_of_ellipse.
   threshold_factor = 2.0;
   
   keypoint_ray_length = norm(keypoint_ray);
   if keypoint_ray_length > threshold_factor * ray_to_edge_of_ellipse_length
       outlier_indices = [outlier_indices, i];
   end
end

% Remove the outliers
inlier_keypoints = keypoints;
inlier_keypoints(outlier_indices, :) = [];

% Recompute ellipse with inliers only
[inlier_principal_components, inlier_keypoints_covariance] = principalComponentAnalysis(inlier_keypoints);
inlier_keypoints_mean = mean(inlier_keypoints);

%% Flood filling

% Run MSER to flood fill the regions
[region_seeds, ~] = vl_mser(byte_img);

% TODO: Only use regions overlapping with the inlier ellipse, and fit a
% convex hull using convexhull over the pixels in those selected regions.

%% Visualizations of extracted ROIs

% Turn on visualize if 'save_intermediate_images' is desired
visualize = true || save_intermediate_images;
if visualize   
    % Use figure 1
    figure_1 = figure(1);
    
    % Get the current plotting axes so the future plotting functions can
    % overlay on the same plot.
    ax1 = gca;
    hold(ax1, 'on');
    
    % Show image
    show_original_image = true;
    if show_original_image
        imshow(single_img);
    end
    
    % Rescale the image so that pixel values within range [a, b] are spread
    % out to [0, 1]. Values below a are set to 0, and values above b are
    % set to 1.
    show_rescaled_image = false;
    if show_rescaled_image
        a = 0;
        b = 0.3;
        
        % Scale all the pixel values
        rescaled_img = (single_img - a) / (b - a);
        
        % Clip values below a to be a, and above b to be b
        rescaled_img = min(rescaled_img, 1);
        rescaled_img = max(rescaled_img, 0);
        
        % Show the image
        imshow(rescaled_img);
    end
   
    % Show the thresholded image
    show_thresholded_image = false;
    if show_thresholded_image
        thresholded_img = byte_img > 0;
        imshow(thresholded_img);
    end
    
    % Show principal components
    show_principal_components = false;
    if show_principal_components
        mean_matrix = repmat(keypoint_mean, 2, 1);
        quiver(ax1, mean_matrix(:,1), mean_matrix(:,2), coarse_principal_components(:,1) / 20, coarse_principal_components(:,2) / 20, 'y');
    end
    
    % Plot ellipse defined by the principal components
    show_ellipse = true;
    if show_ellipse
        plotCovarianceEllipse(ax1, keypoint_mean, coarse_keypoints_covariance, 0.9, 'r');
        plotCovarianceEllipse(ax1, inlier_keypoints_mean, inlier_keypoints_covariance, 0.9, 'g');
    end
    
    % Show keypoints
    show_keypoints = true;
    if show_keypoints
        scatter(ax1, keypoints(:,1), keypoints(:,2), 'r');
        scatter(ax1, inlier_keypoints(:,1), inlier_keypoints(:,2), 'g');
    end
    
    % Show MSER regions
    show_mser_regions = true;
    if show_mser_regions
        
        % Draw on figure 2
        figure_2 = figure(2);
        
        % Get axes of figure2 so we can do overlays
        ax2 = gca;
        hold(ax2, 'on');
        
        % Show the image
        imshow(byte_img);
        
        % Computes a look-up table image, num_regions_for_pixel, where each
        % pixel of this image is an integer representing how many
        % overlapping regions there are for that pixel.
        %
        % Note that this forms a sort of "elevation map". Pixels that have
        % high region overlap can be thought of as "mountain peaks".
        %
        % We use the contour function to display a countour map
        % representing the region boundaries.
        num_regions_for_pixel = zeros(size(byte_img));
        for x = region_seeds'
            s = vl_erfill(byte_img, x);
            num_regions_for_pixel(s) = num_regions_for_pixel(s) + 1;
        end

        % Plot the contours
        [c, figure_handle] = contour(ax2, num_regions_for_pixel, (0:max(num_regions_for_pixel(:))) + .5);
        set(figure_handle, 'color', 'y', 'linewidth', 3);
        
        % Plot ellipse
        plotCovarianceEllipse(ax2, inlier_keypoints_mean, inlier_keypoints_covariance, 0.9, 'g');
        
        hold(ax2, 'off');
        
       if save_intermediate_images
           [~, file_name, ~] = fileparts(img_path);
           saveas(figure_2, sprintf('out\\%s_fig2.png', file_name)); 
       end
   end
    end
    
    % Use vl_plot
%     vl_plotframe(frames);

   hold(ax1, 'off');
   
   if save_intermediate_images
       [~, file_name, ~] = fileparts(img_path);
       saveas(figure_1, sprintf('out\\%s_fig1.png', file_name)); 
   end
end