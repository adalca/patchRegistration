function warp = disp2warp(griddisp, srcSize, patchSize, srcPatchOverlap)
% DISP2WARP translate a displacement (on a grid) to a warp (on the whole image).
%   warp = disp2warp(griddisp, srcSize, patchSize, srcPatchOverlap) trnslate a displacement field
%   (given on a grid) to a full-volume warp (or displacement) field. 
%
% Here, displacement or warps are sort of interchangable, but as a convention a warp is defined on
% the whole volume. We should probably clean this up.

    % interpolate to a full displacement 
    % shift by (patchSize-1)/2 to put the displacement in the center of the patches
    assert(all(isodd(patchSize)));
    warp = patchlib.interpDisp(griddisp, patchSize, srcPatchOverlap, srcSize, (patchSize - 1)/2); 
    assert(all(cellfun(@(d) all(size(d) == srcSize), warp)));
    
    % correct any NANs in the displacements. 
    % Usually these happen at the edges
    nNANs = sum(cellfun(@(x) sum(isnan(x(:))), warp));
    nElems = sum(cellfun(@(x) numel(x), warp));
    if nNANs > 0
        q = dbstack();
        warning('%s: Found %d (%3.2f%%) NANs. Inpainting.', q(1).name, nNANs, nNANs/nElems * 100);
        
        % warning: setting the nans to 0 is not correct. Using inpainting.
        warp = cellfunc(@inpaintn, warp);
    end   
end