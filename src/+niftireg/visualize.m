% unfinished.

% TODO: take this out and put it in a separate visualization function
if opts.verbose > inf % >inf so it doesn't execute.
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