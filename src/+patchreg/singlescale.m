function [sourceWarped, warp] = singlescale(source, target, patchSize, patchOverlap, varargin)
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

    % input parse
    srcSize = size(source);
    [local, searchargs, mrfargs, edgefn] = parseInputs(source, target, patchSize, patchOverlap, varargin{:});
    
    % get optimal patch movements via knnsearch and patchmrf.
    % explanation: We're using volknnsearch simply because of existing implementaiton. In concept,
    % we should use something like pdist2 without the knnsearch, since we set K = prod(patchSize).
    % So the Knn search is overkill here, and likely slows us down, but is quick to implement given
    % patchlib. 
    % TODO: fix (use pdist2) upon completion. 
    if local > 0
        [patches, pDst, pIdx, ~, srcgridsize, refgridsize] = ...
            patchlib.volknnsearch(source, target, patchSize, patchOverlap, ...
            'local', local, 'location', 0.01, 'K', prod(patchSize), 'fillK', true, searchargs{:});
    else
        [patches, pDst, pIdx, ~, srcgridsize, refgridsize] = ...
            patchlib.volknnsearch(source, target, patchSize, patchOverlap, ...
            'location', 0.01, 'K', prod(patchSize), 'fillK', true, searchargs{:});
    end
    
    [~, ~, ~, ~, pi] = ...
            patchlib.patchmrf(patches, srcgridsize, pDst, patchSize, patchOverlap, ...
            'edgeDst', edgefn, 'lambda_node', 0.1, 'lambda_edge', 0.1, 'pIdx', pIdx, ...
            'refgridsize', refgridsize, mrfargs{:});
    
    % compute the displacement on the grid
    idx = patchlib.grid(srcSize, patchSize, patchOverlap);
    griddisp = patchlib.corresp2disp(srcSize, refgridsize, pi, 'srcGridIdx', idx, 'reshape', true);
    
    % interpolate to a full displacement 
    % shift by (patchSize-1)/2 to put the displacement in the center of the patches
    warp = patchlib.interpDisp(griddisp, patchSize, patchOverlap, size(source), (patchSize - 1)/2); 
    assert(all(cellfun(@(d) all(size(d) == size(source)), warp)));
    
    % correct any NANs in the displacements. 
    % Usually these happen at the edges due to silly interpolations.
    nNANs = sum(cellfun(@(x) sum(isnan(x(:))), warp));
    if nNANs > 0
        warning('Found %d NANs. Transforming them to 0s', nNANs);
        for i = 1:numel(warp), 
            warp{i}(isnan(warp{i})) = 0; 
        end
    end   
    
    % warp
    sourceWarped = volwarp(source, warp);
end

function [local, searchargs, mrfargs, edgefn] = parseInputs(source, target, patchSize, patchOverlap, varargin)

    p = inputParser();
    p.addRequired('source', @isnumeric);
    p.addRequired('target', @isnumeric);
    p.addRequired('patchSize', @isnumeric);
    p.addRequired('patchOverlap', @(x) isnumeric(x) | ischar(x));
    p.addOptional('searchargs', {}, @iscell);
    p.addOptional('mrfargs', {}, @iscell);
    p.addParameter('local', 1, @isnumeric);
    p.parse(source, target, patchSize, patchOverlap, varargin{:});

    % extract param/Value pairs
    searchargs = p.Results.searchargs;
    mrfargs = p.Results.mrfargs;
    local = p.Results.local;

     % setup variables
    usemex = exist('pdist2mex', 'file') == 3;
    edgefn = @(a1,a2,a3,a4) patchlib.correspdst(a1, a2, a3, a4, [], usemex); 
end
