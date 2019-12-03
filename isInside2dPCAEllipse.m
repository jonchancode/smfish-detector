function is_inside = isInside2dPCAEllipse(xy, center, principal_components)
% This function returns whether the point, xy, is inside the ellipse
% defined by the 'center' and 'principal_components'.
%
% principal_components is interpreted as a 2 x 2 matrix where each column
% is one principal component.

assert(...
    isequal(size(xy), [1 2]), ...
    'xy should be a 1x2 row vector');
assert(...
    isequal(size(center), [1 2]), ...
    'center should be a 1x2 row vector');
assert(...
    isequal(size(principal_components), [2 2]), ...
    'principal_components should be 2x2 matrix');

% Translate xy into the center of the ellipse
xy_centered = xy - center;

% Get the rotation matrix defined by the principal components
% Just need to orthonormalize it
a = norm(principal_components(:,1));
b = norm(principal_components(:,2));

% Make the principal components the row-space of the rotation matrix
rotation = [
    principal_components(:,1)' / a;
    principal_components(:,2)' / b];
xy_centered_rotated = rotation * xy_centered';

% Use the equation of the ellipse to test whether xy is inside.
x = xy_centered_rotated(1);
y = xy_centered_rotated(2);

is_inside = (((x^2 / a^2) + (y^2 / b^2)) <= 1);

end