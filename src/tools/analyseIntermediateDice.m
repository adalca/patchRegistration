%% analyseIntermediateDice
% compare ventricle segmentations yielded by intermediate-scale PBR results compared to manual
% segmentations. 

%% Settings and paths
origPath = '/data/vision/polina/scratch/patchRegistration/input/stroke/proc/brain_pad10/';
runPath = '/data/vision/polina/scratch/patchRegistration/output/stroke/PBR_v63_brainpad/';
runPath = '/data/vision/polina/scratch/patchRegistration/output/stroke/PBR_v605_brainpad_sym/';
runPath = '/data/vision/polina/scratch/patchRegistration/output/stroke/PBR_v605_brainpad_scale3/';

% list of subjects
subjlist = {'10537','10534','10530','10529','10522','14209','P0870','12191','P0054','P0180'};

% string templates
autoSegInRaw = 'stroke61-seg-in-%s-raw_via_%s-2-stroke61-warp_via-scale%d.nii.gz';
diceAtScale = 'ven-dice-in-raw_via_%s-2-stroke61-warp_via-scale%d.nii.gz';

% scale setting
maxScale = 3;

% ventricle labels in registration segmentation map (warped from atlas)
venLabels = [4, 43];

%% Gather Dice
dices = [];
settings = cell(1);
for i = 1:numel(subjlist)
    subj = subjlist{i};
    
    % get manual segmentation
    truesegFile = fullfile(origPath, subj, [subj, '_proc_ds7_ven_seg.nii.gz']);
    trueseg = nii2vol(truesegFile); % get volume not nii structure
    
    % go through different settings and get automatic segmentation
    dashes = ['*[*', repmat('-*', [1, maxScale-1]), ']*'];
    d = sys.fulldir(fullfile(runPath, [subj, dashes]));
    if i == 1
        dices = nan(numel(subjlist), numel(d));
    end
    for si = 1:numel(d)
        fullfileparts = strsplit(d(si).name, '/');
        newset = strrep(fullfileparts{end}, subj, '');
        if i == 1, settings{si} = newset; end
        
        % load auto seg file
        localname = sprintf(autoSegInRaw, subj, subj, maxScale);
        autoSegFile = fullfile(d(si).name, 'final', localname);
        if ~sys.isfile(autoSegFile)
            continue
        end
        autoseg = nii2vol(autoSegFile);

        % dice
        autosegVenMap = ismember(autoseg, venLabels);
        dce = dice(trueseg(:), autosegVenMap(:), 1);
        dices(i, si) = dce;

        % save dice
        diceFileName = sprintf(diceAtScale, subj, maxScale);
        save(diceFileName, 'dce');

        % some output, especially so that Andreea can understand it.
        fprintf('done %35s. Dice: %3.2f\n', fullfileparts{end}, dce)        
        
        % make sure the settings are consistent across subjects.
        if i > 1
            prevset = settings{si};
            assert(strcmp(prevset, newset), ...
                'original setting %s not the same as current setting %s', ...
                prevset, newset);
        end
    end
end
    
%% plot dice results
f = figure(); hold on;
[maxdiceMedian, mi] = max(nanmedian(dices));
plot([1, size(dices,2)], maxdiceMedian * [1, 1], '-', 'color', [1,1,1]*0.75);
bar(mi, 1, 'FaceColor', [1,1,1]*0.75, 'EdgeColor', [1,1,1]*0.75);
boxplot(dices, 'labels', repmat({''}, [1, numel(settings)])); % not labeling with settings.
title(sprintf('Scale %d. Max Dice Median: %3.2f', maxScale, maxdiceMedian));
set(gca, 'XTick', 1:numel(settings));
set(gca, 'XTickLabel', settings);
xticklabel_rotate([], 90)
ylim([0,1]);

nNans = sum(isnan(dices));
% add missing data
for i = 1:numel(nNans)
    if nNans(i) > 0
        text(i-0.5, max(dices(:, i)), sprintf('%d NANs', nNans(i)), 'Color', 'red');
    end
end
