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
miccai2016analysisPaths

%% settings
nTrainSubj = 10;
bucknerSelSubj = '101411';
% goodish for both: 23
doInOutAnalysis = false;

nUpscale = [3, 3, 1];
segThickness = 6;

inoutDesiredLabels = [4, 43];
desiredDiceLabels = [2, 3, 4, 41, 42, 43];
dicenames = {'Left White Matter', 'Left Cortex', 'Left Ventricle', 'Right White Matter', 'Right Cortex', 'Right Ventricle'};

%% buckner analysis
dice4OverallPlots = cell(1, numel(desiredDiceLabels));
glmeanin = cell(1, 2);
glmeanout = cell(1, 2);
for pi = 1:numel(buckneroutpaths)
    respath = buckneroutpaths{pi};
    
    % gather Dice parameters 
    [params, dices, dicelabels, subjNames, folders] = gatherDiceStats(respath, desiredDiceLabels, 1);
    
    % select entries that belong to the first nTrainSubj subjects
    trainidx = params(:, 1) < nTrainSubj;
    testidx = ~trainidx;

    % get optimal parameters for training subjects
    [optParams, bestDices] = optimalDiceParams(params(trainidx, 2:end), dices(trainidx, :), true);

    % select testing subjects dice values for those parameters.
    optsel = testidx & all(bsxfun(@eq, params(:, 2:end), optParams), 2);
    
    % some Dice plotting
    % plotMultiParameterDICE(params(trainidx, :), dices(trainidx, :), dicelabels, diceLabelNames, paramNames);
    % figure(); boxplot(dices(optsel, :)); hold on; grid on;
    % xlabel('Structure'); ylabel('DICE'); title(bucknerpathnames{pi});
    
    % prepare Dice of rest of subjects given top parameters
    for i = 1:numel(dice4OverallPlots)
        if pi == 1, dice4OverallPlots{i} = dices(optsel, i); 
        else q = nan(max(size(dice4OverallPlots{i}, 1), sum(optsel)), size(dice4OverallPlots{i}, 2) + 1);
            q(1:size(dice4OverallPlots{i}, 1), 1:size(dice4OverallPlots{i}, 2)) = dice4OverallPlots{i};
            q(1:sum(optsel), size(dice4OverallPlots{i}, 2) + 1) = dices(optsel, i);
            dice4OverallPlots{i} = q;
        end
        % dice4OverallPlots{i} = [dice4OverallPlots{i}, dices(optsel, i)];
    end
    
    % show some example slices of outlines 
    subjnr = find(strcmp(subjNames, bucknerSelSubj));
    showSel = find(all(bsxfun(@eq, params, [subjnr, optParams]), 2));
    assert(numel(showSel) == 1, 'did not find the folder to show');
    
%     % axial - use the raw volumes
%     vol = nii2vol(fullfile(bucknerinpath, bucknerSelSubj, sprintf(rawSubjFiletpl, bucknerSelSubj)));
%     selfname = sprintf(segInRawFiletpl, 'ADNI_T1_baselines', bucknerSelSubj, bucknerSelSubj, 'ADNI_T1_baselines');
%     seg = nii2vol(fullfile(respath, folders{showSel}, 'final', selfname));
%     seg(~ismember(seg, desiredDiceLabels)) = 0;
%     [rgbImages, ~] = showVolStructures2D(vol, seg, {'axial'}, nUpscale, segThickness, 1); title(bucknerpathnames{pi});
%     foldername = sprintf('%s/%s_%s/', saveImagesPath, bucknerpathnames{pi}, bucknerSelSubj); mkdir(foldername);
%     miccai2016saveFrames(rgbImages, fullfile(foldername, 'axial_%d.png'));

%     % saggital - here we want the interpolated volumes
%     vol = nii2vol(fullfile(bucknerinpath, bucknerSelSubj, sprintf(subjFiletpl, bucknerSelSubj)));
%     selfname = sprintf(segInSubjFiletpl, 'ADNI_T1_baselines', bucknerSelSubj, bucknerSelSubj, 'ADNI_T1_baselines');
%     seg = nii2vol(fullfile(respath, folders{showSel}, 'final', selfname));
%     seg(~ismember(seg, desiredDiceLabels)) = 0;
%     [rgbImages, ~] = showVolStructures2D(vol, seg, {'saggital'}, nUpscale, segThickness, 1); title(bucknerpathnames{pi});
%     miccai2016saveFrames(rgbImages, fullfile(foldername, 'saggital_%d.png'));
%     
    % gather intensity differences around ventricles
    if doInOutAnalysis
        [glmeanin{pi}, glmeanout{pi}] = miccai2016inoutStats(buckneroutpaths{pi}, folders, params, bucknerinpath, ...
            subjNames, rawSubjFiletpl, segInRawFiletpl, inoutDesiredLabels, 'buckner');
        assert(size(glmeanin{pi}, 1) == size(params, 1));
    end
end

%% plot dice vs ventricle difference
if doInOutAnalysis
    diffcell = cellfunc(@(o,i) o(:)-i(:), glmeanout, glmeanin);  
    % diffsel = diffcell{2}(optsel, :);
    % vdice = mean([dice4OverallPlots{3}, dice4OverallPlots{6}], 2);
    diffsel = diffcell{2};
    vdice = sum(dices(:, [3, 6]), 2);
    nonnan = ~isnan(diffsel) & ~isnan(vdice);
    figure(); plot(diffsel, vdice, '.'); xlabel('diff'); ylabel('Dice'); hold on;
    p = polyfit(diffsel(nonnan), vdice(nonnan), 1);
    x = [min(diffsel), max(diffsel)]; plot(x, polyval(p, x));
    title(sprintf('cc: %5.3f', corr(diffsel(nonnan), vdice(nonnan))));
end

%% joint dice plotting
save([saveImagesPath, '/adniDiceData.mat'], 'dice4OverallPlots', 'dicenames', 'bucknerpathnames');

% combine left and right
dice4OverallPlotsHalf = dice4OverallPlots;
nDiceHalf = numel(dicenames) / 2;
dicenamesHalf = dicenames(1:nDiceHalf); 
dicenamesHalf = cellfunc(@(d) strrep(d, 'Left ', ''), dicenamesHalf);
for i = 1:nDiceHalf
    dice4OverallPlotsHalf{i} = [dice4OverallPlotsHalf{i}; dice4OverallPlotsHalf{i+nDiceHalf}];
end
dice4OverallPlotsHalf(nDiceHalf+1:end) = [];

% plot
dicePlot = boxplotALMM(dice4OverallPlotsHalf, dicenamesHalf); grid on;
ylabel('Volume Overlap (Dice)', 'FontSize', 28);
ylim([0.01,1]);
legend(bucknerpathnames(1:2));

export_fig(dicePlot, fullfile(saveImagesPath, 'BucknerDicePlot'), '-pdf', '-transparent');
