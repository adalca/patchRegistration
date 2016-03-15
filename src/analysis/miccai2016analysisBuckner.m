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
bucknerSelSubj = 'buckner03';

desiredDiceLabels = [2, 3, 4, 41, 42, 43];
dicenames = {'Left White Matter', 'LC', 'LV', 'RWM', 'RC', 'RV'};

%% buckner analysis
dice4OverallPlots = cell(1, numel(desiredDiceLabels));
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
    
    % axial - use the raw volumes
    vol = nii2vol(fullfile(bucknerinpath, bucknerSelSubj, sprintf(rawSubjFiletpl, bucknerSelSubj)));
    selfname = sprintf(segInRawFiletpl, 'buckner', bucknerSelSubj, bucknerSelSubj, 'buckner');
    seg = nii2vol(fullfile(respath, folders{showSel}, 'final', selfname));
    seg(~ismember(seg, desiredDiceLabels)) = 0;
    [rgbImages, ~] = showVolStructures2D(vol, seg, {'axial'}); title(bucknerpathnames{pi});
    foldername = sprintf('%s/%s_%s', saveImagesPath, bucknerpathnames{pi}, bucknerSelSubj); mkdir(foldername);
    for imnr = 1:size(rgbImages, 4)
        imwrite(rgbImages(:, :, :, imnr), fullfile(foldername, sprintf('axial_%d.png', imnr)));
    end
    
    % saggital - here we want the interpolated volumes
    vol = nii2vol(fullfile(bucknerinpath, bucknerSelSubj, sprintf(subjFiletpl, bucknerSelSubj)));
    selfname = sprintf(segInSubjFiletpl, 'buckner', bucknerSelSubj, bucknerSelSubj, 'buckner');
    seg = nii2vol(fullfile(respath, folders{showSel}, 'final', selfname));
    seg(~ismember(seg, desiredDiceLabels)) = 0;
    [rgbImage, ~] = showVolStructures2D(vol, seg, {'saggital'}); title(bucknerpathnames{pi});
    for imnr = 1:size(rgbImages, 4)
        imwrite(rgbImages(:, :, :, imnr), fullfile(foldername, sprintf('saggital_%d.png', imnr)));
    end
end

%% joint dice plotting
save([saveImagePath, '/bucknerDiceData.mat'], 'dice4OverallPlots', 'dicenames', 'bucknerpathnames');
dicePlot = boxplotALMM(dice4OverallPlots, dicenames); grid on;
ylabel('Volume Overlap (Dice)', 'FontSize', 28);
ylim([0.1,1]);
legend(bucknerpathnames(1:2));
export_fig(dicePlot, fullfile(saveImagesPath, 'BucknerDicePlot'), '-pdf', '-transparent');
