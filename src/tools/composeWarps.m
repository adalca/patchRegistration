function finalW = composeWarps(warp1, warp2)
% Calculates the composition of two forward warps: warp1 is the displacement
% from image A to B; warp 2 is the displacement from image B to C;
% finalWarp is the overall A->C displacement
%
% TODO: composition of backward warp. composition. 
% TODO: inverse warps. Think of all of these files.
    
    % get a normal ndgrid
    grid = size2ndgrid(size(warp1{1}));
    
    % add the grid and the first warp to get the predicted positions
    % gridAndW1 is actually the position at which each voxel should move.
    % And I will rename the variable to show this :)
    gridAndW1 = cellfunc(@plus, grid, warp1);
    
    % get the displacement values in the refrence frame of the second warp
    % image
    deltaW = cellfunc(@(x) interpn(grid{:}, x, gridAndW1{:}), warp2);
    
    % correct any NANs in the displacements. 
    % Usually these happen at the edges due to silly interpolations.
    nNANs = sum(cellfun(@(x) sum(isnan(x(:))), deltaW));
    if nNANs > 0
        warning('ComposeWarps: found %d NANs. Transforming them to 0s', nNANs);
        for i = 1:numel(deltaW), 
            deltaW{i}(isnan(deltaW{i})) = 0; 
        end
    end
    
    % get the overall warp displacement in the reference frame of the first
    % warp image
    finalW = cellfunc(@plus, deltaW, warp1);
    assert(isclean([finalW{:}]));
end
