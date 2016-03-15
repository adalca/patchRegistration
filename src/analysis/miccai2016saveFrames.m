function miccai2016saveFrames(rgbImages, filename)

    for imnr = 1:size(rgbImages, 4)
        imwrite(rgbImages(:, :, :, imnr), sprintf(filename, imnr));
    end