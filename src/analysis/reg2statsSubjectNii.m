function reg2statsSubjectNii(regfolder)
    try
        pathsFile = [regfolder, '/paths.ini'];
        paths = ini2struct(pathsFile);
        srcName = paths.sourceName;
        tgtName = paths.targetName;
        displName = sprintf('%s-2-%s-warp', srcName, tgtName);
        displInvName = sprintf('%s-2-%s-invWarp', srcName, tgtName);
        displFile = sprintf('%s.nii.gz', displName);
        displInvFile = sprintf('%s.nii.gz', displInvName);
        sourceWarpedFile = sprintf('%s-in-%s_via_%s.nii.gz', srcName, tgtName, displName);
        targetWarpedFile = sprintf('%s-in-%s_via_%s.nii.gz', tgtName, srcName, displInvName);
        sourceWarpedSegFile = sprintf('%s-seg-in-%s_via_%s.nii.gz', srcName, tgtName, displName);
        targetWarpedSegFile = sprintf('%s-seg-in-%s_via_%s.nii.gz', tgtName, srcName, displInvName);
        targetWarpedRawSegFile = sprintf('%s-seg-in-%s-raw_via_%s.nii.gz', tgtName, srcName, displInvName);

        displ = niftireg.prepNiiToVol(fullfile(regfolder, 'final', displFile));
        displInv = niftireg.prepNiiToVol(fullfile(regfolder, 'final', displInvFile));
        sourceWarped = niftireg.prepNiiToVol(fullfile(regfolder, 'final', sourceWarpedFile));
        targetWarped = niftireg.prepNiiToVol(fullfile(regfolder, 'final', targetWarpedFile));
        sourceWarpedSeg = niftireg.prepNiiToVol(fullfile(regfolder, 'final', sourceWarpedSegFile));
        targetWarpedSeg = niftireg.prepNiiToVol(fullfile(regfolder, 'final', targetWarpedSegFile));
        targetWarpedRawSeg = niftireg.prepNiiToVol(fullfile(regfolder, 'final', targetWarpedRawSegFile));
        sourceSeg = niftireg.prepNiiToVol(paths.sourceSegFile);
        targetSeg = niftireg.prepNiiToVol(paths.targetSegFile);
        sourceRawSeg = niftireg.prepNiiToVol(paths.sourceRawSegFile);

        % go through iteration files
        alldicelabels = unique([sourceSeg(:); targetSeg(:)]);
        [dicesSource, dicelabels] = ...
            dice(sourceWarpedSeg, targetSeg, alldicelabels);
        [jaccardsSource, jaccardlabels] = ...
            jaccard(sourceWarpedSeg, targetSeg, alldicelabels);
        [dicesTarget, dicelabels] = ...
            dice(targetWarpedSeg, sourceSeg, alldicelabels);
        [jaccardsTarget, jaccardlabels] = ...
            jaccard(targetWarpedSeg, sourceSeg, alldicelabels);
        [dicesRaw, dicelabels] = ...
            dice(targetWarpedRawSeg, sourceRawSeg, alldicelabels);

        savePath = [regfolder, '/out/stats.mat'];
        % save stats
        % TODO: also need stats for subject to subjectraw
        save(savePath, 'dicesSource', 'dicelabels', 'jaccardsSource', 'jaccardlabels', 'dicesTarget', 'jaccardsTarget', 'dicesRaw');
    catch err
        fprintf(1, 'skipping %d due to \n\t%s', i, err.identifier);
    end
end