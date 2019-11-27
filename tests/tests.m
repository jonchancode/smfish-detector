function tests()

testPrincipalComponentAnalysis()

end


function testPrincipalComponentAnalysis()

% Generate test data
X = nan(50, 2);
variance = [[2 1]; [1 1];];

for i = 1:size(X, 1)
    rand_pt = (variance * rand(2,1));
    X(i,:) = rand_pt';
%     for j = 1:size(X, 2)
%         X(i,j) = variance(j) * rand();
%     end
end

% Run PCA
[components, covariance] = principalComponentAnalysis(X)

% Visualize
visualize = true;
if visualize
    hold on;
    scatter(X(:,1), X(:,2));
    mean_pt = mean(X);
    mean_X = [mean_pt; mean_pt];
    quiver(mean_X(:,1), mean_X(:,2), components(:,1), components(:,2));
    xlim([0 3]);
    ylim([0 3]);
    hold off;
end

end