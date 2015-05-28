function [I_2, I_DX, I_DY] = ball2D(I_1, varargin)
    
    % initiate figure
    nRows = 2; % the number of slices shown
    patchview.figure(); 
    
    % setup variables
    W = size(I_1, 1);
    H = size(I_1, 2);
    
    % create a ball of ones in the center of the displacement images for x
    % and y; 
    radius = 5;
    
    [xx, yy] = meshgrid(1:W, 1:H);
    I_DX = sqrt((xx-W/2).^2+(yy-W/2).^2)<=radius;   
    I_DY = I_DX;
    
    % warp the image I_1 according to the I_Ds to create I_2
    I_2 = volwarp(I_1, {I_DX, I_DY}, 'interpmethod', 'nearest');
         
    % show the original image, the final image, and the two displacement
    % images
    ims = {I_1, I_2, I_DX, I_DY, ...
        I_1, I_2, I_DX, I_DY,...
        I_1, I_2, I_DX, I_DY};
    titles = {'original image', 'simulated image', 'X displacement image', 'Y displacement image'};
    if(~isempty(varargin))
        examples_drawRow(nRows, ims, titles);
    end
end



