function reg2stats(regfolder, statsfile)

    % load initial file
    n00 = load(fullfile(regfolder, sprintf('%d_%d.mat', 0, 0)));      
    nScales = n00.params.nScales;
    nInnerReps = n00.params.nInnerReps;

    % data
    data = cell(nScales, nInnerReps);

    % stats
    times = zeros(nScales, nInnerReps);
    norms = cell(nScales, nInnerReps);
    normLocalDisplVol = cell(nScales, nInnerReps);
    normScaledLocalDisplVol = cell(nScales, nInnerReps);
    dices = cell(nScales, nInnerReps);
    dicelabels = cell(nScales, nInnerReps);
    jaccards = cell(nScales, nInnerReps);
    jaccardlabels = cell(nScales, nInnerReps);
    
    % go through iteration files
    alldicelabels = unique([n00.volumes.sourceSeg(:); n00.volumes.targetSeg(:)]);
    [dices{nScales+1, 1}, dicelabels{nScales+1, 1}] = ...
        dice(n00.volumes.sourceSeg, n00.volumes.targetSeg, alldicelabels);
    [jaccards{nScales+1, 1}, jaccardlabels{nScales+1, 1}] = ...
        jaccard(n00.volumes.sourceSeg, n00.volumes.targetSeg, alldicelabels);
    
    for s = 1:nScales
        for i = 1:nInnerReps
            
            % load volume
            data{s, i} = load(fullfile(regfolder, sprintf('%d_%d.mat', s, i)));

            % extract useful data
            times(s, i) = data{s, i}.state.runTime;
            norms{s, i} = data{s, i}.displVolumes.localDispl;

            % compute point-wise norms for localDispl and scaledLocalDispl
            dsquared = cellfunc(@(x) x.^ 2, data{s, i}.displVolumes.localDispl);
            normLocalDisplVol{s, i} = sqrt(sum(cat(4, dsquared{:}), 4));

            scaledLocalDispl = ...
                resizeWarp(data{s, i}.displVolumes.localDispl, size(data{s, i}.volumes.scSource)); 
            dsquared = cellfunc(@(x) x.^ 2, scaledLocalDispl);
            normScaledLocalDisplVol{s, i} = sqrt(sum(cat(4, dsquared{:}), 4));

            % compute displ
            wd = resizeWarp(data{s,i}.displVolumes.cdispl, size(n00.volumes.source));
            srcSegWarped = ...
                volwarp(n00.volumes.sourceSeg, wd, n00.opts.warpDir, 'interpmethod', 'nearest');
            [dices{s, i}, dicelabels{s, i}] = ...
                dice(srcSegWarped, n00.volumes.targetSeg, alldicelabels);
            [jaccards{s, i}, jaccardlabels{s, i}] = ...
                jaccard(srcSegWarped, n00.volumes.targetSeg, alldicelabels);
        end
    end

    % save stats
    save(statsfile, 'times', 'norms', 'normLocalDisplVol', 'dices', 'dicelabels', 'jaccards', 'jaccardlabels');
    