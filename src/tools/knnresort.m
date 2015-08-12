function pDstOrd = knnresort(pDst, pIdx, gridSize, dispPatchSize)
    pDstOrd = zeros(size(pDst));
    for patchNum = 1:size(pIdx, 1)
        % Get the subscript for the current patch
        patchNumSub = ind2sub(gridSize, patchNum);
        
        % Get the subscript for all the state indexes for this patch
        pIdxSub = ind2subvec(gridSize, pIdx(patchNum, :)');
        
        % Get the displacement difference between the patch's subscript and
        % the index states' subscripts, then normalize it with respect to
        % the corner of the displacement cube
        pDiff = bsxfun(@minus, pIdxSub, patchNumSub);
        pDiff = bsxfun(@plus, pDiff, ceil(size(dispPatchSize)/2));
        
        % Get indexes in the displacement cube for all the pDiff
        % coordinates
        pDiffInd = subvec2ind(dispPatchSize, pDiff);
        
        % Sort these indexes to get the arrangement of pDiffInd into the
        % sorted array
        [~, ci] = sort(pDiffInd);
        pDstOrd(patchNum, :) = pDst(patchNum, ci);
    end
end
        
    
