function registerNii(pathsFile, paramsFile, optsFile, varargin)
% patch-based discrete registration
% - pathsFile is a .ini file that contains all necessary paths
% - paramsFile is a .ini file that contains all the necessary parameters,
% - optsFile is a .ini file that contains all necessary options
% - varargin takes in optional files for sourceMask and targetMask, in case
% registration is sparse
%
% TODO: use cubic interpolation? see if there is a difference?

    %% load in configurations
    params = ini2struct(paramsFile);
    params.nScales = size(params.gridSpacing, 1);
    
    opts = ini2struct(optsFile);
    
    paths = ini2struct(pathsFile);
    if strcmp(opts.scaleMethod, 'load') % load option has 
        params.volPad = [0, 0, 0];
    end
    
    % evaluate whatever modifiers are put in place
    % e.g. 'params.mrf.lambda_edge = 0.1';
    for i = 1:numel(varargin)
        eval(varargin{i});
    end

    % TODO: should only do this in the case of non-load scaleMethod.
    [source, target, params.sourceMask, params.targetMask] = ...
        prepareVolumes(paths, params.volPad, opts);
    
    %% Patch Registration
    % do multi scale registration
    tic;
    displ = patchreg.multiscale(source, target, params, opts, paths, varargin{:});
    mastertoc = toc;
    
    %% save final displacement and original volumes and niis
    % TODO: could move this to another file that takes in the same ini files, to make the code more
    % modular. We can then call if from here. This file would then take in the displacement.

    % get inverse displacement
    displInv = invertwarp(displ, opts.warpDir);
    
    % compose the final image using the resulting displacements
    sourceWarped = volwarp(source, displ, opts.warpDir);
    targetWarped = volwarp(target, displInv, opts.warpDir);
    if strcmp(opts.distance, 'sparse')
        sourceMaskWarped = volwarp(params.sourceMask, displ, opts.warpDir);
        targetMaskWarped = volwarp(params.targetMask, displInv, opts.warpDir);
    end
    
    volumes.source = source;
    volumes.sourceWarped = sourceWarped;
    volumes.target = target; 
    volumes.targetWarped = targetWarped;
    if strcmp(opts.distance, 'sparse')
        volumes.sourceMask = params.sourceMask;
        volumes.sourceMaskWarped = sourceMaskWarped;
        volumes.targetMask = params.targetMask;
        volumes.targetMaskWarped = targetMaskWarped;
    end

    srcSize = size(volumes.source) - params.volPad * 2;
    volumes.sourceSeg = padarray(volresize(nii2vol(paths.sourceSegFile), srcSize, 'nearest'), params.volPad, 'both');
    tarSize = size(volumes.target) - params.volPad * 2;
    volumes.targetSeg = padarray(volresize(nii2vol(paths.targetSegFile), tarSize, 'nearest'), params.volPad, 'both');

    volumes.sourceWarpedSeg = volwarp(volumes.sourceSeg, displ, opts.warpDir, 'interpmethod', 'nearest');
    volumes.targetWarpedSeg = volwarp(volumes.targetSeg, displInv, opts.warpDir, 'interpmethod', 'nearest');

    % crop volumes after padding
    for fi = fieldnames(volumes)
        volumes.(fi) = cropVolume(volumes.(fi), params.volPad + 1, size(volumes.(fi)) - params.volPad);
    end
    
    for volume = 1:numel(displ)
        displ{volume} = cropVolume(displ{volume}, params.volPad + 1, size(displ{volume}) - params.volPad);
        displInv{volume} = cropVolume(displInv{volume}, params.volPad + 1, size(displInv{volume}) - params.volPad);
    end
    
    save(sprintf([paths.savepathout '%d_%d.mat'], 0, 0), 'volumes', 'paths', 'displ', 'displInv', 'params', 'opts', 'mastertoc');

    % make and save niis
    displFile = sprintf('%s_2_%s.nii.gz', paths.sourceName, paths.targetName);
    displInvFile = sprintf('%s_2_%s_inv.nii.gz', paths.sourceName, paths.targetName);
    sourceWarpedFile = sprintf('%s_in%s_via%s_2_%s.nii.gz', paths.sourceName, paths.targetName, paths.sourceName, paths.targetName);
    targetWarpedFile = sprintf('%s_in%s_via%s_2_%s_inv.nii.gz', paths.targetName, paths.sourceName, paths.sourceName, paths.targetName);
    sourceWarpedSegFile = sprintf('%s_seg_in%s_via%s_2_%s.nii.gz', paths.sourceName, paths.targetName, paths.sourceName, paths.targetName);
    targetWarpedSegFile = sprintf('%s_seg_in%s_via%s_2_%s_inv.nii.gz', paths.targetName, paths.sourceName, paths.sourceName, paths.targetName);
    
    saveNii(make_nii(cat(5, displ{:})), [paths.savepathnii displFile]);
    saveNii(make_nii(cat(5, displInv{:})), [paths.savepathnii displInvFile]);
    saveNii(make_nii(sourceWarped), [paths.savepathnii sourceWarpedFile]);
    saveNii(make_nii(targetWarped), [paths.savepathnii targetWarpedFile]);
    saveNii(make_nii(volumes.sourceWarpedSeg), [paths.savepathnii sourceWarpedSegFile]);
    saveNii(make_nii(volumes.targetWarpedSeg), [paths.savepathnii targetWarpedSegFile]);
    
    %% Immediate Output Visualization
    % TODO: take this out and put it in a separate visualization function
    if opts.verbose > 1
        % This is just some quick visualization. Analysis should be done separately
        displvols = {source, target, sourceWarped}; % volumes to display
        
        if opts.verbose > 1 % only computer targetWarped if you're willing to wait a while
            oppdirn = ifelse(strcmp(opts.warpDir, 'backward'), 'forward', 'backward');
            targetWarped = volwarp(target, displ,  oppdirn);
            displvols = [displvols, targetWarped];
        end

        % TODO: try to do quilt instead of warp. Soemthing like:
        % [~, ~, srcgridsize] = patchlib.grid(size(source), patchSize, patchOverlap);
        % alternativeWarped = patchlib.quilt(qp, srcgridsize, patchSize, patchOverlap); 

        % display results
        if ndims(source) == 2 %#ok<ISMAT>
            patchview.figure();
            drawWarpedImages(source, target, sourceWarped, displ); 

        elseif ndims(source) == 3
            % prepare segmentations
            segvols = {};
            if isfield(paths, 'sourceSegFile') && isfield(paths, 'targetSegFile')
                sourceSegmWarped = volwarp(sourceSeg, displ, opts.warpDir, 'interpmethod', 'nearest');
                segvols = {sourceSeg, targetSeg, sourceSegmWarped};
            end

            % visualize
            view3Dopt(displvols{:}, segvols{:}, displ{:});
        end
    end
end
