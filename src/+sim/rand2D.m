function rand2D(I_1, varargin)
    % initiate figure
    nRows = 1;
    patchview.figure(); 
    
    % setup variables
    maxDisp = 2;
    maxDist = 2;
    W = size(I_1, 1);
    H = size(I_1, 2);
    
    I_2 = zeros(H, W);
    I = (rand(W,H)*(maxDisp*2)-maxDist);
    
    % create the two displacement images with gaussian blur
    sigma = 1;
    I_DX = round(volblur(I, sigma));
    I_DY = round(volblur(I, sigma)); 
    
    % warp the image I_1 according to the I_Ds to create I_2
    I_2 = volwarp(I_1, {I_DX, I_DY});
      
    % show the original image, the final image, and the two displacement
    % images
    ims = {I_1, I_2, I_DX, I_DY};
    titles = {'original image', 'final image', 'X displacement image', 'Y displacement image'};
    examples_drawRow(nRows, ims, titles)
end



