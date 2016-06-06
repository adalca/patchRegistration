%% analyseIntermediateDice
% compare ventricle segmentations yielded by intermediate-scale PBR results compared to manual
% segmentations. 

%% Settings and paths
origPath = '/data/vision/polina/scratch/patchRegistration/input/stroke/proc/brain_pad10/';
runPath = '/data/vision/polina/scratch/patchRegistration/output/stroke/PBR_v63_brainpad/';
% runPath = '/data/vision/polina/scratch/patchRegistration/output/stroke/PBR_v605_brainpad_sym/';

subjlist = {'10537','10534','10530','10529','10522','14209','P0870','12191','P0054','P0180'};
maxScale = 1;

% string templates
autoSegInRaw = 'stroke61-seg-in-%s-raw_via_%s-2-stroke61-warp_via-scale%d.nii.gz';
diceAtScale = 'ven-dice-in-raw_via_%s-2-stroke61-warp_via-scale%d.nii.gz';

%% Gather Dice
dices = [];
settings = cell(1);
for i = 1:numel(subjlist)
    subj = subjlist{i};
    
    % get manual segmentation
    truesegFile = fullfile(origPath, subj, [subj, '_proc_ds7_ven_seg.nii.gz']);
    trueseg = nii2vol(truesegFile); % get volume not nii structure
    
    % go through different settings and get automatic segmentation
    d = sys.fulldir(fullfile(runPath, [subj, '*']));
    for si = 1:numel(d)
        % load auto seg file
        localname = sprintf(autoSegInRaw, subj, subj, maxScale);
        autoSegFile = fullfile(d(si).name, 'final', localname);
        if ~sys.isfile(autoSegFile)
            continue
        end
        autoseg = nii2vol(autoSegFile);

        % dice
        autosegVenMap = ismember(autoseg, [4, 43]);
        dce = dice(trueseg(:), autosegVenMap(:), 1);
        dices(i, si) = dce;

        % save dice
        diceFileName = sprintf(diceAtScale, subj, maxScale);
        save(diceFileName, 'dce');

        % some output, especially so that Andreea can understand it.
        parts = strsplit(d(si).name, '/');
        fprintf('done %25s. Dice: %3.2f\n', parts{end}, dce)        
        
        if i == 1
            settings{si} = strrep(parts{end}, subj, '');
        else
            assert(strcmp(settings{si}, strrep(parts{end}, subj, '')));
        end
    end
end
    
%% plot dice results
figure(); hold on;
boxplot(dices);
title(sprintf('Scale %d', maxScale));
set(gca, 'XTick', 1:numel(settings));
set(gca, 'XTickLabel', settings);
xticklabel_rotate([],90)
