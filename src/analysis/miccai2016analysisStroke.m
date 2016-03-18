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

segInRawFiletpl = '%s61-seg-in-%s-raw_via_%s-2-%s61-invWarp.nii.gz';
rawSubjFiletpl = '%s_proc_ds7.nii.gz';

segInSubjFiletpl = '%s61-seg-in-%s_via_%s-2-%s61-invWarp.nii.gz';
subjFiletpl = '%s_ds7_us7_reg.nii.gz';


nTrainSubj = 10;
strokeSelSubj = '14209'; % 10530
% bad one: 10534
% catastrofic failure for ANTs: 10530

inoutDesiredLabels = [4, 43];
desiredDiceLabels = [2, 3, 4, 41, 42, 43];
dicenames = {'Left White Matter', 'Left Cortex', 'Left Ventricle', 'Right White Matter', 'Right Cortex', 'Right Ventricle'};

%% stroke analysis 
glmeanin = cell(1, 2); glmeanout = cell(1, 2);
glparams = cell(1, 2); glsubjNames = cell(1, 2);
for pi = 1:numel(strokeoutpaths)
    % get stroke folders
    [params, subjNames, folders] = gatherRunParams(strokeoutpaths{pi});
    glparams{pi} = params; 
    glsubjNames{pi} = subjNames;
    
    % get in out paths
    [glmeanin{pi}, glmeanout{pi}] = miccai2016inoutStats(strokeoutpaths{pi}, folders, params, strokeinpath, ...
        subjNames, rawSubjFiletpl, segInRawFiletpl, inoutDesiredLabels, 'stroke');
    
    % show optimal based on meanout - meanin
    subjnr = find(strcmp(subjNames, strokeSelSubj));
    optParams = optimalDiceParams(params(:, 2:end), glmeanout{pi} - glmeanin{pi}, true);
    showSel = find(all(bsxfun(@eq, params, [subjnr, optParams]), 2));
    
    % axial - use the raw volumes
%     vol = nii2vol(fullfile(strokeinpath, strokeSelSubj, sprintf(rawSubjFiletpl, strokeSelSubj)));
%     selfname = sprintf(segInRawFiletpl, 'stroke', strokeSelSubj, strokeSelSubj, 'stroke');
%     seg = nii2vol(fullfile(strokeoutpaths{pi}, folders{showSel}, 'final', selfname));
%     seg(~ismember(seg, desiredDiceLabels)) = 0;
%     [rgbImages, ~] = showVolStructures2D(vol, seg, {'axial'}, 6, 3, 1); title(strokeoutpaths{pi});
%     foldername = sprintf('%s/%s_%s', saveImagesPath, strokepathnames{pi}, strokeSelSubj); mkdir(foldername);
%     for imnr = 1:size(rgbImages, 4)
%         imwrite(rgbImages(:, :, :, imnr), fullfile(foldername, sprintf('axial_%d.png', imnr)));
%     end
    
    % saggital - here we want the interpolated volumes
%     vol = nii2vol(fullfile(strokeinpath, strokeSelSubj, sprintf(subjFiletpl, strokeSelSubj)));
%     selfname = sprintf(segInSubjFiletpl, 'stroke', strokeSelSubj, strokeSelSubj, 'stroke');
%     seg = nii2vol(fullfile(strokeoutpaths{pi}, folders{showSel}, 'final', selfname));
%     seg(~ismember(seg, desiredDiceLabels)) = 0;
%     [rgbImages, ~] = showVolStructures2D(vol, seg, {'saggital'}, 6, 3, 1); title(strokeoutpaths{pi});
%     for imnr = 1:size(rgbImages, 4)
%         imwrite(rgbImages(:, :, :, imnr), fullfile(foldername, sprintf('saggital_%d.png', imnr)));
%     end 
end

%% plots
% only work on common stuff.
[ia, ib, ic] = intersect(glsubjNames{1}, glsubjNames{2});
p1 = glparams{1} == ib;
p2 = glparams{2} == ic;







save([saveImagesPath, '/strokePlotData.mat'], 'glmeanout', 'glmeanin', 'strokepathnames');
diffcell = cellfunc(@(o,i) o(:)-i(:), glmeanout, glmeanin);
diffvec = cat(1, diffcell{:});

% different plot
f1 = figure(); plot(diffcell{1}, '.'); hold on; plot(diffcell{2}, '.'); 
legend(strokepathnames);
xlabel('run or subject');
ylabel('out - in intensity diff');
title('Mean intensity diff around ventricles');
export_fig(f1, fullfile(saveImagesPath, 'MeanIntensity'), '-pdf', '-transparent');

f2 = figure(); 
grp = [zeros(numel(diffcell{1}), 1); ones(numel(diffcell{2}), 1)];
boxplot(diffvec, grp); 

% dice plot
f2 = figure(); hold on;
set(0,'DefaultTextFontname', 'CMU Serif')
set(0,'DefaultAxesFontName', 'CMU Serif')
set(0,'DefaultTextFontname', 'Garamond')
set(0,'DefaultAxesFontName', 'Garamond')
b = boxplot(diffcell{1}, 'colors', [0 0.447 0.741]); set(b, 'LineWidth', 3); set(findobj(gca, 'Type', 'text'), 'FontSize', 18);
b = boxplot([zeros(numel(diffcell{2}), 1)-100, diffcell{2}], 'Labels', {}, 'colors', [0.85 0.325 0.098]);  set(b, 'LineWidth', 3); set(findobj(gca, 'Type', 'text'), 'FontSize', 18);
ylim([min(diffvec)*1.1, max(diffvec)*1.1]);


xlabel('');
ylabel('out - in intensity diff');
title('Mean intensity diff around ventricles');

set(gca, 'XTickLabel', []);
set(gca, 'XTickLabel', {'ANTs', 'Patch based MRF'}, 'FontSize', 22);
drawnow;
export_fig(f2, fullfile(saveImagesPath, 'MeanIntensityBox'), '-pdf', '-transparent');
