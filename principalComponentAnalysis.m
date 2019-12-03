function [components, covariance] = principalComponentAnalysis(X)
% Finds principal components of X. Assumes each row of X is p dimensional
% data point.
%
% Returns 'components', which is a p x p matrix where each column is
% one of the principal components. The length of each component is 1
% standard deviation of the variance being 'explained' by that component.

% Find mean
mean_row = mean(X);

% Compute covariance
zero_mean_X = X - mean_row;
num_samples = size(X, 1);
num_components = size(X, 2);
covariance = (zero_mean_X' * zero_mean_X) / (num_samples - 1);

% Find principal components of covariance matrix with SVD
[~, S, V] = svd(zero_mean_X);

% Extract the square matrix (p x p) of singular values
S = S(1:num_components, 1:num_components);

% Compute the variance explained by each component 
variance_explained = (S * S) / (num_samples - 1);

% Scale the components by the standard deviation (sqrt(variance)).
components = V * sqrt(variance_explained);

end
