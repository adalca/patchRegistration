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
    gridAndW1 = cellfunc(@plus, grid, warp1);
    
    % get the displacement values in the refrence frame of the second warp
    % image
    deltaW = cellfunc(@(x) interpn(grid{:}, x, gridAndW1{:}), warp2);
    
    % get the overall warp displacement in the reference frame of the first
    % warp image
    finalW = cellfunc(@plus, deltaW, warp1);
end
