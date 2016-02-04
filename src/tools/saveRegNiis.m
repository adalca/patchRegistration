function saveRegNiis(paths, volumes, displ, displInv)
    displFile = sprintf('%s_2_%s.nii.gz', paths.sourceName, paths.targetName);
    displInvFile = sprintf('%s_2_%s_inv.nii.gz', paths.sourceName, paths.targetName);
    sourceWarpedFile = sprintf('%s_in%s_via%s_2_%s.nii.gz', paths.sourceName, paths.targetName, paths.sourceName, paths.targetName);
    targetWarpedFile = sprintf('%s_in%s_via%s_2_%s_inv.nii.gz', paths.targetName, paths.sourceName, paths.sourceName, paths.targetName);
    sourceWarpedSegFile = sprintf('%s_seg_in%s_via%s_2_%s.nii.gz', paths.sourceName, paths.targetName, paths.sourceName, paths.targetName);
    targetWarpedSegFile = sprintf('%s_seg_in%s_via%s_2_%s_inv.nii.gz', paths.targetName, paths.sourceName, paths.sourceName, paths.targetName);
    
    saveNii(make_nii(cat(5, displ{:})), [paths.savepathnii displFile]);
    saveNii(make_nii(cat(5, displInv{:})), [paths.savepathnii displInvFile]);
    saveNii(make_nii(volumes.sourceWarped), [paths.savepathnii sourceWarpedFile]);
    saveNii(make_nii(volumes.targetWarped), [paths.savepathnii targetWarpedFile]);
    saveNii(make_nii(volumes.sourceWarpedSeg), [paths.savepathnii sourceWarpedSegFile]);
    saveNii(make_nii(volumes.targetWarpedSeg), [paths.savepathnii targetWarpedSegFile]);
end