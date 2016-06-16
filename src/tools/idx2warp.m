function [warp, griddisp] = idx2warp(pIdx, srcSize, patchSize, srcPatchOverlap, refgridsize, nanlocs)
% IDX2WARP translate (reference) index locations to a full-volume warp
%   warp = idx2Warp(pIdx, srcSize, patchSize, srcPatchOverlap, refGridSize) translate reference
%   index locations (pIdx) to a full src-sized volume warp. pIdx is nLoc x 1.

    % compute the displacement on the grid
    srcgrididx = patchlib.grid(srcSize, patchSize, srcPatchOverlap);
    griddisp = patchlib.corresp2disp(srcSize, refgridsize, pIdx, 'srcGridIdx', srcgrididx, 'reshape', true);
        
    if nargin >= 6
         for i = 1:numel(griddisp)
            griddisp{i}(nanlocs) = nan;
         end
    end
    
    warp = disp2warp(griddisp, srcSize, patchSize, srcPatchOverlap);
end