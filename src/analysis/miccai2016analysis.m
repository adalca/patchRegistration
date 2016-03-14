%% Analyse and prepare data for the MICCAI 2016 submission of patch-based registration
% assumes data organization:
% /outpath/datatype/runname/subjid_param1_param2_.../
%   /final/datatype61-seg-in-%s-raw_via_%s-2-datatype61-invWarp.nii.gz
%   /final/datatype61-seg-in-%s_via_%s-2-datatype61-invWarp.nii.gz
%   /out/stats.amt
% /inpath/datatype/proc/brain_pad10/subjid/
%
% where datatype is buckner or stroke, runname is something like PBR_v5

%% setup paths
INPUT = '/data/vision/polina/scratch/patchRegistration/inputs/';
bucknerinpath = [INPUT, 'buckner/proc/brain_pad10/'];
strokeinpath = [INPUT, 'stroke/proc/brain_pad10/'];

OUTPATH = '/data/vision/polina/scratch/patchRegistration/output/';
bppath = [OUTPATH, 'buckner/sparse_ds7_pad10_lambdaedge_gridspacing_innerreps/'];
bapath = [OUTPATH, 'buckner/ANTs_v3_raw_fromDs7us7Reg_continueAffine_multiparam/'];
sppath = [OUTPATH, 'stroke/PBR_v5'];
sapath = [OUTPATH, 'stroke/ANTs_v3_raw_fromDs7us7Reg_continueAffine_multiparam']; %ANTs_v3_raw_fromDs7us7Reg_continueAffine_multiparam

saveImagesPath = '/data/vision/polina/scratch/patchRegistration/output/miccai2016figures';

buckneroutpaths = {bppath, bapath};
strokeoutpaths = {sppath, sapath};
bucknerpathnames = {'buckner-PBR', 'buckner-ANTs'};
strokepathnames = {'stroke-PBR', 'stroke-ANTs'};

segInRawFiletpl = '%s61-seg-in-%s-raw_via_%s-2-%s61-invWarp.nii.gz';
rawSubjFiletpl = '%s_proc_ds7.nii.gz';

segInSubjFiletpl = '%s61-seg-in-%s_via_%s-2-%s61-invWarp.nii.gz';
subjFiletpl = '%s_ds7_us7_reg.nii.gz';

%% settings
bucknerSelSubj = 'buckner03';
strokeSelSubj = '10534'; % 10530
nTrainSubj = 10;

desiredDiceLabels = [2, 3, 4, 17, 41, 42, 43, 53];
dicenames = {'LWM', 'LC', 'LV', 'LH', 'RWM', 'RC', 'RV', 'RH'};
dice4OverallPlots = cell(1, numel(desiredDiceLabels));

%% buckner analysis
for pi = 1:numel(buckneroutpaths)
    respath = buckneroutpaths{pi};
    
    % gather Dice parameters 
    [params, dices, dicelabels, subjNames, folders] = gatherDiceStats(respath, desiredDiceLabels, 1);
    nParams = size(params, 2);
    
    % select entries that belong to the first nTrainSubj subjects
    trainidx = params(:, 1) < nTrainSubj;
    testidx = ~trainidx;

    % get optimal parameters for training subjects
    [optParams, optDices] = optimalDiceParams(params(trainidx, 2:end), dices(trainidx, :), true);

    % select testing subjects dice values for those parameters.
    optsel = testidx & all(bsxfun(@eq, params(:, 2:end), optParams), 2);
    
    % some Dice plotting
    % plotMultiParameterDICE(params(trainidx, :), dices(trainidx, :), dicelabels, diceLabelNames, paramNames);
    % figure(); boxplot(dices(optsel, :)); hold on; grid on;
    % xlabel('Structure'); ylabel('DICE'); title(bucknerpathnames{pi});
    
    % prepare Dice of rest of subjects given top parameters
    for i = 1:numel(dice4OverallPlots)
        dice4OverallPlots{i} = [dice4OverallPlots{i}, dices(optsel, i)];
    end
    
    % show some example slices of outlines 
    subjnr = find(strcmp(subjNames, bucknerSelSubj));
    showSel = find(all(bsxfun(@eq, params, [subjnr, optParams]), 2));
    assert(numel(showSel) == 1, 'did not find the folder to show');
    % axial
    vol = nii2vol(fullfile(bucknerinpath, bucknerSelSubj, sprintf(rawSubjFiletpl, bucknerSelSubj)));
    selfname = sprintf(segInRawFiletpl, 'buckner', bucknerSelSubj, bucknerSelSubj, 'buckner');
    seg = nii2vol(fullfile(respath, folders{showSel}, 'final', selfname));
    seg(~ismember(seg, desiredDiceLabels)) = 0;
    [rgbImages, ~] = showVolStructures2D(vol, seg, {'axial'}); title(bucknerpathnames{pi});
    for im = 1:numel(rgbImages)
        imwrite(rgbImages{im}, fullfile(saveImagesPath, sprintf('%s_axial_%d',bucknerpathnames{pi}, im)));
    end 
    % saggital - here we want the interpolated volumes(maybe)
    vol = nii2vol(fullfile(bucknerinpath, bucknerSelSubj, sprintf(subjFiletpl, bucknerSelSubj)));
    selfname = sprintf(segInSubjFiletpl, 'buckner', bucknerSelSubj, bucknerSelSubj, 'buckner');
    seg = nii2vol(fullfile(respath, folders{showSel}, 'final', selfname));
    seg(~ismember(seg, desiredDiceLabels)) = 0;
    [rgbImage, ~] = showVolStructures2D(vol, seg, {'saggital'}); title(bucknerpathnames{pi});
    for im = 1:numel(rgbImages)
        imwrite(rgbImages{im}, fullfile(saveImagesPath, sprintf('%s_saggital_%d',bucknerpathnames{pi}, im)));
    end
