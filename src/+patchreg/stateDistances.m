function  [patches, pDst, pIdx, srcgridsize, refgridsize] = ...
    stateDistances(source, target, patchSize, patchOverlap, searchSize, ...
    locweight, distanceMetric, libraryMethod, varargin)
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
    
    if strcmp(libraryMethod, 'full')
        % compute source library
        srcLib = patchlib.vol2lib(source, patchSize, patchOverlap);

        % build the reference libraries
        refLib = patchlib.vol2lib(target, patchSize);
    end
    
    P = prod(patchSize);
    K = prod(searchSize);
    pDst = Inf(numel(srcIdx), K);
    pIdx = ones(numel(srcIdx), K); % Should be investigated. ones is a hack
    patches = nan(numel(srcIdx), 1, prod(searchSize)); % We never use the patches in this case. The second argument should be P, but we're putting 1 for memory win.
    local = (searchSize(1) - 1)/2;
    srcgridsub = ind2subvec(size(source), srcIdx(:));
    refgridsub = ind2subvec(size(target), refIdx(:));
    
    % parse optional inputs
    if(numel(varargin) == 2)
        srcMask = varargin{1};
        refMask = varargin{2};
        
        if strcmp(libraryMethod, 'full')
            % compute source mask library
            srcMaskLib = patchlib.vol2lib(srcMask, patchSize, patchOverlap);

            % build the reference mask libraries
            refMaskLib = patchlib.vol2lib(refMask, patchSize);
        end
    end
    
    % for each point in the source grid
    for i = 1:numel(srcIdx)
        srcsubi = srcgridsub(i, :);
        if abs(srcsubi - [41,55,42]) < 2
            disp('hi andreea. cat.');
        end
            
        range = cell(1, nDims);
        for j = 1:nDims
            range{j} = max(srcsubi(j)-local, 1):min(srcsubi(j)+local, refgridsize(j));
            assert(~isempty(range{j}));
        end
        
        rangeNumbers = ndgrid2vec(range{:});
        
        % tranform indexes from target space to reference index.
        refNeighborIdx = ind2ind(size(target), refgridsize, refIdx(range{:}));
        refNeighborIdx = refNeighborIdx(:);
        nNeighbors = numel(refNeighborIdx);
        
        if strcmp(libraryMethod, 'local')
            % compute source library
            srcLibCurrent = patchlib.vol2lib(source, patchSize, 'locations', srcsubi);

            % build the reference libraries (same as neighboring patches)
            targetCrop = cropVolume(target, min(rangeNumbers), max(rangeNumbers) + patchSize - 1);
            neighborPatches = patchlib.vol2lib(targetCrop, patchSize);
            %neighborPatches = patchlib.vol2lib(target, patchSize, 'locations', rangeNumbers);
            %assert(all(neighborPatches(:)==neighborPatches2(:)));
            
            % parse optional inputs
            if(numel(varargin) == 2)
                % compute source mask library
                srcMaskLibCurrent = patchlib.vol2lib(srcMask, patchSize, 'locations', srcsubi);

                % build the reference mask libraries (same as neighboring
                % mask patches)
                %neighborMaskPatches = patchlib.vol2lib(refMask, patchSize, 'locations', rangeNumbers);  
                targetMaskCrop = cropVolume(refMask, min(rangeNumbers), max(rangeNumbers) + patchSize - 1);
                neighborMaskPatches = patchlib.vol2lib(targetMaskCrop, patchSize);
            end
        else
            % extract source library
            srcLibCurrent = srcLib(i, :);

            % parse optional inputs
            if(numel(varargin) == 2)
                % compute source mask library
                srcMaskLibCurrent = srcMaskLib(i, :);         
            end
            
            % get the neighbor patches
            neighborPatches = refLib(refNeighborIdx, :);
            if(numel(varargin)==2)
                neighborMaskPatches = refMaskLib(refNeighborIdx, :);
            end
        end     
        
        % store the neighbor patches
        % patches(i, :, 1:nNeighbors) = reshape(neighborPatches, [1, P, nNeighbors]);
        
        % patch intensity distance of current patch to neighbors
        % normal pdist2:
        switch distanceMetric
            case 'euclidean'
                d = pdist2(srcLibCurrent, neighborPatches);
                
            case 'seuclidean'
                % relative pdist2:
                avg = bsxfun(@plus, srcLibCurrent, neighborPatches) / 2 + eps;
                d = sum((bsxfun(@times, srcLibCurrent, 1./avg) - neighborPatches./avg) .^2, 2)';
                
            case 'sparse'
                % distance function for sparse data
                patchDifference = bsxfun(@minus, srcLibCurrent, neighborPatches) .^2 + eps;
                productMask = bsxfun(@times, srcMaskLibCurrent, neighborMaskPatches) + eps;
                numeratorD = sum(productMask .* patchDifference, 2)';
                denominatorD = sum(productMask, 2)';
                d = bsxfun(@times, numeratorD, prod(patchSize)./denominatorD) .^ 0.5;
            otherwise
                error('unknown distance metric');
        end
        
        % compute spatial distance of current location to neighbors
        dNeigh = locweight * pdist2(srcsubi, refgridsub(refNeighborIdx, :));
        
        % note we don't use 1:K, instead we use 1:numel(p) since we might allow less than K matches
        pDst(i, 1:nNeighbors) = d + dNeigh;   
        pIdx(i, 1:nNeighbors) = refNeighborIdx;
    end
end

