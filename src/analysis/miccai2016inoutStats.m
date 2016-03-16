function [glmeanin, glmeanout] = miccai2016inoutStats(corepath, folders, params, inpath, ...
    subjNames, rawSubjFiletpl, segInRawFiletpl, inoutDesiredLabels)
% corepath = strokeoutpaths{pi};
    voxThr = 5;

    glmeanin = nan(numel(folders), 1);
    glmeanout = nan(numel(folders), 1);
    % go through existing folders
    for i = 1:numel(folders)
        % TODO: save meanin/meanout to stats. If it exists, load, otherwise compute.
        statsfile = fullfile(corepath, folders{i}, 'out/stats.mat');
        if sys.isfile(statsfile)
            load(statsfile, 'stats');
        else

            subjName = subjNames{params(i, 1)};
            volfile = fullfile(inpath, subjName, sprintf(rawSubjFiletpl, subjName));
            selfname = sprintf(segInRawFiletpl, 'stroke', subjName, subjName, 'stroke');
            segfile = fullfile(corepath, folders{i}, 'final', selfname);

            if ~sys.isfile(volfile)
                fprintf(2, 'Skipping %s due to missing %s\n', folders{i}, volfile);
                continue;
            end

            if ~sys.isfile(segfile)
                fprintf(2, 'Skipping %s due to missing %s\n', folders{i}, segfile);
                continue;
            end

            volnii = loadNii(volfile);
            segnii = loadNii(segfile);

            [stats.meanin, stats.meanout] = inoutStats(volnii, voxThr, segnii, inoutDesiredLabels, true);
            mkdir(fullfile(corepath, folders{i}, 'out'));
            save(statsfile, 'stats');
        end
        glmeanin(i) = stats.meanin;
        glmeanout(i) = stats.meanout;
    end