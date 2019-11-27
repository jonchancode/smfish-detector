% Process one easy image
img_path = 'images\cell 19_opn4_enhanced.tif';
processImage(img_path, false);

% Process all of the images
img_dir_path = 'images';
img_files = dir(img_dir_path);

% Whether or not to save the intermediate images
save_intermediate_images = true;

% Loop through all the images and processImage
% Start at 3 because 1 and 2 are '.' and '..'
for i = 3:size(img_files, 1)
    
    img_file = img_files(i);
    img_path = fullfile(img_file.folder, img_file.name);
    
    % Process the image
    processImage(img_path, save_intermediate_images);
    
    % Wait for a click or button press before moving on to next image
    if ~save_intermediate_images
        waitforbuttonpress;
    end
end
