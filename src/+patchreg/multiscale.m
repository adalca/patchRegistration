function displ = multiscale(vols, params, varargin)
% MULTISCALE run a full patch-based registration.
%
% displ = multiscale(vols, params)

    % tic for timing run
    mastertic = tic;

    % prepare scales
    [params, parsedParams] = parseInputs(vols, params);
    
    % initiate a displacement
    if isfield(vols, 'initDispl')
        d = dimsplit(5, vols.initDispl);
        displ = cellfunc(@(x) volresize(x, parsedParams.movingSizes{1}), d);
    else
        displ = repmat({zeros(parsedParams.movingSizes{1})}, [1, ndims(parsedParams.movingOrig)]); 
    end
    
    % go through the multiple scales
    for s = 1:params.scale.nScales        
        
        % get the scale moving and fixed, either by extraction or resizing
        scMovingSize = parsedParams.movingSizes{s};
        scFixedSize = parsedParams.fixedSizes{s};
        scvols.moving = vol2scaleVol(vols.moving, scMovingSize, s);
        scvols.fixed = vol2scaleVol(vols.fixed, scFixedSize, s);
        if isfield(vols, 'movingMask')
            scvols.movingMask = vol2scaleVol(vols.movingMask, scMovingSize, s);
            scvols.fixedMask = vol2scaleVol(vols.fixedMask, scFixedSize, s);
        end
        
        % resize the warp distances to the current scale size
        displ = resizeWarp(displ, scMovingSize);
        
        % go through multiple inner iterations
        for t = 1:params.nInnerReps 
            
            % if verbose, print a bit of information
            if params.verbose
               fprintf('multiscale: scale %d iter %d size %s\n', s, t, sprintf('%d ', scMovingSize));
            end

            % warp moving image
            scvolsw = warpMovingImageAtScale(scvols, displ, params, vols, parsedParams);

            % run registration at given scale
            sstic = tic();
            locparams = scaleParams(params, s, t);
            localDispl = patchreg.singlescale(scvolsw, locparams, 'currentdispl', displ, varargin{:});
            sstime = toc(sstic);

            % compose previous warp with newfound warp
            cdispl = composeWarps(displ, localDispl, params.warp.dir, params.warp.dir);
            
            % if debug save mode is on, save relevant iteration information
            if isfield(params, 'debug') && isfield(params.debug, 'out') && ~isempty(params.debug.out)
                state = struct('scale', s, 'iter', t, 'scMovingSize', scMovingSize, ...
                    'scFixedSize', scFixedSize, 'runTime', sstime); %#ok<NASGU>
                displVolumes = struct('prevdispl', {displ}, 'localDispl', {localDispl}, ...
                    'cdispl', {cdispl}); %#ok<NASGU>
                volumes = struct('scMoving', scvols.moving, 'scFixed', scvols.fixed, ... 
                    'scMovingWarped', scvolsw.moving); %#ok<NASGU>
                if isfield(scvolsw, 'movingMask'), volumes.scMovingMaskWarped = scvolsw.movingMask; end
                filename = sprintf(params.debug.out, s, t);
                save(filename, 'params', 'state', 'displVolumes', 'volumes');
            end 
            
            % final warp for this iteration is the composed warp
            displ = cdispl;
        end
    end
    
    if isfield(params, 'debug') && isfield(params.debug, 'out') && ~isempty(params.debug.out)
        state = struct('runTime', toc(mastertic)); %#ok<NASGU>
        volumes = struct('moving', moving, 'fixed', fixed); %#ok<NASGU>
        displVolumes = struct('displ', displ); %#ok<NASGU>
        filename = sprintf(params.debug.out, 0, 0);
        save(filename, 'params', 'displVolumes', 'volumes', 'state');
    end    
end

