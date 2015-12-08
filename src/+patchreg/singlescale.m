function [warp, quiltedPatches, quiltedpIdx] = singlescale(source, target, params, opts, varargin)
% SINGLESCALE run a single scale patch-based registration
%
% warp = singlescale(source, target, params, opts) run a single scale patch-based registration.
% source and target are the moving and fixed (2D or 3D) volumes. params is a struct with fields:
% patchSize, gridSpacing, searchSize. opts is a struct with fields: inferMethod, warpDir, warpReg.
% warp is a cell of size nDims-by-1, and each entry is a volumes is the same size as source,
% indicating the warp in that dimention. We assuming size(source) == size(target) here (or rather,
% haven't tested the function otherwise).
%
% warp = singlescale(source, target, params, opts, Param1, Value1, ...) allows for the following
% extra param/value pairs:
%   currentdispl: the current displacement, if this call is part of a iterative run. NOTE: passing
%       this is crucial if using mrf regularization, since it will be important in the pair
%       potentials
%   searchargs: any extra arguments to be passed to the search function
%   mrfargs: any extra arguments to be passed to the mrf function.
%
% note: passing currentdispl is important in MRF!
%
% TODO: 
%   - We will explore two main methods
%       + grid on mrf, 
%       + large-scale search (here, can *add* diffeomorphism constraint to edgefun)
%   - Move out hardcoded parameters (e.g. locations)
%   - shoudl somehow make symmetric the patch search? Jointly they should find e/o ?
%   - pIdx is initialized with ones in stateDistances. Should investigate
%   because this is a hack

    % parse inputs
    narginchk(4, inf);
    inputs = parseInputs(source, target, params, opts, varargin{:});
    patchSize = params.patchSize;
    srcPatchOverlap = patchSize - params.gridSpacing; % patchSize - (source grid spacing)
    srcSize = size(source);
    
    % get optimal patch movements via knnsearch and patchmrf.
    %   We're using volknnsearch simply because of existing implementaiton. In concept, we should
    %   use something like pdist2 without the knnsearch, since we set K = prod(patchSize). So the
    %   Knn search is overkill here, and likely slows us down, but is quick to implement given
    %   patchlib. TODO: fix (use pdist2) upon completion.
    refPatchOverlap = 'sliding';
    local = (params.searchSize - 1) / 2;
    if local > 0
        searchPatch = ones(1, ndims(source)) .* local .* 2 + 1;
        if strcmp(opts.warpDir, 'backward')
            if strcmp(opts.distanceMethod, 'volknnsearch')
                [patches, pDst, pIdx, ~, srcgridsize, refgridsize] = ...
                patchlib.volknnsearch(target, source, patchSize, srcPatchOverlap, refPatchOverlap, ...
                'local', local, 'location', 0.01, 'K', prod(searchPatch), 'fillK', true, inputs.searchargs{:});
            else
                [patches, pDst, pIdx, srcgridsize, refgridsize] = patchreg.stateDistances(target, source, patchSize, srcPatchOverlap, searchPatch, opts.location);
            end
        else
            if strcmp(opts.distanceMethod, 'volknnsearch')
                [patches, pDst, pIdx, ~, srcgridsize, refgridsize] = ...
                patchlib.volknnsearch(source, target, patchSize, srcPatchOverlap, refPatchOverlap, ...
                'local', local, 'location', 0.01, 'K', prod(searchPatch), 'fillK', true, inputs.searchargs{:});
            else
                [patches, pDst, pIdx, srcgridsize, refgridsize] = patchreg.stateDistances(source, target, patchSize, srcPatchOverlap, searchPatch, opts.location);
            end
        end
        
    else
        % unverified/explored.
        [patches, pDst, pIdx, ~, srcgridsize, refgridsize] = ...
            patchlib.volknnsearch(source, target, patchSize, srcPatchOverlap, refPatchOverlap, ...
            'location', 0.01, 'K', 10, 'fillK', true, inputs.searchargs{:});
    end
    
    % transform patch movements to a (regularized) warp
    % regularize in one of a few ways
    switch opts.warpReg
        case 'none'
            % Unregularized warp 
            warp = patchreg.idx2Warp(pIdx(:, 1), srcSize, patchSize, srcPatchOverlap, refgridsize);
            
        case 'mrf'
            % Regularization Method 1: mrf warp
            [warp, quiltedPatches, quiltedpIdx] = ...
                mrfwarp(srcSize, patches, pDst, pIdx, patchSize, srcPatchOverlap, srcgridsize, ...
                refgridsize, inputs.edgefn, opts.inferMethod, inputs.mrfargs);

        case 'quilt'
            % Regularization Method 2: quilt warp. (this may only have been implemented for 2d)
            alpha = 5;
            warp = quiltwarp(srcSize, pDst, pIdx, patchSize, srcPatchOverlap, srcgridsize, params.searchSize, alpha);
            
        otherwise
            error('warp regularization: unknown method');
    end
end

%% Warp functions

function [warp, quiltedPatches, quiltedpIdx] = mrfwarp(srcSize, patches, pDst, pIdx, patchSize, patchOverlap, ...
    srcgridsize, refgridsize, edgefn, inferMethod, mrfargs)
 % TODO: try taking (mean shift?) mode of displacements as opposed to mrf. use quilt where
    % patches are copies of the displacements? TODO: do study.
    [quiltedPatches, ~, ~, ~, quiltedpIdx] = ...
            patchlib.patchmrf(patches, srcgridsize, pDst, patchSize, patchOverlap, ...
            'edgeDst', edgefn, 'lambda_node', 1, 'lambda_edge', 1, 'pIdx', pIdx, ...
            'refgridsize', refgridsize, 'infer_method', inferMethod, mrfargs{:});
        
     warp = patchreg.idx2warp(quiltedpIdx, srcSize, patchSize, patchOverlap, refgridsize);
end

function warp = quiltwarp(srcSize, pDst, pIdx, patchSize, patchOverlap, srcgridsize, searchSize, alpha)

    % first try for second method:
    dispPatchSize = ones(1, numel(patchSize)) * searchSize;
    [pDstOrd, pIdxOrd] = knnresort(pDst, pIdx, srcgridsize, dispPatchSize);
    nodePot = exp(-alpha * pDstOrd); 
    nodePot = bsxfun(@times, nodePot, 1./sum(nodePot, 2));    
    
    piver = stateDispQuilt(nodePot, dispPatchSize, patchOverlap, srcgridsize);
    
    pisub = bsxfun(@minus, ind2subvec(dispPatchSize, piver(:)), ceil(dispPatchSize/2));
    pisub = -pisub; % since we're doing the warp in the other direction.
    piwarp = cellfunc(@(x) reshape(x, srcSize), dimsplit(2, pisub));
    
    % the warp probably needs to be shifted in the same manner that it is for mrfwarp
    % since we want to match center points, not top-left points
    % perhaps go from (-piver) --> pIdxNew and all patchreg.idx2Warp?
    piwarp = cellfunc(@(x) cropVolume(x, srcgridsize), piwarp);
    warp = patchreg.disp2warp(piwarp, srcSize, patchSize, patchOverlap);
end

%% Logistics

function inputs = parseInputs(source, target, params, opts, varargin)
    nDims = ndims(source);

    % checking functions
    checkparams = @(x) isstruct(x) && ...
        isfield(x, 'patchSize') && numel(x.patchSize) == nDims && all(isodd(x.patchSize)) && ...
        isfield(x, 'gridSpacing') && numel(x.gridSpacing) == nDims && all(x.gridSpacing > 0) && ...
        isfield(x, 'searchSize') && numel(x.searchSize) == nDims && all(isodd(x.searchSize));
    checkopts = @(x) isstruct(x) && ...
        isfield(x, 'inferMethod') && isa(x.inferMethod, 'function_handle') && ...
        isfield(x, 'warpDir') && ismember(x.warpDir, {'backward', 'forward'}) && ...
        isfield(x, 'warpReg') && ismember(x.warpReg, {'none', 'mrf', 'quilt'});
    
    p = inputParser();
    p.addRequired('source', @isnumeric);
    p.addRequired('target', @isnumeric);
    p.addRequired('params', checkparams);    
    p.addRequired('opts', checkopts); 
    
    p.addParameter('currentdispl', repmat({source*0}, [1, ndims(source)]), @iscell);
    p.addParameter('searchargs', {}, @iscell);
    p.addParameter('mrfargs', {}, @iscell);
    
    p.parse(source, target, params, opts, varargin{:});
    inputs = p.Results;
    
    % setup edge function for mrfs.
    usemex = exist('pdist2mex', 'file') == 3;
    inputs.edgefn = @(a1,a2,a3,a4) edgefunc(a1, a2, a3, a4, p.Results.currentdispl, usemex); 
end

function dst = edgefunc(a1, a2, a3, a4, currentdispl, usemex)
    dvFact = 100;
    dst = patchlib.correspdst(a1, a2, a3, a4, dvFact, usemex); 
    
    loc1 = mat2cellsplit(a1.loc);
    loc2 = mat2cellsplit(a2.loc);
    displ1 = cellfun(@(x) x(loc1{:}) ./ dvFact, currentdispl);
    displ2 = cellfun(@(x) x(loc2{:}) ./ dvFact, currentdispl);
    dst = dst + norm(displ1 - displ2);
end
