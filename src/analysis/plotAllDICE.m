fpath = ['/data/vision/polina/scratch/adalca/patchSynthesis/data/buckner/ants/buckner*'];
d = sys.fulldir(fpath);

paramIdx = [17, 2, 3, 4, 53, 41, 42, 43];
diceScores = nan(8, numel(d));
times = nan(1, numel(d));
jaccardScores = nan(8, numel(d));
idx = nan(numel(d), 4);

for i = 1:numel(d)
    % first, get format. This is not general :(
    % use parameters in n00?
    [~, fname] = fileparts(d(i).name);
    z = strsplit(fname, '_');
    znr = str2num(z{1}(end-1:end));

    try
        n00 = load(fullfile(d(i).name, 'out', '0_0.mat'), 'params'); % 'mastertoc'
        sta = load(fullfile(d(i).name, 'out', 'stats.mat'), 'dicesSource', 'dicelabels', 'jaccardsSource', 'jaccardlabels');
    catch err
        fprintf(2, 'skipping %s because of \n %s\n', fname, err.message);
        continue;
    end

    % still hardcoded, need to fix
    idx(i, 1) = znr;
    idx(i, 2) = n00.params.mrf.lambda_edge;
    idx(i, 3) = n00.params.gridSpacing(end);
    idx(i, 4) = n00.params.nInnerReps;
%     times(i) = n00.mastertoc;
    for p = 1:numel(paramIdx)
%         diceScores(p, i) = sta.dices{n00.params.nScales, end}(sta.dicelabels{n00.params.nScales, end}(:) == paramIdx(p));
%         jaccardScores(p, i) = 1 - sta.jaccards{n00.params.nScales, end}(sta.jaccardlabels{n00.params.nScales, end}(:) == paramIdx(p));
        diceScores(p, i) = sta.dicesSource(sta.dicelabels(:) == paramIdx(p));
        jaccardScores(p, i) = 1 - sta.jaccardsSource(sta.jaccardlabels(:) == paramIdx(p));
    end
end

% do the plots

dicePlotLabels = {'dice LeftHippocampus', 'dice LeftCerebralWhiteMatter', 'dice LeftCerebralCortex', 'dice LeftLateralVentricle', 'dice RightHippocampus', 'dice RightCerebralWhiteMatter', 'dice RightCerebralCortex', 'dice RightLateralVentricle'};
jaccardPlotLabels = {'jaccard LeftHippocampus', 'jaccard LeftCerebralWhiteMatter', 'jaccard LeftCerebralCortex', 'jaccard LeftLateralVentricle', 'jaccard RightHippocampus', 'jaccard RightCerebralWhiteMatter', 'jaccard RightCerebralCortex', 'jaccard RightLateralVentricle'};

figure();
boxplot(times, idx(:,2)); hold on; grid on;
figure();
boxplot(times, idx(:,4)); hold on; grid on;

for param = 1:4
    f = figure();
    for labelIdx = 1:numel(paramIdx)
        subplot(2, 4, labelIdx);
        boxplot(diceScores(labelIdx, :), idx(:,param)); hold on; grid on;
%         if param==2 || param==4
            ylim([0.3, 1]);
%         end
    end
    
    ax = findobj(f,'Type','Axes');
    for i=1:length(ax)
        title(ax(i), dicePlotLabels{length(ax)-i+1})
    end
end

for param = 1:4
    f = figure();
    for labelIdx = 1:numel(paramIdx)
        subplot(2, 4, labelIdx);
        boxplot(jaccardScores(labelIdx, :), idx(:,param)); hold on; grid on;
        if param==2 || param==4
            ylim([0.3, 1]);
        end
    end

    ax = findobj(f,'Type','Axes');
    for i=1:length(ax)
        title(ax(i), jaccardPlotLabels{length(ax)-i+1})
    end
end
