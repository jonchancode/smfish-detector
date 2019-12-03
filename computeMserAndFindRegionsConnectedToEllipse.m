function [region_map, pixels_of_connected_regions] = computeMserAndFindRegionsConnectedToEllipse(byte_img, ellipse_center, principal_components)
% Returns:
%
% region_map:
%   A new 'image' the same size as byte_img where each pixel is an integer 
%   representing how many regions it belongs to.
%
%   Can be thought of like an elevation map, where the integer of each pixel
%   is the height at that position. The "higher" the pixel, the the closer to
%   the peak/center of the region you are.
%
% pixels_of_connected_regions:
%   The pixels (x,y positions) of the regions that are connected to the
%   ellipse. Is an Nx2 matrix, where each row is an (x,y) position.
%

% Zero initialize output variables
region_map = zeros(size(byte_img));
pixels_of_connected_regions = [];

% Run MSER to flood fill the regions. Each region_seed is the index of a
% pixel that belongs to a region.
[region_seeds, ~] = vl_mser(byte_img);

% Keep a dictionary of pixels we've already counted as an inlier
indices_of_inlier_region_pixels = containers.Map(...
    'KeyType', 'int32', ...
    'ValueType', 'logical');


% Loop through each region_seed, and use vl_erfill at the seed to get the
% list of pixels in that region.
for region_seed = region_seeds'
    % Flood fill the region given by the seed
    indices_of_pixels_in_filled_region = vl_erfill(byte_img, region_seed);
    
    % Increment the num_regions_per_pixel to represent that this
    % set of pixels belongs to one additional region.
    region_map(indices_of_pixels_in_filled_region) = ...
        region_map(indices_of_pixels_in_filled_region) + 1;
    
    % Figure out if any pixel in this region is inside the inlier
    % ellipse
    region_overlaps_ellipse = false;
    for idx = indices_of_pixels_in_filled_region'

        % Check if we've already found this pixel to be connected to the
        % ellipse during the evaluation of a region from a previous
        % iteration.
        is_pixel_connected_to_ellipse = indices_of_inlier_region_pixels.isKey(idx);
        if is_pixel_connected_to_ellipse
            % If this pixel was found to be connected in the past, then
            % this whole region must be connected to the ellipse as well.
            %
            % Can exit this loop.
            region_overlaps_ellipse = true;
            break;
        end
        
        % This is a pixel we've never seen before. Check if it's inside the
        % ellipse.
        [row, col] = ind2sub(size(byte_img), idx);
        if isInside2dPCAEllipse(...
                [col row], ...
                ellipse_center, ...
                principal_components)
            
            % This pixel is inside the ellipse. Thus this region must
            % overlap.
            % Can exit this loop.
            region_overlaps_ellipse = true;
            break;
        end
        
    end % for indices_of_pixels_in_filled_region
    
    if region_overlaps_ellipse
        % Add all the pixels in this region to our list
        for idx = indices_of_pixels_in_filled_region'
            
            if indices_of_inlier_region_pixels.isKey(idx)
                % Skip if we've already recorded this pixel
                continue;
            end
            
            % Add the xy position of the pixel
            [row, col] = ind2sub(size(byte_img), idx);
            pixels_of_connected_regions = [pixels_of_connected_regions; [col row];];
            
            % Mark that we've seen this pixel now
            indices_of_inlier_region_pixels(idx) = true;
        end

    end % if region_overlaps_ellipse
    
end % for region_seeds

end