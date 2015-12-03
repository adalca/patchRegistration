function [sourceWarped, warp, qp, pi] = singlescale(source, target, patchSize, srcPatchOverlap, varargin)
% patch based discrete registration: single scale
%
% two main methods:
%   - grid on mrf, 
%   - large-scale search.
%
% TODO: 
%   - have explicit definition of default parameters (e.g. location 0.01 for knnargs)
%   - for large-scale search, *add* diffeomorphism constraint to edgefun.
%   - consider separating the warp computation from the warping itself. 
%       - However, what's the proper naming?
%
% Warning: are we assuming size(source) == size(target) here?

    % input parse
    inputs = parseInputs(source, target, patchSize, srcPatchOverlap, varargin{:});
    refPatchOverlap = 'sliding';
    srcSize = size(source);
    
    % get optimal patch movements via knnsearch and patchmrf.
    %   We're using volknnsearch simply because of existing implementaiton. In concept, we should
    %   use something like pdist2 without the knnsearch, since we set K = prod(patchSize). So the
    %   Knn search is overkill here, and likely slows us down, but is quick to implement given
    %   patchlib. TODO: fix (use pdist2) upon completion.
    if inputs.local > 0
        searchPatch = ones(1, ndims(source)) .* inputs.local .* 2 + 1;
        if strcmp(warpDir, 'backward')
            [patches, pDst, pIdx, ~, srcgridsize, refgridsize] = ...
            patchlib.volknnsearch(target, source, patchSize, srcPatchOverlap, refPatchOverlap, ...
            'local', inputs.local, 'location', 0.01, 'K', prod(searchPatch), 'fillK', true, inputs.searchargs{:});
        
        else
            [patches, pDst, pIdx, ~, srcgridsize, refgridsize] = ...
                patchlib.volknnsearch(source, target, patchSize, srcPatchOverlap, refPatchOverlap, ...
                'local', inputs.local, 'location', 0.01, 'K', prod(searchPatch), 'fillK', true, inputs.searchargs{:});
        end
        
    else
        % unverified/explored.
        [patches, pDst, pIdx, ~, srcgridsize, refgridsize] = ...
            patchlib.volknnsearch(source, target, patchSize, srcPatchOverlap, refPatchOverlap, ...
            'location', 0.01, 'K', 10, 'fillK', true, inputs.searchargs{:});
    end
    
    % transform patch movements to a (regularized) warp
    % regularize in one of a few ways
    switch inputs.warpreg
        case 'none'
            % Unregularized warp 
            warp = patchreg.idx2Warp(pIdx(:, 1), srcSize, patchSize, srcPatchOverlap, refgridsize);
            
        case 'mrf'
            % Regularization Method 1: mrf warp
            [warp, qp, pi] = mrfwarp(srcSize, patches, pDst, pIdx, patchSize, srcPatchOverlap, srcgridsize, ...
                refgridsize, inputs.edgefn, inputs.mrfargs, infer_method);

        case 'quilt'
            % Regularization Method 2: quilt warp. (this may only have been implemented for 2d)
            alpha = 5;
            warp = quiltwarp(srcSize, pDst, pIdx, patchSize, srcPatchOverlap, srcgridsize, inputs.local, alpha);
            
        otherwise
            error('warp regularization: unknown method');
    end
    
    % warp - use MRF warp
    sourceWarped = volwarp(source, warp, warpDir);
end

%% Warp functions

function [warp, qp, pi] = mrfwarp(srcSize, patches, pDst, pIdx, patchSize, patchOverlap, ...
    srcgridsize, refgridsize, edgefn, mrfargs, infer_method)
 % TODO: try taking (mean shift?) mode of displacements as opposed to mrf. use quilt where
    % patches are copies of the displacements? TODO: do study.
    [qp, ~, ~, ~, pi] = ...
            patchlib.patchmrf(patches, srcgridsize, pDst, patchSize, patchOverlap, ...
            'edgeDst', edgefn, 'lambda_node', 1, 'lambda_edge', 1, 'pIdx', pIdx, ...
            'refgridsize', refgridsize, 'infer_method', infer_method, mrfargs{:});
        
     warp = patchreg.idx2Warp(pi, srcSize, patchSize, patchOverlap, refgridsize);
end

function warp = quiltwarp(srcSize, pDst, pIdx, patchSize, patchOverlap, srcgridsize, local, alpha)

    % first try for second method:
    dispPatchSize = ones(1, numel(patchSize)) * (2*local+1);
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
    warp = disp2warp(piwarp, srcSize, patchSize, patchOverlap);
end

%% Logistics

function inputs = parseInputs(source, target, patchSize, srcPatchOverlap, varargin)

    p = inputParser();
    p.addRequired('source', @isnumeric);
    p.addRequired('target', @isnumeric);
    p.addRequired('patchSize', @isnumeric);
    p.addRequired('srcPatchOverlap', @(x) isnumeric(x) | ischar(x));
    
    p.addParameter('searchargs', {}, @iscell);
    p.addParameter('mrfargs', {}, @iscell);
    
    p.addParameter('warpDir', 'backward', @(x) ischar(x)); % 'backward' or 'forward'
    p.addParameter('infer_method', @UGM_Infer_LBP, @(x) isa(x, 'function_handle'));
    p.addParameter('local', 1, @isnumeric);
    p.addParameter('currentdispl', repmat({source*0}, [1, ndims(source)]), @iscell);
    p.parse(source, target, patchSize, srcPatchOverlap, varargin{:});
    inputs = p.Results;

    % setup variables
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
