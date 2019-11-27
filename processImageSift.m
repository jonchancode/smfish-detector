function processImageSift(img_path)

% Load the image and convert to single precision floating point image
byte_img = imread(img_path);
single_img = im2single(byte_img);

% Run SIFT
[frames, ~] = vl_sift(single_img);

% Visualize SIFT
visualize_sift = false;
if visualize_sift
    hold on;
    imshow(single_img);
    vl_plotframe(frames);
    hold off;
end

end