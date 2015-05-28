function [I_2, I_DX, I_DY, I_DZ] = ball3D(I_1, varargin)
    
    % initiate figure
    nRows = 3; % the number of slices shown
    patchview.figure(); 
    
    % setup variables
    W = size(I_1, 1);
    H = size(I_1, 2);
    D = size(I_1, 3);
    
    % create a ball of ones in the center of the displacement images for x
    % and y; z stays 0
    I_DZ = zeros(W, H, D);
    radius = 6;
    
    [xx, yy, zz] = ndgrid(1:W, 1:H, 1:D);
    I_DX = sqrt((xx-W/2).^2+(yy-H/2).^2+(zz-D/2).^2)<=radius; 
    I_DX = I_DX + (sqrt((xx-W/2).^2+(yy-H/2).^2+(zz-D/2).^2)<=radius/2);  
    I_DY = I_DX;
    
    % warp the image I_1 according to the I_Ds to create I_2
    I_2 = volwarp(I_1, {I_DX, I_DY, I_DZ}, 'interpmethod', 'nearest');
         
    % show the original image, the final image, and the two displacement
    % images
    ims = {I_1(:, :, 2), I_2(:, :, 2), I_DX(:, :, 2), I_DY(:, :, 2), I_DZ(:, :, 2), ...
        I_1(:, :, 11), I_2(:, :, 11), I_DX(:, :, 11), I_DY(:, :, 11), I_DZ(:, :, 11),...
        I_1(:, :, 20), I_2(:, :, 20), I_DX(:, :, 20), I_DY(:, :, 20), I_DZ(:, :, 20)};
    titles = {'original image', 'simulated image', 'X displacement image', 'Y displacement image', 'Z displacement image'};
    if(~isempty(varargin))
        examples_drawRow(nRows, ims, titles);
    end
end



