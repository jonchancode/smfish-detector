function processImage(img_path, save_intermediate_images)
% Processes one image

%% Coarse ellipse detection

% Load the image and convert to single precision floating point image
byte_img = imread(img_path);
single_img = im2single(byte_img);

% Run DoH to detect strong blobs and PCA to get a coarse estimate of an
% ellipse outlining the cell
covdet_frames = vl_covdet(single_img, 'method', 'Hessian');
keypoints = covdet_frames(1:2, :)';  % First 2 rows
keypoint_mean = mean(keypoints);
[coarse_principal_components, coarse_keypoints_covariance] = principalComponentAnalysis(keypoints);

%% Remove outlier detections

% Scale the coarse principal components to some threshold which we would
% consider to be inlier points. Use ~2 standard deviations of the
% variance PCA fit on the keypoints.
num_stddev_for_coarse_pca = 2.2;
coarse_principal_components = num_stddev_for_coarse_pca * coarse_principal_components;

% Consider a keypoint outside the ellipse an outlier
outlier_indices = [];
for i = 1:size(keypoints, 1)
    keypoint = keypoints(i,:);

    is_inside_inlier_ellipse = isInside2dPCAEllipse(...
        keypoint, ...
        keypoint_mean, ...
        coarse_principal_components);
    
    if ~is_inside_inlier_ellipse
        outlier_indices = [outlier_indices, i];
    end
end

% Create a new list of keypoints without the outliers
inlier_keypoints = keypoints;
inlier_keypoints(outlier_indices, :) = [];

%% ROI refinement with inliers only

% Recompute an ellipse with inliers only
inlier_keypoints_mean = mean(inlier_keypoints);
[inlier_principal_components, inlier_keypoints_covariance] = principalComponentAnalysis(inlier_keypoints);
% Fit more of the variance of the inliers since we trust the information
% given by the inliers more.
num_stddev_for_inlier_pca = num_stddev_for_coarse_pca + 0.3;
inlier_principal_components = num_stddev_for_inlier_pca * inlier_principal_components;

%% ROI dilation

% Run MSER to flood fill the regions, and compute which regions overlap
% with the inlier ellipse.
[region_map, xy_of_inlier_region_pixels] = computeMserRegionMapOverlappingEllipse(...
    byte_img, ...
    inlier_keypoints_mean, ...
    inlier_principal_components, ...
    inlier_keypoints_covariance);

% Create a bounding convex hull around the regions overlapping the inlier
% ellipse.
hull_pts = convhull(double(xy_of_inlier_region_pixels));

%% Visualizations

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
        
        % We use the contour function to display the region_map which will
        % draw lines around the region boundaries
        show_contours = true;
        if show_contours
            
            [~, figure_handle] = contour(...
                ax2, ...
                region_map, ...
                (0:max(region_map(:))) + .5);
            
            set(figure_handle, 'color', 'y', 'linewidth', 3);
        end
        
        % Plot the convex hull of the inlier pixel regions
        show_convex_hull = true;
        if show_convex_hull

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