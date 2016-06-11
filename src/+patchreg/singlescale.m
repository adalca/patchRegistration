function [warp, quiltedPatches, quiltedpIdx] = singlescale(vols, params, varargin)
% SINGLESCALE run a single scale patch-based registration
%
% warp = singlescale(source, target, params) run a single scale patch-based registration. source and
% target are the moving and fixed (2D or 3D) volumes. warp is a cell of size nDims-by-1, and each
% entry is a volumes is the same size as source, indicating the warp in that dimention. We assuming
% size(source) == size(target) here (or rather, haven't tested the function otherwise).
%
% warp = singlescale(source, target, params, opts, Param1, Value1, ...) allows for the following
% extra param/value pairs:
%   currentdispl: the current displacement, if this call is part of a iterative run. NOTE: passing
%       this is crucial if using mrf regularization, since it will be important in the pair
%       potentials
%   searchargs: any extra arguments to be passed to the search function
%   mrfargs: any extra arguments to be passed to the mrf function
%   sourceMask:
%   targetMask:
%
% note: passing currentdispl is important in MRF!

    % parse inputs
    narginchk(2, inf);
    inputs = parseInputs(vols, params, varargin{:});
    patchSize = params.patchSize;
    movingPatchOverlap = patchSize - params.gridSpacing; % patchSize - (source grid spacing)
    params.patchOverlap = movingPatchOverlap;
    
    % prepare volumes for patch distances
    dstvols = vols;
    if (strcmp(params.warp.dir, 'backward')) % switch moving and fixed
        dstvols.fixed = vols.moving;
        dstvols.moving = vols.fixed;
        if isfield(vols, 'movingMask');
            dstvols.fixedMask = vols.movingMask;
            dstvols.movingMask = vols.fixedMask;
        end
    end
    
    % get proposed patch displacement and cost/distances
    [patches, pDst, pIdx, srcgridsize, refgridsize] = patchreg.stateDistances(dstvols, params);
    if isIntegerValue(params.dist.nStates); % only keep the top k
        [~, si] = sort(pDst, 2, 'ascend');
        for xi = 1:size(pDst, 1)
            patches(xi, :) = patches(xi, :, si(xi,:));
            pDst(xi, :) = pDst(xi, si(xi,:));
            pIdx(xi, :) = pIdx(xi, si(xi,:));
        end
        patches = patches(:, :, 1:params.dist.nStates);
        pDst = pDst(:, 1:params.dist.nStates);
        pIdx = pIdx(:, 1:params.dist.nStates);
    else
        assert(ischar(params.dist.nStates) && strcmp(params.dist.nStates, 'complete'), ...
            'dist.search can only be ''complete'' or an int');
    end
    
    % transform patch movements to a (regularized) warp
    % regularize in one of a few ways
    movingSize = size(vols.moving);
    switch params.warp.reg
        case 'none'
            % Unregularized warp 
            [~, mi] = min(pDst, [], 2);
            idx = sub2ind(size(pIdx), (1:size(pIdx, 1))', mi);
            warp = idx2warp(pIdx(idx), movingSize, patchSize, movingPatchOverlap, refgridsize);
            
        case 'mrf'
            % Regularization via MRF 
            [warp, quiltedPatches, quiltedpIdx] = patchreg.mrfWarpReg(movingSize, patches, pDst, pIdx, ...
                patchSize, movingPatchOverlap, srcgridsize, refgridsize, params.warp.dir, inputs, params);

        case 'quilt'
            % Regularization Method 2: quilt warp. (this may only have been implemented for 2d)
            alpha = 5;
            warp = patchreg.quiltWarpReg(movingSize, pDst, pIdx, patchSize, movingPatchOverlap, ...
                srcgridsize, params.searchSize, alpha, params.dist.search);
            
        otherwise
            error('warp regularization: unknown method');
    end
end

function inputs = parseInputs(vols, params, varargin)
% input parsing.

    source = vols.moving;
    target = vols.fixed;

    nDims = ndims(source);
    assert(all(size(source) == size(target)), 'source and target are not the same size');

    % checking functions
    checkparams = @(x) isstruct(x) && ...
        isfield(x, 'patchSize') && numel(x.patchSize) == nDims && all(isodd(x.patchSize)) && ...
        isfield(x, 'gridSpacing') && numel(x.gridSpacing) == nDims && all(x.gridSpacing > 0) && ...
        isfield(x, 'searchSize') && numel(x.searchSize) == nDims && all(isodd(x.searchSize)) && ...
        isfield(x, 'warp') && isfield(x.warp, 'dir') && ismember(x.warp.dir, {'backward', 'forward'}) && ...
        isfield(x.warp, 'reg') && ismember(x.warp.reg, {'none', 'mrf', 'quilt'});
    
    p = inputParser();
    p.addRequired('params', checkparams);    
    
    p.addParameter('currentdispl', repmat({source*0}, [1, ndims(source)]), @iscell);
    p.addParameter('searchargs', {}, @iscell);
    
    p.parse(params, varargin{:});
    inputs = p.Results;
    inputs.mrf.lambda_edge = params.mrf.lambda_edge;
    inputs.mrf.lambda_node = params.mrf.lambda_node;
    
    % setup edge function for mrfs.
    if ispc
        pdistFunc = @pdist2mex;
        
	else % unix
		ver = version('-release');
		switch ver
			case '2013b'
				pdistFunc = @pdist2mexR2013b;
			otherwise
				pdistFunc = @pdist2mex;
		end
    end
    inputs.mrf.edgeDst = @(x, y, ~, ~) pdistFunc(x.disp', y.disp', 'euc', [], [], []);
end
