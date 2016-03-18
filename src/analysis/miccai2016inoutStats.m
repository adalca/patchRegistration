function [glmeanin, glmeanout] = miccai2016inoutStats(corepath, folders, params, inpath, ...
    subjNames, rawSubjFiletpl, segInRawFiletpl, inoutDesiredLabels, type)
% corepath = strokeoutpaths{pi};
    voxThr = 1.01;

    glmeanin = nan(numel(folders), 1);
    glmeanout = nan(numel(folders), 1);
    % go through existing folders
    for i = 1:numel(folders)
        % TODO: save meanin/meanout to stats. If it exists, load, otherwise compute.
        statsfile = fullfile(corepath, folders{i}, 'out/stats.mat');
        try 
            % asdsa
            % try is faster than 
            % if sys.isfile(statsfile) && numel(whos(matfile(statsfile), 'stats')) > 0
            % since matfile is slow
            load(statsfile, 'stats');
            assert(isclean(stats.meanin));
            assert(isclean(stats.meanout));
            
        catch
            fprintf('Gathering stats for %s\n', statsfile);
            subjName = subjNames{params(i, 1)};
            volfile = fullfile(inpath, subjName, sprintf(rawSubjFiletpl, subjName));
            selfname = sprintf(segInRawFiletpl, type, subjName, subjName, type);
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
            assert(isclean(stats.meanin));
            assert(isclean(stats.meanout));
            mkdir(fullfile(corepath, folders{i}, 'out'));
            if ~sys.isfile(statsfile)
                save(statsfile, 'stats');
            else
                save(statsfile, 'stats', '-append');
            end
        end
        glmeanin(i) = stats.meanin;
        glmeanout(i) = stats.meanout;
    end
    
    %assert(isclean(glmeanin));
    %assert(isclean(glmeanout));