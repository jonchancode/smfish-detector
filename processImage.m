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
keypoint_mean = mean(keypoints);
[coarse_principal_components, coarse_keypoints_covariance] = principalComponentAnalysis(keypoints);
% Scale the principal components to 2 standard deviations
num_stddev_for_coarse_pca = 2.1460;
coarse_principal_components = num_stddev_for_coarse_pca * coarse_principal_components;

% Detect outlier blobs according to their distance from the ellipse. Throw
% away any detections beyond a certain threshold.
outlier_indices = [];
for i = 1:size(keypoints, 1)
    keypoint = keypoints(i,:);
    
    % Consider the keypoint an inlier if it's inside a slightly larger
    % ellipse
    threshold_scale = 1.1406;
    is_inside_inlier_ellipse = isInside2dPCAEllipse(keypoint, keypoint_mean, threshold_scale * coarse_principal_components);
    
    if ~is_inside_inlier_ellipse
        outlier_indices = [outlier_indices, i];
    end
end

% Remove the outliers
inlier_keypoints = keypoints;
inlier_keypoints(outlier_indices, :) = [];

% Recompute ellipse with inliers only
inlier_keypoints_mean = mean(inlier_keypoints);
[inlier_principal_components, inlier_keypoints_covariance] = principalComponentAnalysis(inlier_keypoints);
num_stddev_for_inlier_pca = 2.4477;
inlier_principal_components = num_stddev_for_inlier_pca * inlier_principal_components;

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
    
    % Show coarse principal components
    show_coarse_principal_components = false;
    if show_coarse_principal_components
        mean_matrix = repmat(keypoint_mean, 2, 1);
        
        quiver(...
            ax1, ...
            mean_matrix(:,1), ...
            mean_matrix(:,2), ...
            coarse_principal_components(1,:)', ...
            coarse_principal_components(2,:)', ...
            'y');
    end
    
    % Plot ellipse defined by the principal components
    show_coarse_ellipse = false;
    if show_coarse_ellipse
        plotPCAEllipse(...
            ax1, ...
            keypoint_mean, ...
            coarse_principal_components, ...
            'r');
    end
    
    show_inlier_ellipse = true;
    if show_inlier_ellipse
        plotPCAEllipse(...
            ax1, ...
            inlier_keypoints_mean, ...
            inlier_principal_components, ...
            'g');
    end
    
    % Show keypoints
    show_keypoints = false;
    if show_keypoints
        
        scatter(...
            ax1, ...
            keypoints(:,1), ...
            keypoints(:,2), ...
            'r');
        
        scatter(...
            ax1, ...
            inlier_keypoints(:,1), ...
            inlier_keypoints(:,2), ...
            'g');
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
        num_regions_per_pixel = zeros(size(byte_img));
        indices_of_inlier_region_pixels = containers.Map(...
            'KeyType', 'int32', ...
            'ValueType', 'logical');
        xy_of_inlier_region_pixels = [];
        for region_seed = region_seeds'
            % Flood fill the region given by the seed
            indices_of_pixels_in_filled_region = vl_erfill(byte_img, region_seed);
            
            % Increment the num_regions_per_pixel to represent that this
            % set of pixels belongs to one additional region.
            num_regions_per_pixel(indices_of_pixels_in_filled_region) = ...
                num_regions_per_pixel(indices_of_pixels_in_filled_region) + 1;
            
            % Figure out if any pixel in this region is inside the inlier
            % ellipse
            is_inside_inlier_ellipse = false;
            for idx = indices_of_pixels_in_filled_region'
                % Check if we've already marked this pixel as an inlier
                % region during the evaluation of a previous, overlapping
                % region.
                if indices_of_inlier_region_pixels.isKey(idx)
                    % The current region is connected to a pixel that is an
                    % inlier region. Thus, this region must be an inlier
                    % region.
                    % Exit this loop.
                    is_inside_inlier_ellipse = true;
                    break;
                end
                
                % Otherwise, check if this pixel is inside the inlier
                % ellipse.
                [row, col] = ind2sub(size(byte_img), idx);
                
                if isInside2dPCAEllipse(...
                        [col row], ...
                        inlier_keypoints_mean, ...
                        inlier_principal_components)
                    
                    is_inside_inlier_ellipse = true;
                    break;
                end
                
            end
            
            if is_inside_inlier_ellipse
                % Add all the pixels in this region to our list
                for idx = indices_of_pixels_in_filled_region'
                    
                    if indices_of_inlier_region_pixels.isKey(idx)
                        % Skip if we've already recorded this pixel
                        continue;
                    end
                    
                    % Add the xy position of the pixel
                    [row, col] = ind2sub(size(byte_img), idx);
                    xy_of_inlier_region_pixels = [xy_of_inlier_region_pixels; [col row];];
                    
                    % Mark that we've seen this pixel now
                    indices_of_inlier_region_pixels(idx) = true;
                end
            end
            
        end
        
        % Plot the convex hull of the inlier pixel regions
        show_convex_hull = true;
        if show_convex_hull
            hull_pts = convhull(double(xy_of_inlier_region_pixels));
            
            plot(...
                ax1, ...
                xy_of_inlier_region_pixels(hull_pts, 1), ...
                xy_of_inlier_region_pixels(hull_pts, 2), ...
                'c');
            
            plot(...
                ax2, ...
                xy_of_inlier_region_pixels(hull_pts, 1), ...
                xy_of_inlier_region_pixels(hull_pts, 2), ...
                'c');
        end
        
        % Plot the contours
        show_contours = true;
        if show_contours
            
            [~, figure_handle] = contour(...
                ax2, ...
                num_regions_per_pixel, ...
                (0:max(num_regions_per_pixel(:))) + .5);
            
            set(figure_handle, 'color', 'y', 'linewidth', 3);
        end
        
        % Plot inlier ellipse
        if show_inlier_ellipse
            plotPCAEllipse(...
                ax2, ...
                inlier_keypoints_mean, ...
                inlier_principal_components, ...
                'g');
        end
        
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