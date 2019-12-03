function plotPCAEllipse(ax, center, principal_components, variance_explained, color)

t = linspace(0, 2 * pi);

scaled_components = principal_components * diag(sqrt(variance_explained));
ellipse_boundary_pts = scaled_components * [cos(t(:))'; sin(t(:))'];

plot(...
    ax, ...
    ellipse_boundary_pts(1, :) + center(1), ...
    ellipse_boundary_pts(2, :) + center(2), ...
    'color', color);

end