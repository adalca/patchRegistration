function [I_2, I_D] = ovoidShift(vol, radius, verbose)
    % This function creates a n-dimentional displacement ball, where `n = ndims(vol)`, 
    % and apply the displacement to `vol`. 
    %
    % `radius` is a scalar in (0, inf), or a vector of size 1 x n where each entry is (0, inf). 
    % If it's a scalar, then: 
    %   (1) if radius in (0, 1) indicates a fractional radius with respect to the size of the volume; 
    %   (2) if radius is in [1, inf), then the radius is assumed to be given in actual units. 
    % If radius is a vector, then each displacement volume gets its own radius. 
    %
    % `verbose` is a `logical` on whether to display the results or not (only applicable if n == 2 or n == 3).
    
    
    % setup variables
    n = ndims(vol);
    s = size(vol);
    if isscalar(radius)
        if radius < 1
            radius = arrayfun(@(x) x*radius, s);
        else
            radius = ones(1,n) * radius;
        end
    end
    I_1 = vol;
    
    % create a ball of ones and twos in the center of the displacement images 
    outGrid = size2ndgrid(s);  % ndgrid of all 1:dim in s
    cent = arrayfunc(@(x) (outGrid{x}-size(outGrid{1},x)/2).^2, 1:n); % compute the deltaSquared
    oneMoreCent = cat(n+1, cent{:}); % concatenate all n dimension cells in n+1 dimmension cell
    distancesGrid = sqrt(sum(oneMoreCent, n+1)); % collapse the n+1 dimmension cell in n dimmension array of distances
    I_D = arrayfunc(@(x) (distancesGrid<=x), radius); % final distance ball matrix
    
    % warp the image I_1 according to the I_Ds to create I_2
    I_2 = volwarp(I_1, I_D, 'interpmethod', 'nearest');
     
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



