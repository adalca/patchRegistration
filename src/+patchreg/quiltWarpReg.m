function warp = quiltWarpReg(srcSize, pDst, pIdx, patchSize, patchOverlap, srcgridsize, searchSize, alpha, dstmethod)
% "quilt" warp regularizer - a heuristic devised in the summer of 2015. 
% not supported anymore, really.
% this needs to be looked at.

    % first try for second method:
    [pDstOrd, pIdxOrd] = knnresort(pDst, pIdx, srcgridsize, searchSize);
    nodePot = exp(-alpha * pDstOrd); 
    nodePot = bsxfun(@times, nodePot, 1./sum(nodePot, 2));    
    
    piver = stateDispQuilt(nodePot, searchSize, patchOverlap, srcgridsize);
    
    pisub = bsxfun(@minus, ind2subvec(searchSize, piver(:)), ceil(searchSize/2));
    pisub = -pisub; % since we're doing the warp in the other direction.
    piwarp = cellfunc(@(x) reshape(x, srcSize), dimsplit(2, pisub));
    
    % the warp probably needs to be shifted in the same manner that it is for mrfwarp
    % since we want to match center points, not top-left points
    % perhaps go from (-piver) --> pIdxNew and all patchreg.idx2Warp?
    piwarp = cellfunc(@(x) cropVolume(x, srcgridsize), piwarp);
    warp = disp2warp(piwarp, srcSize, patchSize, patchOverlap);
end