function locparams = scaleParams(params, s, t)
% extract this scale's parameters
    locparams = params;
    locparams.patchSize = locparams.patchSize(s, :);
    locparams.gridSpacing = locparams.gridSpacing(s, :);
    locparams.searchSize = locparams.searchSize(s, :);
    if params.adaptSearchGridSpacing
        locparams.searchGridSize = params.nInnerReps - t + 1;
    else
        locparams.searchGridSize = 1;
    end
    locparams.mrf.lambda_edge = locparams.mrf.lambda_edge(s) ./ locparams.searchGridSize;
    locparams.mrf.lambda_node = locparams.mrf.lambda_node(s);
end

function scVol = vol2scaleVol(vol, scVolSize, s)
% get scale vol of size scVolSize, but with the possibility of scVol having been provided.
    if iscell(vol)
        scVol = vol{s};
    else
        scVol = volresize(vol, scVolSize);
    end
end

function scvolsw = warpMovingImageAtScale(scvols, displ, params, vols, parsedParams)
    scvolsw = scvols;

    % warp the moving following the current displacement
    if strcmp(params.warp.res, 'atscale')
        % using the current scale dispalcement result, warp the current-scale moving image
        scvolsw.moving = volwarp(scvols.moving, displ, params.warp.dir);
        if isfield(scvols, 'movingMask')
            scvolsw.movingMask = volwarp(scvols.movingMask, displ, params.warp.dir);
        end

    else
        % upsample the displacement to original (highest scale) image size, 
        % then warp the image, and then downsample it to the current image size
        assert(strcmp(params.warp.res, 'full'));
        assert(~iscell(vols.moving), ...
            'full warp.res cannot be used with scale-specified volumes');

        wd = resizeWarp(displ, size(parsedParams.movingOrig));
        movingWarped = volwarp(parsedParams.movingOrig, wd, params.warp.dir);
        scvolsw.moving = volresize(movingWarped, scMovingSize); % TODO: fix bug.
        if domask
            movingMaskWarped = volwarp(movingMaskOrig, wd, params.warp.dir);
            scvolsw.movingMask = volresize(movingMaskWarped, scMovingSize);
        end
    end
end

function sizes = logSizes(minScale, nScales, sz)
% get log-based sizes 
    sizes = arrayfunc(@(x) round(2 .^ linspace(log2(minScale), log2(x), nScales)), sz);
    sizes = cat(1, sizes);
    sizes = dimsplit(2, sizes{:});
end

function [params, pp] = parseInputs(vols, params)

    if strcmp(params.warp.dir, 'forward')
        warning('Warning: forward full volwarp at each iteration is costly');
    end

    moving = vols.moving;
    fixed = vols.fixed;

    % prepare scale sizes
    if strcmp(params.scale.method, 'load')
        pp.movingSizes = cellfunc(@(x) size(x), moving);
        pp.fixedSizes = cellfunc(@(x) size(x), fixed);
        pp.movingOrig = moving{params.scale.nScales};
    else
        % pre-compute the moving and fixed sizes at each scale.
        % e.g. 2.^linspace(log2(32), log2(256), 4)
        minScale = min(opts.minVolSize, min([size(moving), size(fixed)])/2);
        pp.movingSizes = logSizes(minScale, params.scale.nScales, size(moving));
        pp.fixedSizes = logSizes(minScale, params.scale.nScales, size(fixed));
        pp.movingOrig = moving;
    end
    
    % all sizes are allowed to be nScales sized.
    rfn = @(p) repmat(p, [params.scale.nScales, 1]);
    if size(params.patchSize, 1) == 1, params.patchSize = rfn(params.patchSize); end
    if size(params.gridSpacing, 1) == 1, params.gridSpacing = rfn(params.gridSpacing); end
    if size(params.searchSize, 1) == 1, params.searchSize = rfn(params.searchSize); end
    if size(params.mrf.lambda_edge, 1) == 1, params.mrf.lambda_edge = rfn(params.mrf.lambda_edge); end
    if size(params.mrf.lambda_node, 1) == 1, params.mrf.lambda_node = rfn(params.mrf.lambda_node); end
end
