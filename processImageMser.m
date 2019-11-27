function processImageMser(img_path)

% Load the image as byte image
byte_img = imread(img_path);

% Run MSER
[regions, frames] = vl_mser(byte_img);

% Visualize MSER
visualize_mser = false;
if visualize_mser
    mser_frames_transposed = vl_ertr(frames);
    hold on;
    imshow(byte_img);
    vl_plotframe(mser_frames_transposed);
    hold off;
end

end