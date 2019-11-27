function [components, covariance] = principalComponentAnalysis(X)
% Finds principal components of X. Assumes each row of X is a data point,
% and each column is the dimension of interest.

% Find mean
mean_row = mean(X);

% Compute covariance
zero_mean_X = X - mean_row;
N = size(X, 1);
covariance = (zero_mean_X' * zero_mean_X) / (N - 1);

% Find principal components of covariance matrix with SVD
[U, S, ~] = svd(covariance);
components = S * U;

end
