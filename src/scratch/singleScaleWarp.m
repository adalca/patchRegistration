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

    % setup variables
    n = ndims(source);
    
    [patches, pDst, pIdx,~,srcgridsize,refgridsize] = ...
        patchlib.volknnsearch(source, target, patchSize, patchOverlap, ...
        'local', 1, 'location', 0.01, 'K', 9, 'fillK', true);
    
    usemex = exist('pdist2mex', 'file') == 3;
    edgefn = @(a1,a2,a3,a4) patchlib.correspdst(a1, a2, a3, a4, [], usemex); 
    
    [qp, ~, ~, ~, pi] = ...
            patchlib.patchmrf(patches, srcgridsize, pDst, patchSize, patchOverlap, 'edgeDst', edgefn, ...
            'lambda_node', 0.1, 'lambda_edge', 0.1, 'pIdx', pIdx, 'refgridsize', refgridsize);
        
    idx = patchlib.grid(size(source), patchSize, patchOverlap);
    disp = patchlib.corresp2disp(size(source), refgridsize, pi, 'srcGridIdx', idx, 'reshape', true);
    disp = patchlib.interpDisp(disp, patchSize, patchOverlap, size(source)); % interpolate displacement
    for i = 1:numel(disp), disp{i}(isnan(disp{i})) = 0; end

    final = volwarp(source, disp, 'interpmethod', 'nearest');
        
    if(verbose)
        assert(n == 2 || n == 3, 'Dimension incorrect for verbose. Can only use verbose with 2D or 3D');
        
        patchview.figure();
        drawWarpedImages(source, target, final, disp); 
        view3Dopt(source, target, final, disp{:});
    end   
end



