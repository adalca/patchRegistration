function  [patches, pDst, pIdx, srcgridsize, refgridsize] = stateDistances(vols, params)
% As an easy start, we can assume the reference/fixed grid is dense ('sliding'). It would be nicer
% to change this in the future, but it could be a good start.
%
% patches is nSrcGridPts x prod(patchSize) x prod(searchSize)
%
% Rought outline of algorithm:
%
% compute srcgridsize and refgridsize using patchlib.grid();
% compute the moving library (size should be nSrcGridPts x prod(patchSize))
% compute the reference library (size should be nRefGridPts(==nRefSize) x prod(patchSize))
%
% for each point in the moving grid
%    get the location in 2D/3D
%    compute all the locations in the reference library within the searchSize
%    transform these locations into a linear index (subvec2ind()) based on the reference grid
%    get the relevant patches from the computed libraries
%    compute all of the patch distances in pDst, and store them into pDst. Note, this storage has 
%       to be in a consistent order for all locations, even edge ones. At the edges, for unavailable
%       patches, e.g. for computation at the edges of the volume, set distance of infinity (I think)
%   also fill in patches array in a consistent matter.
    
    % load some params for easier access
    patchSize = params.patchSize;
    patchOverlap = params.patchOverlap;
    searchSize = params.searchSize;
    nDims = ndims(vols.moving);
    domask = isfield(vols, 'movingMask') && strcmp(params.dist.metric, 'sparse');

    [srcIdx, ~, srcgridsize, ~] = patchlib.grid(size(vols.moving), patchSize, patchOverlap);
    [refIdx, ~, refgridsize, ~] = patchlib.grid(size(vols.fixed), patchSize);
    
    % compute full libraries if necessary
    if strcmp(params.dist.libraryMethod, 'full')
        % compute moving library
        movLib = patchlib.vol2lib(vols.moving, patchSize, patchOverlap);
        % build the reference libraries
        fixLib = patchlib.vol2lib(vols.fixed, patchSize);
        
        % parse optional inputs
        if domask
            % compute moving mask library
            movMaskLib = patchlib.vol2lib(vols.movingMask, patchSize, patchOverlap);
            % build the reference mask libraries
            fixMaskLib = patchlib.vol2lib(vols.fixedMask, patchSize);
        end
    end
    
    K = prod(searchSize);
    pDst = Inf(numel(srcIdx), K);
    pIdx = ones(numel(srcIdx), K); % Should be investigated. ones is a hack
    patches = nan(numel(srcIdx), 1, prod(searchSize)); % We never use the patches in this case. The second argument should be P, but we're putting 1 for memory win.
    local = (searchSize(1) - 1)/2 .* params.searchGridSize;
    srcgridsub = ind2subvec(size(vols.moving), srcIdx(:));
    refgridsub = ind2subvec(size(vols.fixed), refIdx(:));
    
    % for each point in the moving grid
    for i = 1:numel(srcIdx)
        srcsubi = srcgridsub(i, :);
            
        range = cell(1, nDims);
        for j = 1:nDims
            range{j} = max(srcsubi(j)-local, 1):params.searchGridSize:min(srcsubi(j)+local, refgridsize(j));
            assert(~isempty(range{j}));
        end
        rangeNumbers = ndgrid2vec(range{:});
        
        % tranform indexes from fixed space to reference index.
        % fixNeighborIdx = ind2ind(size(vols.fixed), refgridsize, refIdx(range{:}));
        n = ndgrid2cell(range{:}); 
        fixNeighborIdx = sub2ind(refgridsize, n{:});
        fixNeighborIdx = fixNeighborIdx(:);
        nNeighbors = numel(fixNeighborIdx);
        
        % extract appropriate patches, either by computing local libraries or taking a subset of the
        % full libraries.
        if strcmp(params.dist.libraryMethod, 'local')
            % compute moving library
            movingLibCurrent = patchlib.vol2lib(vols.moving, patchSize, 'locations', srcsubi);

            % build the reference libraries (same as neighboring patches)
            fixedCrop = cropVolume(vols.fixed, min(rangeNumbers), max(rangeNumbers) + patchSize - 1);
            neighborPatches = patchlib.vol2lib(fixedCrop, patchSize, patchSize - params.searchGridSize);
            
            % parse optional inputs
            if domask
                % compute moving mask library
                movingMaskLibCurrent = patchlib.vol2lib(vols.movingMask, patchSize, 'locations', srcsubi);

                % build the reference mask libraries (same as neighboring mask patches)
                fixedMaskCrop = cropVolume(vols.fixedMask, min(rangeNumbers), max(rangeNumbers) + patchSize - 1);
                neighborMaskPatches = patchlib.vol2lib(fixedMaskCrop, patchSize, patchSize - params.searchGridSize);
            end
        else
            % extract moving library
            movingLibCurrent = movLib(i, :);
            neighborPatches = fixLib(fixNeighborIdx, :);

            % parse optional inputs
            if domask
                % compute moving mask library
                movingMaskLibCurrent = movMaskLib(i, :);         
                % get the neighbor patches
                neighborMaskPatches = fixMaskLib(fixNeighborIdx, :);
            end
        end     
        
        % patch intensity distance of current patch to neighbors
        % normal pdist2:
        switch params.dist.metric
            case 'euclidean'
                d = pdist2(movingLibCurrent, neighborPatches);
                
            case 'seuclidean'
                % relative pdist2:
                avg = bsxfun(@plus, movingLibCurrent, neighborPatches) / 2 + eps;
                d = sum((bsxfun(@times, movingLibCurrent, 1./avg) - neighborPatches./avg) .^2, 2)';
                
            case 'sparse'
                % distance function for sparse data
                if isfield(params.hack, 'maxThr')
                    neighborThrIdx = neighborPatches > params.hack.maxThr;
                    movingThrIdx = movingLibCurrent > params.hack.maxThr;
                    
                    % update the the mask.
                    upNeighborMask = max((neighborPatches - params.hack.maxThr) ./ params.hack.maxThr, 0.25);
                    movingMaskLibCurrent = max((movingLibCurrent - params.hack.maxThr) ./ params.hack.maxThr, 0.25);
                    
                    neighborMaskPatches(neighborThrIdx) = min(neighborMaskPatches(neighborThrIdx), upNeighborMask(neighborThrIdx));
                    movingMaskLibCurrent(movingThrIdx) = min(movingMaskLibCurrent(movingThrIdx), movingMaskLibCurrent(movingThrIdx));
                end
                    
                patchDifference = bsxfun(@minus, movingLibCurrent, neighborPatches) .^2 + eps;
                productMask = bsxfun(@times, movingMaskLibCurrent, neighborMaskPatches) + eps;
                numeratorD = sum(productMask .* patchDifference, 2)';
                denominatorD = sum(productMask, 2)';
                d = bsxfun(@times, numeratorD, prod(patchSize)./denominatorD) .^ 0.5;
            otherwise
                error('unknown distance metric');
        end
        
        % compute spatial distance of current location to neighbors
        dNeigh = params.dist.location * pdist2(srcsubi, refgridsub(fixNeighborIdx, :));
        
        % note we don't use 1:K, instead we use 1:numel(p) since we might allow less than K matches
        pDst(i, 1:nNeighbors) = d + dNeigh;   
        pIdx(i, 1:nNeighbors) = fixNeighborIdx;
        
    end
end

