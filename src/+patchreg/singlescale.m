function [sourceWarped, warp, qp, pi] = singlescale(source, target, patchSize, patchOverlap, varargin)
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
        searchPatch = ones(1, ndims(source)) .* local .* 2 + 1;
        [patches, pDst, pIdx, ~, srcgridsize, refgridsize] = ...
            patchlib.volknnsearch(source, target, patchSize, patchOverlap, ...
            'local', local, 'location', 0.01, 'K', prod(searchPatch), 'fillK', true, searchargs{:});
    else
        % unverified/explored.
        [patches, pDst, pIdx, ~, srcgridsize, refgridsize] = ...
            patchlib.volknnsearch(source, target, patchSize, patchOverlap, ...
            'location', 0.01, 'K', 10, 'fillK', true, searchargs{:});
    end
    
    % TODO: try taking (mean shift?) mode of displacements as opposed to mrf. use quilt where
    % patches are copies of the displacements? TODO: do study.
    [qp, ~, ~, ~, pi] = ...
            patchlib.patchmrf(patches, srcgridsize, pDst, patchSize, patchOverlap, ...
            'edgeDst', edgefn, 'lambda_node', 1, 'lambda_edge', 5, 'pIdx', pIdx, ...
            'refgridsize', refgridsize, mrfargs{:});
    
    % first try for second method:
    dispPatchSize = ones(1, numel(patchSize)) * (2*local+1);
    nodePot = exp(-0.1 * pDst); % weight should be different than in mrf.
    piver = stateDispQuilt(nodePot, dispPatchSize, patchOverlap, srcgridsize);
    disp('done ver');
    
    
    % compute the displacement on the grid
    idx = patchlib.grid(srcSize, patchSize, patchOverlap);
    griddisp = patchlib.corresp2disp(srcSize, refgridsize, pi, 'srcGridIdx', idx, 'reshape', true);
    
    % interpolate to a full displacement 
    % shift by (patchSize-1)/2 to put the displacement in the center of the patches
    warp = patchlib.interpDisp(griddisp, patchSize, patchOverlap, size(source), (patchSize - 1)/2); 
    assert(all(cellfun(@(d) all(size(d) == size(source)), warp)));
    
    % correct any NANs in the displacements. 
    % Usually these happen at the edges
    nNANs = sum(cellfun(@(x) sum(isnan(x(:))), warp));
    nElems = sum(cellfun(@(x) numel(x), warp));
    if nNANs > 0
        warning('patchreg.singlescale: Found %d (%3.2f%%) NANs. Inpainting.', nNANs, nNANs/nElems);
        
        % warning: setting the nans to 0 is not correct. Using inpainting.
        warp = cellfunc(@inpaintn, warp);
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
    p.addParameter('currentdispl', repmat({source*0}, [1, ndims(source)]), @iscell);
    p.parse(source, target, patchSize, patchOverlap, varargin{:});

    % extract param/Value pairs
    searchargs = p.Results.searchargs;
    mrfargs = p.Results.mrfargs;
    local = p.Results.local;

     % setup variables
    edgefn = @(a1,a2,a3,a4) edgefunc(a1, a2, a3, a4, p.Results.currentdispl); 
end


function dst = edgefunc(a1, a2, a3, a4, currentdispl)
    dvFact = 100;
    usemex = exist('pdist2mex', 'file') == 3;
    dst = patchlib.correspdst(a1, a2, a3, a4, dvFact, usemex); 
    
    loc1 = mat2cellsplit(a1.loc);
    loc2 = mat2cellsplit(a2.loc);
    displ1 = cellfun(@(x) x(loc1{:}) ./ dvFact, currentdispl);
    displ2 = cellfun(@(x) x(loc2{:}) ./ dvFact, currentdispl);
    dst = dst + norm(displ1 - displ2);
end
