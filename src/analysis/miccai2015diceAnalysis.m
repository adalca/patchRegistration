% Buckner
% Gather DICE analysis from BUCKNER PBR, 
% select all entries that belong to the first 20 subjects, 
% and select the top parameters
% show DICE of rest of subjects given top parameters
% show some example slices of outlines 
% use labelOutlines() below to extract outlines from propagated atlas segmentations
% use 
% Repeat for ANTs 

%% setup paths
INPUT = '/data/vision/polina/scratch/patchRegistration/inputs/';
bucknerinpath = [INPUT, 'buckner/proc/brain_pad10/'];
strokeinpath = [INPUT, 'stroke/proc/brain_pad10/'];

OUTPATH = '/data/vision/polina/scratch/patchRegistration/output/';
bppath = [OUTPATH, 'buckner/sparse_ds7_pad10_lambdaedge_gridspacing_innerreps/'];
bapath = [OUTPATH, 'buckner/ANTs_v3_raw_fromDs7us7Reg_continueAffine_multiparam/'];
sppath = [OUTPATH, 'stroke/PBR_v5'];
sapath = [OUTPATH, 'stroke/ANTs_v2_raw_fromDs7us7Reg_continueAffine']; %ANTs_v3_raw_fromDs7us7Reg_continueAffine_multiparam

buckneroutpaths = {bppath, bapath};
strokeoutpaths = {sppath, sapath};
bucknerpathnames = {'buckner-PBR', 'buckner-ANTs'};
strokepathnames = {'stroke-PBR', 'stroke-ANTs'};
atlname = {'buckner', 'buckner', 'stroke', 'stroke'};

showsubjid = 3;

desiredDiceLabels = [2, 3, 4, 17, 41, 42, 43, 53];
dicenames = {'LWM', 'LC', 'LV', 'LH', 'RWM', 'RC', 'RV', 'RH'};
diceForPlots = cell(1, numel(desiredDiceLabels));

%% buckner analysis
for pi = 1:numel(buckneroutpaths)
    respath = buckneroutpaths{pi};
    
    % gather dice parameters 
    [params, dices, dicelabels, subjNames, folders] = gatherDiceStats(respath);
    
    % clean up dice labels
    [~, ix] = intersect(dicelabels, desiredDiceLabels);
    dices = dices(:, ix);
    dicelabels = dicelabels(ix);
    nParams = size(params, 2);
    nanind = find(all(isnan(dices), 2));
    fprintf('Did not run:\n'); 
    for i = 1:numel(nanind), fprintf('%s ', subjNames{params(nanind(i), 1)}); fprintf('%f ', params(nanind(i), :)); fprintf('\n'); end
    
    % select entries that belong to the first 10 subjects
    trainidx = params(:, 1) < 10;

    % plot dice
    % plotMultiParameterDICE(params(trainidx, :), dices(trainidx, :), dicelabels, diceLabelNames, paramNames);

    % get optimal parameters for those entries
    [optParams, optDices] = optimalDiceParams(params(trainidx, 2:end), dices(trainidx, :));
    fprintf('best parameter options are:\n');
    for i = 1:(nParams-1)
        fprintf('%f (%f)\n', optParams(i), optDices(i));
    end
    fprintf('\n');

    % select dice values for those parameters.
    optsel = all(bsxfun(@eq, params(:, 2:end), optParams), 2);
    
    % show DICE of rest of subjects given top parameters
    dicesel = dices(optsel, :);
    figure(); boxplot(dicesel); hold on; grid on;
    xlabel('Structure'); ylabel('DICE'); title(bucknerpathnames{pi});
    for i = 1:numel(diceForPlots)
        diceForPlots{i} = [diceForPlots{i}, dicesel(:, i)];
    end
    
    % show some example slices of outlines 
    % use labelOutlines() below to extract outlines from propagated atlas segmentations
    showSel = find(all(bsxfun(@eq, params, [showsubjid, optParams]), 2));
    assert(numel(showSel) == 1, 'did not find the folder to show');
    volfilename = fullfile(bucknerinpath, subjNames{showsubjid}, [subjNames{showsubjid}, '_proc_ds7.nii.gz']);
    vol = nii2vol(volfilename);
    fname = sprintf('%s61-seg-in-%s-raw_via_%s-2-%s61-invWarp.nii.gz', 'buckner', subjNames{showsubjid}, subjNames{showsubjid}, 'buckner');
    seg = nii2vol(fullfile(respath, folders{showSel}, 'final', fname));
    seg(~ismember(seg, desiredDiceLabels)) = 0;
    colors = jitter(numel(unique(seg(:))));
    seglabels = unique(seg(:)); seglabels(seglabels == 0) = [];
    rgbImage = cell(1); slices = 1:size(vol, 3); 
    for sii = 1:numel(slices)
        si = slices(sii);
        rgbImage{sii} = overlapVolSeg(vol(:,:,si), seg(:,:,si), colors, seglabels, 1);
    end
    view2D(rgbImage);
    title(bucknerpathnames{pi});
    
end

% joint dice plotting
boxplotALMM(diceForPlots, dicenames);
ylabel('DICE', 'FontSize', 28);
legend(bucknerpathnames(1:2));


%% stroke analysis 
meanin = nan(numel(folders), 2);
meanout = nan(numel(folders), 2);
for pi = 1:numel(buckneroutpaths)
    % get stroke folders
    [params, subjNames, folders] = gatherRunParams(strokeoutpaths{pi});
    
    % compute in/out.
    for i = 1:numel(folders)
        i
        try
            sid = params(i, 1);
            volfilename = fullfile(strokeinpath, subjNames{sid}, [subjNames{sid}, '_proc_ds7.nii.gz']);
            fname = sprintf('%s61-seg-in-%s-raw_via_%s-2-%s61-invWarp.nii.gz', 'stroke', subjNames{sid}, subjNames{sid}, 'stroke');
            maskVol = fullfile(strokeoutpaths{pi}, folders{i}, 'final', fname);
            [meanin(i, pi), meanout(i, pi)] = inoutStats(volfilename, 3, maskVol, desiredDiceLabels(3), true);
        catch err
            err.message
        end
    end
end

figure(); plot(meanout - meanin, '.'); title('Mean intensity diff around ventricles');
legend(strokepathnames);
xlabel('run/subject');
ylabel('out - in intensity diff');
