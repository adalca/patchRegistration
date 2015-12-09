function  [patches, pDst, pIdx, srcgridsize, refgridsize] = stateDistances(source, target, patchSize, patchOverlap, searchSize, location, varargin)
% As an easy start, we can assume the reference/target grid is dense ('sliding'). It would be nicer
% to change this in the future, but it could be a good start.
%
% patches is nSrcGridPts x prod(patchSize) x prod(searchSize)
%
% Rought outline of algorithm:
%
% compute srcgridsize and refgridsize using patchlib.grid();
% compute the source library (size should be nSrcGridPts x prod(patchSize))
% compute the reference library (size should be nRefGridPts(==nRefSize) x prod(patchSize))
%
% for each point in the source grid
%    get the location in 2D/3D
%    compute all the locations in the reference library within the searchSize
%    transform these locations into a linear index (subvec2ind()) based on the reference grid
%    get the relevant patches from the computed libraries
%    compute all of the patch distances in pDst, and store them into pDst. Note, this storage has 
%       to be in a consistent order for all locations, even edge ones. At the edges, for unavailable
%       patches, e.g. for computation at the edges of the volume, set distance of infinity (I think)
%   also fill in patches array in a consistent matter.
    
    [srcIdx, ~, srcgridsize, ~] = patchlib.grid(size(source), patchSize, patchOverlap);
    [refIdx, ~, refgridsize, ~] = patchlib.grid(size(target), patchSize);
 
    % compute source library
    srcLib = patchlib.vol2lib(source, patchSize, patchOverlap);
    
    % build the reference libraries
    refLib = patchlib.vol2lib(target, patchSize);
    
    K = prod(patchSize);
    pDst = Inf(size(srcLib, 1), K);
    pIdx = ones(size(srcLib, 1), K); % Should be investigated. ones is a hack
    patches = nan(size(srcLib, 1), K, prod(searchSize));
    local = (searchSize(1) - 1)/2;
    srcgridsub = ind2subvec(size(source), srcIdx(:));
    refgridsub = ind2subvec(size(target), refIdx(:));
    
    % for each point in the source grid
    for i = 1:size(srcLib, 1)
        subIdx = srcgridsub(i, :);
        range = {};
        for j = 1:ndims(source)
            range{j} = max(subIdx(j)-local, 1):min(subIdx(j)+local, refgridsize(j));
            assert(~isempty(range{j}));
        end
        refNeighborIdx = ind2ind(size(target), refgridsize, refIdx(range{:}));
        patches(i, 1:size(refLib(refNeighborIdx(:), :), 1), :) = reshape(refLib(refNeighborIdx(:), :), [1 size(refLib(refNeighborIdx(:), :))]);
                        
        % do a pdist2 calculation among the patches and among the neighbors
        d = pdist2(srcLib(i, :), refLib(refNeighborIdx(:), :));
        dNeigh = location * pdist2(subIdx, refgridsub(refNeighborIdx(:), :));
        
        % note we don't use 1:K, instead we use 1:numel(p) since we might allow less than K matches
        pDst(i, 1:size(refLib(refNeighborIdx(:), :), 1)) = d + dNeigh;   
        pIdx(i, 1:size(refLib(refNeighborIdx(:), :), 1)) = refNeighborIdx(:);
    end
end
