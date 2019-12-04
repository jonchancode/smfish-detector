function processImage(img_path, save_intermediate_images)
% Processes one image


%% Image loading

% Load the image and convert to single precision floating point image
byte_img = imread(img_path);
single_img = im2single(byte_img);


%% Coarse ellipse detection

% Run DoH to detect strong blobs and PCA to get a coarse estimate of an
% ellipse outlining the cell
covdet_frames = vl_covdet(single_img, 'method', 'Hessian');
keypoints = covdet_frames(1:2, :)';  % First 2 rows
keypoint_mean = mean(keypoints);
[coarse_principal_components, ~] = principalComponentAnalysis(keypoints);


%% Remove outlier detections

% Scale the coarse principal components to some threshold which we would
% consider to be inlier points. Use ~2 standard deviations of the
% variance PCA fit on the keypoints.
num_stddev_for_coarse_pca = 2.2;
coarse_principal_components = num_stddev_for_coarse_pca * coarse_principal_components;

% Consider a keypoint outside the ellipse an outlier
inlier_keypoints = filterKeypointsOutsideEllipse(...
    keypoints, ...
    keypoint_mean, ...
    coarse_principal_components);


%% ROI refinement with inliers only

% Recompute an ellipse with inliers only
inlier_keypoints_mean = mean(inlier_keypoints);
[inlier_principal_components, ~] = principalComponentAnalysis(inlier_keypoints);
% Fit more of the variance of the inliers since we trust the information
% given by the inliers more.
num_stddev_for_inlier_pca = num_stddev_for_coarse_pca + 0.3;
inlier_principal_components = num_stddev_for_inlier_pca * inlier_principal_components;


%% ROI dilation

% Run MSER to flood fill the regions (region_map).
% Then find the regions that are connected to the inlier ellipse
% (pixels_of_connected_regions).
[region_map, pixels_of_connected_regions] = computeMserAndFindRegionsConnectedToEllipse(...
    byte_img, ...
    inlier_keypoints_mean, ...
    inlier_principal_components);

% Create a bounding convex hull around the regions connected to the inlier
% ellipse.
% hull_vertex_indices is a list where each element is the index into the
% 'pixels_of_connected_regions' list of pixels.
%
% Thus, to get the xy position of the i'th vertex, you do:
% pixels_of_connected_regions(hull_vertex_indices(i))
hull_vertex_indices = convhull(double(pixels_of_connected_regions));


%% Count number of keypoints inside convex hull

% Get the xy positions of the hull vertices.
% hull_vertex_points is N x 2 matrix where each row is one xy pos of a vertex.
hull_vertex_points = pixels_of_connected_regions(hull_vertex_indices, :);

% Loop through each keypoint and check if it's inside the convex hull.
num_points_inside_hull = 0;
num_points_outside_hull = 0;
for i = 1:size(keypoints, 1)
    
    keypoint = keypoints(i,:);
    
    % Check if it's inside the hull. Increment the appropriate counters.
    if inpolygon(...
            keypoint(1), ...
            keypoint(2), ...
            hull_vertex_points(:,1), ...
            hull_vertex_points(:,2))
        
        num_points_inside_hull = num_points_inside_hull + 1;
        
    else
        
        num_points_outside_hull = num_points_outside_hull + 1;
        
    end
end

% Print to console the result
fprintf('Total detections: %d. # dots inside: %d. # dots outside: %d. Image: %s\n', ...
    size(keypoints, 1), ...
    num_points_inside_hull, ...
    num_points_outside_hull, ...
    img_path);


%% Visualizations

% Turn on visualize if 'save_intermediate_images' is desired
visualize = true || save_intermediate_images;
if visualize
    visualizeProcessImage(...
        save_intermediate_images, ...
        byte_img, ...
        single_img, ...
        keypoints, ...
        inlier_keypoints, ...
        keypoint_mean, ...
        coarse_principal_components, ...
        inlier_keypoints_mean, ...
        inlier_principal_components, ...
        region_map, ...
        pixels_of_connected_regions, ...
        hull_vertex_indices)
end

end