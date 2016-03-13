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
INPUT = '/data/vision/polina/scratch/patchRegistration/output/';
bucknerinpath = [INPUT, 'buckner/proc/brain_pad10/'];
strokeinpath = [INPUT, 'stroke/proc/brain_pad10/'];

OUTPATH = '/data/vision/polina/scratch/patchRegistration/output/';
bppath = [OUTPATH, 'buckner/sparse_ds7_pad10_lambdaedge_gridspacing_innerreps/'];
bapath = [OUTPATH, 'buckner/ANTs_v3_multiparams/'];
sppath = [OUTPATH, 'stroke/PBR_v5'];
sapath = [OUTPATH, 'stroke/ANTs_v3_multiparams'];

inpaths = {bucknerinpath, strokepath, bucknerinpath, strokepath};
outpaths = {bppath, bapath, sppath, sapath};
pathnames = {'buckner-PBR', 'buckner-ANTs', 'stroke-PBR', 'stroke-ANTs'};
atlname = {'buckner', 'buckner', 'stroke', 'stroke'};

showsubjid = 3;

%% buckner analysis
for pi = 1:numel(outpaths)
    respath = outpaths{pi};
    
    % gather dice parameters 
    [params, dices, dicelabels, subjNames, folders] = gatherDiceStats(respath);
    nParams = size(params, 2);
    
    % select entries that belong to the first 10 subjects
    trainidx = params(:, 1) < 10;

    % plot dice
    % plotMultiParameterDICE(params(trainidx, :), dices(trainidx, :), dicelabels, diceLabelNames, paramNames);

    % get optimal parameters for those entries
    optParams = optimalDiceParams(params(trainidx, 2:end), dice(trainidx, :));
    fprintf('best parameter options are:');
    fprintf('%f ', bestParams);
    fprintf('\n');

    % select dice values for those parameters.
    optsel = all(bsxfun(@eq, params(:, 2:end), bestParams), 2);
    
    % show DICE of rest of subjects given top parameters
    dicesel = dice(optsel, :);
    figure(); boxplot(dicesel); hold on; grid on;
    xlabel('Structure'); ylabel('DICE'); 
    
    % show some example slices of outlines 
    % use labelOutlines() below to extract outlines from propagated atlas segmentations
    showSel = find(all(bsxfun(@eq, params, [showsubjid, bestParams]), 2));
    assert(numel(showSel) == 1, 'did not find the folder to show');
    vol = nii2vol(fullfile(inpaths{pi}, subjNames{showsubjid}, [subjNames{showsubjid}, '_proc_ds7.nii.gz']));
    fname = sprintf('%s61-seg-in-%s-raw_via_%s-to-%s61-invWarp.nii.gz', atlname{pi}, subjNames{showsubjid}, atlname{pi}, subjNames{showsubjid});
    seg = nii2vol(fullfile(respath, folder(showsel), fname));
    sliceNr = round(size(vol, 3)/2);
    rgbImage = overlapVolSeg(vol(:,:,sliceNr), seg(:,:,sliceNr));
    figure(); imagesc(rgbImage);
end
