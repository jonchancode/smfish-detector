function is_inside = isInsideEllipse(xy, center, covariance, probability)
% This function checks whether a point, xy, is within the ellipse defined
% by a 2d normal distribution parameterized by (center, covariance, and probability).
%
% xy = 2d point we're interested in
% center = 2d center of the ellipse
% covariance = Covariance defining the ellipse
% probability = Assuming the ellipse is showing an outline of a Gaussian
% with the provided covariance, probability sets what factor of this
% covariance we're looking in. In simpler terms, probabily effectively
% scales the ellipse to be larger or smaller.
%
% The probability is defined as assuming the covariance is describing a
% Gaussian ellipse.
% Thus, the mathematical definition of "inside" here means whether the xy 
% point is within probabilty % of an ellipse defined by a gaussian with 
% the provided covariance.


% TODO: We're just doing it this way to match how the
% "plotCovarianceEllipse" code works. We should simplify this by removing
% the concept of "probability".

% Scale the variance according to the probability we desire
variance_scale = -2 * log(1 - probability);

[evectors, evalues] = eig(covariance * variance_scale);

xy_centered = xy - center;

% Rotate the xy point to be aligned with the eigen vectors.
% Thus, need to project onto the eigen vectors.
% Thus, make the evectors the rows of the rotation matrix.
xy_centered_rotated = evectors' * xy_centered';

% The boundary of an ellipse is defined x^2/a^2 + y^2/b^2 = 1 where (a, b)
% define the major and minor axes of the ellipse, and (x, y) is any point.
% Thus, when (x, y) is plugged in and is less than 1, then (x, y) is inside
% the boundary.

% Retrieve a^2 and b^2 from the eigen values
a2 = evalues(1, 1);
b2 = evalues(2, 2);

x = xy_centered_rotated(1);
y = xy_centered_rotated(2);

is_inside = (((x^2 / a2) + (y^2 / b2)) <= 1);

end