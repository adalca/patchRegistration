function reg2statsnii(regfolder)

    % grab all folder names in regfolder
    folderNames = struct2cell(dir(regfolder));

    % load initial files
    for i = 3:size(folderNames, 2)
        try
            folder = folderNames{1, i};
            pathsFile = [regfolder, folder, '/paths.ini'];
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

            displ = niftireg.prepNiiToVol(fullfile(regfolder, folder, 'final', displFile));
            displInv = niftireg.prepNiiToVol(fullfile(regfolder, folder, 'final', displInvFile));
            sourceWarped = niftireg.prepNiiToVol(fullfile(regfolder, folder, 'final', sourceWarpedFile));
            targetWarped = niftireg.prepNiiToVol(fullfile(regfolder, folder, 'final', targetWarpedFile));
            sourceWarpedSeg = niftireg.prepNiiToVol(fullfile(regfolder, folder, 'final', sourceWarpedSegFile));
            targetWarpedSeg = niftireg.prepNiiToVol(fullfile(regfolder, folder, 'final', targetWarpedSegFile));
            sourceSeg = niftireg.prepNiiToVol(paths.sourceSegFile);
            targetSeg = niftireg.prepNiiToVol(paths.targetSegFile);

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

            savePath = [regfolder, folder, '/out/stats.mat'];
            % save stats
            % TODO: also need stats for subject to subjectraw
            save(savePath, 'dicesSource', 'dicelabels', 'jaccardsSource', 'jaccardlabels', 'dicesTarget', 'jaccardsTarget');
        catch err
            fprintf(1, 'skipping %d due to \n\t%s', i, err.identifier);
        end
    end
end