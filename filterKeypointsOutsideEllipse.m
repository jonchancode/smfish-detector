function inlier_keypoints = filterKeypointsOutsideEllipse(keypoints, ellipse_center, principal_components)
% Goes through the list of keypoints (N x 2 matrix where each row is an x,y
% position) and filters out the keypoints outside of the ellipse.

inlier_indices = [];
for i = 1:size(keypoints, 1)
    keypoint = keypoints(i,:);

    is_inside_ellipse = isInside2dPCAEllipse(...
        keypoint, ...
        ellipse_center, ...
        principal_components);
    
    if is_inside_ellipse
        inlier_indices = [inlier_indices, i];
    end
end

% Create a new list of keypoints with only inliers
inlier_keypoints = keypoints(inlier_indices, :);

end