function [components, covariance, variance_explained] = principalComponentAnalysis(X)
% Finds principal components of X. Assumes each row of X is a data point,
% and each column is the dimension of interest.

% Find mean
mean_row = mean(X);

% Compute covariance
zero_mean_X = X - mean_row;
num_samples = size(X, 1);
num_components = size(X, 2);
covariance = (zero_mean_X' * zero_mean_X) / (num_samples - 1);

% Find principal components of covariance matrix with SVD
[~, S, V] = svd(zero_mean_X);

S = S(1:num_components, 1:num_components);

variance_explained = diag((S * S) / (num_samples - 1));

components = V;
% components(:,1) = components(:,1) * variance_explained(1);
% components(:,2) = components(:,2) * variance_explained(2);

end
