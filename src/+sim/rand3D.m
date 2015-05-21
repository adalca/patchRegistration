function [I_2, I_DX, I_DY, I_DZ] = rand3D(I_1, varargin)
    
    % initiate figure
    nRows = 3; % the number of slices shown
    patchview.figure(); 
    
    % setup variables
    maxDisp = 4;
    maxDist = 4;
    W = size(I_1, 1);
    H = size(I_1, 2);
    D = size(I_1, 3);
    
    % create the two displacement images with gaussian blur
    sigma = 1;
    I = (rand(W, H, D)*(maxDisp*2)-maxDist);
    I_DX = (volblur(I, sigma));
    I = (rand(W, H, D)*(maxDisp*2)-maxDist);
    I_DY = (volblur(I, sigma));
    I = (rand(W, H, D)*(maxDisp*2)-maxDist);
    I_DZ = (volblur(I, sigma));
    
    % warp the image I_1 according to the I_Ds to create I_2
    I_2 = iminterpolate3D(I_1, I_DX, I_DY, I_DZ);

         
    % show the original image, the final image, and the two displacement
    % images
    ims = {I_1(:, :, 2), I_2(:, :, 2), I_DX(:, :, 2), I_DY(:, :, 2), I_DZ(:, :, 2), ...
        I_1(:, :, 11), I_2(:, :, 11), I_DX(:, :, 11), I_DY(:, :, 11), I_DZ(:, :, 11),...
        I_1(:, :, 20), I_2(:, :, 20), I_DX(:, :, 20), I_DY(:, :, 20), I_DZ(:, :, 20)};
    titles = {'original image', 'final image', 'X displacement image', 'Y displacement image', 'Z displacement image'};
    if(~isempty(varargin))
        examples_drawRow(nRows, ims, titles);
    end
end



