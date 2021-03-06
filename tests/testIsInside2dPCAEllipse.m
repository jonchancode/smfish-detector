function testIsInside2dPCAEllipse()

% Define some test principal components
covariance = [[3 1]; [1 2];];
[evectors, evalues] = eig(covariance);
principal_components = evectors * evalues;
ellipse_center = [-1 1];

% Create a uniform distribution of points within x,y limits
xlim = [-5, 5];
ylim = [-5, 5];
[X, Y] = meshgrid(xlim(1):xlim(2), ylim(1):ylim(2));

% For each point, check if it's inside or outside. Save results in separate
% lists.
inside_pts = [];
outside_pts = [];
for row = 1:size(Y, 1)
    for col = 1:size(X, 1)
        xy = [X(1, col) Y(row, 1)];
        
        % Check if xy is inside ellipse defined above
        is_inside = isInside2dPCAEllipse(xy, ellipse_center, principal_components);
        
        if is_inside
            inside_pts = [inside_pts; xy;];
        else
            outside_pts = [outside_pts; xy;];
        end
    end
end

% Visualize
visualize = true;
if visualize
    figure;
    gcf;
    ax = gca;
    hold(ax, 'on');
    scatter(ax, inside_pts(:,1), inside_pts(:,2), 'g');
    scatter(ax, outside_pts(:,1), outside_pts(:,2), 'r');
    plotPCAEllipse(ax, ellipse_center, principal_components, 'g');
    hold(ax, 'off');
end

end