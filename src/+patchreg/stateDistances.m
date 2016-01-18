function  [patches, pDst, pIdx, srcgridsize, refgridsize] = stateDistances(source, target, patchSize, patchOverlap, searchSize, locweight, distanceMetric, varargin)
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
    
    nDims = ndims(source);

    [srcIdx, ~, srcgridsize, ~] = patchlib.grid(size(source), patchSize, patchOverlap);
    [refIdx, ~, refgridsize, ~] = patchlib.grid(size(target), patchSize);
 
    % compute source library
    srcLib = patchlib.vol2lib(source, patchSize, patchOverlap);
    
    % build the reference libraries
    refLib = patchlib.vol2lib(target, patchSize);
    
    P = prod(patchSize);
    K = prod(searchSize);
    pDst = Inf(size(srcLib, 1), K);
    pIdx = ones(size(srcLib, 1), K); % Should be investigated. ones is a hack
    patches = nan(size(srcLib, 1), P, prod(searchSize));
    local = (searchSize(1) - 1)/2;
    srcgridsub = ind2subvec(size(source), srcIdx(:));
    refgridsub = ind2subvec(size(target), refIdx(:));
    
    % parse optional inputs
    if(numel(varargin) == 2)
        srcMask = varargin{1};
        refMask = varargin{2};

        % compute source mask library
        srcMaskLib = patchlib.vol2lib(srcMask, patchSize, patchOverlap);

        % build the reference mask libraries
        refMaskLib = patchlib.vol2lib(refMask, patchSize);
    end
    
    % for each point in the source grid
    for i = 1:size(srcLib, 1)
        subIdx = srcgridsub(i, :);
        range = cell(1, nDims);
        for j = 1:nDims
            range{j} = max(subIdx(j)-local, 1):min(subIdx(j)+local, refgridsize(j));
            assert(~isempty(range{j}));
        end
        
        % tranform indexes from target space to reference index.
        refNeighborIdx = ind2ind(size(target), refgridsize, refIdx(range{:}));
        refNeighborIdx = refNeighborIdx(:);
        nNeighbors = numel(refNeighborIdx);
        
        % get and store the neighbor patches
        neighborPatches = refLib(refNeighborIdx, :);
        patches(i, :, 1:nNeighbors) = reshape(neighborPatches, [1, P, nNeighbors]);
        if(numel(varargin)==2)
            neighborMaskPatches = refMaskLib(refNeighborIdx, :);
        end
                        
        % patch intensity distance of current patch to neighbors
        % normal pdist2:
        switch distanceMetric
            case 'euclidean'
                d = pdist2(srcLib(i, :), neighborPatches);
                
            case 'seuclidean'
                % relative pdist2:
                avg = bsxfun(@plus, srcLib(i, :), neighborPatches) / 2 + eps;
                d = sum((bsxfun(@times, srcLib(i, :), 1./avg) - neighborPatches./avg) .^2, 2)';
            case 'sparse'
                % distance function for sparse data
                patchDifference = bsxfun(@minus, srcLib(i, :), neighborPatches) .^2 + eps;
                productMask = bsxfun(@times, srcMaskLib(i, :), neighborMaskPatches) + eps;
                numeratorD = sum(productMask .* patchDifference, 2)';
                denominatorD = sum(productMask, 2)';
                d = bsxfun(@times, numeratorD, prod(patchSize)./denominatorD) .^ 0.5;
            otherwise
                error('unknown distance metric');
        end
        
        % compute spatial distance of current location to neighbors
        dNeigh = locweight * pdist2(subIdx, refgridsub(refNeighborIdx, :));
        
        % note we don't use 1:K, instead we use 1:numel(p) since we might allow less than K matches
        pDst(i, 1:nNeighbors) = d + dNeigh;   
        pIdx(i, 1:nNeighbors) = refNeighborIdx;
    end
end

