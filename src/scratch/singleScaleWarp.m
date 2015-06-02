function [disp] = singleScaleWarp(source, target, patchSize, patchOverlap, verbose)
%Run patchlib.volknnsearch and lib2patches to get mrf unary potentials automatically. 
%Then call patchmrf and use patchlib.correspdst for the pair potentials. 
%Then repeat
%
% 'source' is the source(moving) image 
% 'target' is the target image
% 'patchSize' is the size of the patch
% 'patchOverlap' can be 'sliding' or 'half'
% 'verbose' if true, will draw the images (source, target,
% displacement, final) for 2D and 3D
%
% Important Notes:
% - note that patchlib sets up patches in the top left of the patches, whereas we want to "move" the
% center of the patches. Thus, we can either use trimarray and padarray after we get the full
% displacement, or use interpDisp with a shift.   
%
% TODO: 
% - Combine this code with Adrian's original code. 
% - Allow for 'volknnparams' which are a combination of the default params plus any params passed in. 

    % setup variables
    n = ndims(source);
    usemex = exist('pdist2mex', 'file') == 3;
    edgefn = @(a1,a2,a3,a4) patchlib.correspdst(a1, a2, a3, a4, [], usemex); 
    
    % get optimal patch movements via knnsearch and patchmrf.
    [patches, pDst, pIdx,~,srcgridsize,refgridsize] = ...
        patchlib.volknnsearch(source, target, patchSize, patchOverlap, ...
        'local', 1, 'location', 0.01, 'K', 9, 'fillK', true);
    [~, ~, ~, ~, pi] = ...
            patchlib.patchmrf(patches, srcgridsize, pDst, patchSize, patchOverlap, 'edgeDst', edgefn, ...
            'lambda_node', 0.1, 'lambda_edge', 0.1, 'pIdx', pIdx, 'refgridsize', refgridsize);
    
    % compute the displacement on the grid
    idx = patchlib.grid(size(source), patchSize, patchOverlap);
    griddisp = patchlib.corresp2disp(size(source), refgridsize, pi, 'srcGridIdx', idx, 'reshape', true);
    
    % interpolate to a full displacement 
    % shift by (patchSize-1)/2 to put the displacement in the center of the patches
    disp = patchlib.interpDisp(griddisp, patchSize, patchOverlap, size(source), (patchSize - 1)/2); 
    assert(all(cellfun(@(d) all(size(d) == size(source)), disp)));
    for i = 1:numel(disp), disp{i}(isnan(disp{i})) = 0; end % TODO: check that this doesn't happen often.
    
    % display / view warp.
    if(verbose)
        warpedSource = volwarp(source, disp, 'interpmethod', 'nearest');
        
        assert(n == 2 || n == 3, 'Dimension incorrect for verbose. Can only use verbose with 2D or 3D');
        
        patchview.figure();
        drawWarpedImages(source, target, warpedSource, disp); 
        view3Dopt(source, target, warpedSource, disp{:});
    end   
end