end

% joint dice plotting
boxplotALMM(dice4OverallPlots, dicenames); grid on;
ylabel('DICE', 'FontSize', 28);
ylim([0.1,1]);
legend(bucknerpathnames(1:2));

%% stroke analysis 
glmeanin = cell(1, 2);
glmeanout = cell(1, 2);
for pi = 1:numel(strokeoutpaths)
    % get stroke folders
    [params, subjNames, folders] = gatherRunParams(strokeoutpaths{pi});
    glmeanin{pi} = nan(numel(folders), 1);
    glmeanout{pi} = nan(numel(folders), 1);
    
    % go through existing folders
    for i = 1:numel(folders)
        % TODO: save meanin/meanout to stats. If it exists, load, otherwise compute.
        statsfile = fullfile(strokeoutpaths{pi}, folders{i}, 'out/stats.mat');
        if sys.isfile(statsfile)
            load(statsfile, 'stats');
        else
            
            subjName = subjNames{params(i, 1)};
            volfile = fullfile(strokeinpath, subjName, sprintf(rawSubjFiletpl, subjName));
            selfname = sprintf(segInRawFiletpl, 'stroke', subjName, subjName, 'stroke');
            segfile = fullfile(strokeoutpaths{pi}, folders{i}, 'final', selfname);

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

            [stats.meanin, stats.meanout] = inoutStats(volnii, 3, segnii, desiredDiceLabels(3), true);
            mkdir(fullfile(strokeoutpaths{pi}, folders{i}, 'out'));
            save(statsfile, 'stats');
        end
        glmeanin{pi}(i) = stats.meanin;
        glmeanout{pi}(i) = stats.meanout;
    end
    
    % show optimal based on meanout - meanin
    subjnr = find(strcmp(subjNames, strokeSelSubj));
    [optParams, optDiffs] = optimalDiceParams(params(:, 2:end), glmeanout{pi} - glmeanin{pi}, true);
    showSel = find(all(bsxfun(@eq, params, [subjnr, optParams]), 2));
    % get and show axial images
    vol = nii2vol(fullfile(strokeinpath, strokeSelSubj, sprintf(rawSubjFiletpl, strokeSelSubj)));
    selfname = sprintf(segInRawFiletpl, 'stroke', strokeSelSubj, strokeSelSubj, 'stroke');
    seg = nii2vol(fullfile(strokeoutpaths{pi}, folders{showSel}, 'final', selfname));
    seg(~ismember(seg, desiredDiceLabels)) = 0;
    showVolStructures2D(vol, seg, {'axial'}); title(strokeoutpaths{pi});
    % saggital - here we want the interpolated volumes(maybe)
    vol = nii2vol(fullfile(strokeinpath, strokeSelSubj, sprintf(subjFiletpl, strokeSelSubj)));
    selfname = sprintf(segInSubjFiletpl, 'stroke', strokeSelSubj, strokeSelSubj, 'stroke');
    seg = nii2vol(fullfile(strokeoutpaths{pi}, folders{showSel}, 'final', selfname));
    seg(~ismember(seg, desiredDiceLabels)) = 0;
    showVolStructures2D(vol, seg, {'saggital'}); title(strokeoutpaths{pi});
end

diffcell = cellfunc(@(o,i) o(:)-i(:), glmeanout, glmeanin);
diffvec = cat(1, diffcell{:});
grp = [zeros(numel(diffcell{1}), 1); ones(numel(diffcell{2}), 1)];
figure(); plot(diffcell{1}, '.'); hold on; plot(diffcell{2}, '.'); title('Mean intensity diff around ventricles');
legend(strokepathnames);
figure(); boxplot(diffvec, grp); title('Mean intensity diff around ventricles');
xlabel('run or subject');
ylabel('out - in intensity diff');

