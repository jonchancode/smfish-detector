function testPrincipalComponentAnalysis()

% Generate random test data with a normal distribution given by
% 'covariance' and centered around 'offset'
rng(42);
X = zeros(50, 2);
covariance = [[3 1]; [1 2];];
% covariance = eye(2);
offset = [3 -2];

for i = 1:size(X, 1)
    rand_pt = (covariance * randn(2,1)) + offset';
    X(i,:) = rand_pt';
end

% Use hard coded test data
% X = [[2, 1]; [-3, 1]; [2, -4]; [1, -1]; [0, 2]; [-1, 3]; [2, -1];];

% Run PCA
[components, pca_covariance] = principalComponentAnalysis(X)

% Verify
assert(components(:,1)' * components(:,2) == 0, 'Columns of components should be orthogonal');
assert(norm(components(:,1)) > norm(components(:,2)), 'Variances/components should be ordered from largest to smallest');

% Visualize
visualize = true;
if visualize
    clf;
    ax = gca;
    
    hold on;
    
    min_val = min(X(:));
    max_val = max(X(:));
    limits = [min_val - 2, max_val + 2];
    xlim(limits);
    ylim(limits);
    
    mean_pt = mean(X);
    mean_X = repmat(mean_pt, 2, 1);
    quiver(...
        ax, ...
        mean_X(:,1), ...
        mean_X(:,2), ...
        components(1,:)', ...
        components(2,:)');
    
    scatter(ax, X(:,1), X(:,2));
    
    plotCovarianceEllipse(...
        ax, ...
        mean_pt, ...
        pca_covariance, ...
        1 - exp(-0.5), ...
        'g');
    
    plotPCAEllipse(...
        ax, ...
        mean_pt, ...
        components, ...
        'r');
    
    hold off;
end

end