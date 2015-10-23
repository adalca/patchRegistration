function [I_2] = sin2D(I_1, angle, sparcity, varargin)
    % I_1 is the image to slice
    
    % angle is the angle of the slices
    
    % sparcity is how sparce the slices should be cut; the larger the
    % sparcity, the more slices will be cut
    
    % varargin determines whether or not to plot the result

    
    
    % initiate figure
    nRows = 1; % the number of rows of images shown
    patchview.figure(); 
    
    % setup variables
    W = size(I_1, 1);
    H = size(I_1, 2);
    
    % create a sliced 2D image starting from the original one
    % first create the mask for it
    I_D = zeros(2*W, 2*H);
    
    for i=1:2*W
        for j=1:2*H
            I_D(i, j) = sin(double(i/sparcity))^10;
        end
    end
    I_D = imrotate(I_D, angle, 'crop');
    [cropM, ~, ~] = cropMask([2*W, 2*H], [W, H]);
    I_D = reshape(I_D(cropM), W, H);
    
    % then apply the mask to the image
    I_2 = I_1.*I_D;
    
    % show the original image, the final image, and the two displacement
    % images
    ims = {I_1, I_D, I_2}
    titles = {'original image', 'mask', 'simulated image'};
    if(~isempty(varargin))
        examples_drawRow(nRows, nRows, ims, titles);
    end
end



