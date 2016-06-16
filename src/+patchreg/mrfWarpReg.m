function [warp, quiltedPatches, quiltedpIdx] = ...
    mrfWarpReg(srcSize, patches, pDst, pIdx, patchSize, srcPatchOverlap, ...
    srcgridsize, refgridsize, warpdir, inputs, params)
% MRF warp regularizer

    % extract existing warp
    if strcmp(params.mrf.spatialPot, 'full')

        % get linear indexes of the centers of the search
        % here, we need to use patchSize since we're 
        srcgrididx = patchlib.grid(srcSize, patchSize, srcPatchOverlap);
        srcgrididx = shiftind(srcSize, srcgrididx, (patchSize - 1) / 2);

        if strcmp(warpdir, 'forward')
            % method 1
            warpedwarp = cellfunc(@(x) volwarp(x, inputs.currentdispl, 'forward'), inputs.currentdispl); 

            % method 2 for 'forward' --- faster, but currently aren't doing proper interpn, though
            % warpedwarp = cellfunc(@(x) volwarp(x, inputs.currentdispl, 'forward', 'selidxout', srcgrididx), inputs.currentdispl); 
            % x = cellfunc(@(x) x(:), warpedwarp);
        else

            warpedwarp = inputs.currentdispl;
        end
        warpedwarpsel = cellfunc(@(x) x(srcgrididx(:)), warpedwarp);

        inputs.mrf.existingDisp = cat(2, warpedwarpsel{:});
        assert(isclean(inputs.mrf.existingDisp));
    end

    % run the mrf inference
    mrfargs = struct2cellWithNames(inputs.mrf);
    [quiltedPatches, ~, ~, ~, quiltedpIdx] = ...
            params.mrf.fn(patches, srcgridsize, pDst, patchSize, srcPatchOverlap, ...
            'pIdx', pIdx, 'refgridsize', refgridsize, 'srcSize', srcSize, mrfargs{:});
        
     % get warp from optimal indeces
     nannodes = [];
     if isfield(inputs.mrf, 'excludeNodes') && ~isempty(inputs.mrf.excludeNodes)
         z = zeros(size(pDst, 1), 1);
         z(inputs.mrf.excludeNodes) = 1;
         z(z == 0) = quiltedpIdx;
         quiltedpIdx = z;
         nannodes = inputs.mrf.excludeNodes;
     end
     warp = idx2warp(quiltedpIdx, srcSize, patchSize, srcPatchOverlap, refgridsize, nannodes);
end
