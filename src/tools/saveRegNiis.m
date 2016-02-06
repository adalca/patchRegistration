function saveRegNiis(paths, volumes, displ, displInv)
    displFile = sprintf('%s_2_%s.nii.gz', paths.sourceName, paths.targetName);
    displInvFile = sprintf('%s_2_%s_inv.nii.gz', paths.sourceName, paths.targetName);
    sourceWarpedFile = sprintf('%s_in%s_via%s_2_%s.nii.gz', paths.sourceName, paths.targetName, paths.sourceName, paths.targetName);
    targetWarpedFile = sprintf('%s_in%s_via%s_2_%s_inv.nii.gz', paths.targetName, paths.sourceName, paths.sourceName, paths.targetName);
    sourceWarpedSegFile = sprintf('%s_seg_in%s_via%s_2_%s.nii.gz', paths.sourceName, paths.targetName, paths.sourceName, paths.targetName);
    targetWarpedSegFile = sprintf('%s_seg_in%s_via%s_2_%s_inv.nii.gz', paths.targetName, paths.sourceName, paths.sourceName, paths.targetName);
    sourceRawSegFile = sprintf('%s_warped_seg_in%s_via%s_reg_2_%s_.nii.gz', paths.sourceName, paths.sourceName, paths.sourceName, paths.sourceName);
    
    displNii = make_nii(cat(5, displ{:}));
    displInvNii = make_nii(cat(5, displInv{:}));
    sourceWarpedNii = make_nii(volumes.sourceWarped);
    targetWarpedNii = make_nii(volumes.targetWarped);
    sourceWarpedSegNii = make_nii(volumes.sourceWarpedSeg);
    targetWarpedSegNii = make_nii(volumes.targetWarpedSeg);
    sourceRawSegNii = make_nii(volumes.sourceRawSeg);
    
    saveNii(displNii, [paths.savepathnii displFile]);
    saveNii(displInvNii, [paths.savepathnii displInvFile]);
    saveNii(sourceWarpedNii, [paths.savepathnii sourceWarpedFile]);
    saveNii(targetWarpedNii, [paths.savepathnii targetWarpedFile]);
    saveNii(sourceWarpedSegNii, [paths.savepathnii sourceWarpedSegFile]);
    saveNii(targetWarpedSegNii, [paths.savepathnii targetWarpedSegFile]);
    
    % source in this case should be the subj_reg
    movingSourceWarpedSeg = double(sourceWarpedSegNii.img);
    movingSourceWarpedSegDims = sourceWarpedSegNii.hdr.dime.pixdim(2:4);
    rMovingSourceWarpedSeg = imref3d(size(movingSourceWarpedSeg), movingSourceWarpedSegDims(2), movingSourceWarpedSegDims(1), movingSourceWarpedSegDims(3));

    % fixed here hsould be the original subject space
    fixedSource = double(sourceRawSegNii.img);
    fixedSourceDims = sourceRawSegNii.hdr.dime.pixdim(2:4);
    rFixedSource = imref3d(size(fixedSource), fixedSourceDims(2), fixedSourceDims(1), fixedSourceDims(3));

    % tform is loaded from the .mat file i told you about
    load(paths.displRaw);
    movedSourceWarpedSeg = imwarp(movingSourceWarpedSeg, rMovingSourceWarpedSeg, tform.invert, interpMethod, 'OutputView', rFixedSource);
    saveNii(make_nii(movedSourceWarpedSeg), [paths.savepathnii, sourceRawSegFile]);
end