function [I_2, I_D] = randShift(vol, sigma, verbose)
    % This function creates a n-dimentional random displacement image, where `n = ndims(vol)`, 
    % and apply the displacement to `vol`. 
    %
    % 'sigma' is the sigma value to apply to the gaussian blur
    %
    % `verbose` is a `logical` on whether to display the results or not (only applicable if n == 2 or n == 3).
    
    
    % setup variables
    n = ndims(vol);
    s = size(vol);
    I_1 = vol;
    maxDisp = 2;
    maxDist = 2;
    
    % create the two displacement images with gaussian blur
    I_D = arrayfunc(@(x) (round(volblur((rand(s)*(maxDisp*2)-maxDist), sigma))), s);
    
    % warp the image I_1 according to the I_Ds to create I_2
    I_2 = volwarp(I_1, I_D, 'interpmethod', 'nearest');
         
    % show the original image, the final image, and the two displacement
    % images
    if(verbose)
        assert(n == 2 || n == 3, 'Dimension incorrect for verbose. Can only use verbose with 2D or 3D');
        
        % initiate figure
        nRows = n; % the number of slices shown
        patchview.figure(); 

        % show the original image, the final image, and the two displacement images
        if n == 2
            ims = {I_1, I_2, I_D{1}, I_D{2}, ...
            I_1, I_2, I_D{1}, I_D{2},...
            I_1, I_2, I_D{1}, I_D{2}};
            titles = {'original image', 'simulated image', 'X displacement image', 'Y displacement image'};
        elseif n == 3
            ims = {I_1(:, :, 2), I_2(:, :, 2), I_D{1}(:, :, 2), I_D{2}(:, :, 2), I_D{3}(:, :, 2), ...
                I_1(:, :, 11), I_2(:, :, 11), I_D{1}(:, :, 11), I_D{2}(:, :, 11), I_D{3}(:, :, 11),...
                I_1(:, :, 20), I_2(:, :, 20), I_D{1}(:, :, 20), I_D{2}(:, :, 20), I_D{3}(:, :, 20)};
            titles = {'original image', 'simulated image', 'X displacement image', 'Y displacement image', 'Z displacement image'};
        end
        examples_drawRow(nRows, ims, titles);
    end
end



