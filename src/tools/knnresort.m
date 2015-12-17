function [pDstOrd, pIdxOrd] = knnresort(pDst, pIdx, gridSize, dispPatchSize)

    pDstOrd = zeros(size(pDst));
    pIdxOrd = zeros(size(pDst));
    
    for patchNum = 1:size(pIdx, 1)
        % we'll need a map of where the NaNs are, since the pIdx in these locations are known to be
        % irrelevant
        nanmap = isinf(pDst(patchNum, :));
        
        % Get the subscript for the current patch
        patchNumSub = ind2subvec(gridSize, patchNum);
        
        % Get the subscript for all the state indexes for this patch
        pIdxSub = ind2subvec(gridSize, pIdx(patchNum, :)');
        
        % Get the displacement difference between the patch's subscript and
        % the index states' subscripts, then normalize it with respect to
        % the corner of the displacement cube
        pDiff = bsxfun(@minus, patchNumSub, pIdxSub);
        pDiff = bsxfun(@plus, pDiff, ceil(dispPatchSize/2));
        
        % Get indexes in the displacement cube for all the pDiff
        % coordinates
        pDiffIndx = subvec2ind(dispPatchSize, pDiff(~nanmap, :));
        
        pDiffInd = zeros(size(pDst, 2), 1); 
        pDiffInd(~nanmap) = pDiffIndx;
        pDiffInd = completerow(pDiffInd, nanmap);
        
        % Sort these indexes to get the arrangement of pDiffInd into the
        % sorted array
        [~, ci] = sort(pDiffInd);
        pDstOrd(patchNum, :) = pDst(patchNum, ci);
        pIdxOrd(patchNum, :) = pIdx(patchNum, ci);
    end
    
    pIdxOrd = fliplr(pIdxOrd);
    pDstOrd = fliplr(pDstOrd);
end
        
    

function pIdxRow = completerow(pIdxRow, nanmask)
% fill in any NaNs in pIdx with the missing values in that row, assuming each row must have values
% in the range of 1:size(pIdx, 2)
    setv = 1:numel(pIdxRow);
    x = setdiff(setv, pIdxRow);
    pIdxRow(nanmask) = x;
end
