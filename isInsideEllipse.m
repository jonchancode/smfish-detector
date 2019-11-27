function is_inside = isInsideEllipse(xy, principal_components, ellipse_center)

% Compute a ray from the center of the ellipse to the given keypoint
xy_ray = xy - ellipse_center;

% Compute the angle between the ray and the biggest component
% PCA always computes components ordered from largest to smallest, so
% first component is the largest one.
largest_component = principal_components(:,1);
angle_in_radians = acos(xy_ray * largest_component(:,1) / (norm(xy_ray) * norm(largest_component)));

% Compute the length of the vector from the center of the ellipse to the
% edge of the ellipse given this angle.
% Let major/minor axes, (a, b), be the length of the principal
% components.
% TODO: Bug! Something is wrong with the principal component lengths.
% They're a few orders of magnitude bigger than they should be...
a = sqrt(norm(principal_components(:,1)));
b = sqrt(norm(principal_components(:,2)));
% TODO: Need to verify whether this ray to ellipse edge math is right...
ray_to_edge_of_ellipse = [a * cos(angle_in_radians), b * sin(angle_in_radians)];
ray_to_edge_of_ellipse_length = norm(ray_to_edge_of_ellipse);

% Consider the keypoint an outlier if it exceeds some factor of the
% ray_to_edge_of_ellipse.
threshold_factor = 1.0;

% Check if the xy_ray length exceeds the bounds of the ellipse
xy_ray_length = norm(xy_ray);
is_inside = (xy_ray_length > threshold_factor * ray_to_edge_of_ellipse_length);

end