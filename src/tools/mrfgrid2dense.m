function denseWarp = mrfgrid2dense(sparseWarp, volsize, patchSize, patchOverlap)
% convert a sparse warp into a dense warp
    gridSpacing = patchSize - patchOverlap;
    gridIdx = patchlib.grid(volsize, patchSize, patchOverlap);
    
    denseWarp = cell(1, 3);
    for i = 1:size(sparseWarp, 2)
        denseWarp{i} = nan(volsize);
        denseWarp{i}(gridIdx) = sparseWarp{i} * gridSpacing(i);
        denseWarp{i} = inpaintn(denseWarp{i});
    end
end
