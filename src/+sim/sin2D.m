function [I_2] = sin2D(I_1, varargin)
    
    % initiate figure
    nRows = 1; % the number of rows of images shown
    patchview.figure(); 
    
    % setup variables
    W = size(I_1, 1);
    H = size(I_1, 2);
    
    % create a sliced 2D image starting from the original one
   
    for i=1:W
        for j=1:H
            I_2(i,j) = I_1(i,j)*sin(double(i/5))^10;
        end
    end
         
    % show the original image, the final image, and the two displacement
    % images
    ims = {I_1, I_2}
    titles = {'original image', 'simulated image'};
    if(~isempty(varargin))
        examples_drawRow(nRows, nRows, ims, titles);
    end
end



