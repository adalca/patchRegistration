%% analyseIterations
% Analyze iteration runtimes and effect on final results (most norm of displacement contributions
% for now)
%
% all of the ids ran at once in this file should have the same nScales and nInnerReps

%% setup
% set the paths and IDs of desired subjects
if ispc
    MATPATH = 'D:\Dropbox (MIT)\Research\patchRegistration\output\';
else
    MATPATH = '/data/vision/polina/scratch/abobu/patchRegistration/output/';
end
IDs = {'736289.773576_gridSpacing3_3_3', '736289.777921_gridSpacing2_2_2', '736289.079323_gridSpacing1_1_1'};

%% get parameters 
% obtain parameters using from the first file in the first id.
d = sys.fulldir(fullfile(MATPATH, IDs{1}, '*.mat'));
q = load(d(1).name);
nScales = q.parameters.nScales;
nInnerReps = q.parameters.nInnerReps;
    
%% gather data
times = zeros(numel(IDs), nScales, nInnerReps);
norms = cell(numel(IDs), nScales, nInnerReps);
dices = cell(numel(IDs), nScales, nInnerReps);
data = cell(numel(IDs), nScales, nInnerReps);
normLocalDisplVol = cell(numel(IDs), nScales, nInnerReps);
normScaledLocalDisplVol = cell(numel(IDs), nScales, nInnerReps);
for n = 1:numel(IDs)
    ID = IDs{n};
    for s = 1:nScales
        for i = 1:nInnerReps
            data{n, s, i} = load(fullfile(MATPATH, ID, sprintf('%d_%d.mat', s, i)));             
            times(n, s, i) = data{n, s, i}.tics;
            norms{n, s, i} = data{n, s, i}.normDispl.local;
            dices{n, s, i} = data{n, s, i}.diceCoeff;
        end
    end

    % compute point-wise norms for localDispl and scaledLocalDispl
    for s = 1:nScales
        for i = 1:nInnerReps
            dsquared = cellfunc(@(x) x.^ 2, data{n, s, i}.volumes.localDispl);
            normLocalDisplVol{n, s, i} = sqrt(sum(cat(4, dsquared{:}), 4));

            dsquared = cellfunc(@(x) x.^ 2, data{n, s, i}.volumes.scaledLocalDispl);
            normScaledLocalDisplVol{n, s, i} = sqrt(sum(cat(4, dsquared{:}), 4));
        end
    end
end

%% visualize

% visualize histograms
for n = 1:numel(IDs)
    figure(1 + n); hold on;
    for s = 1:nScales
        for i = 1:nInnerReps
            subplot(nScales, nInnerReps, sub2ind([nInnerReps, nScales], i, s));
            hist(normLocalDisplVol{n, s, i}(:));
            title(sprintf('hist(norm(localDispl))) \n %s scale:%d iter:%d', IDs{n}, s, i)); 
        end
    end
end

% visualize
figure(1); hold on;
subplot(1, 3, 1); title('times'); ylabel('log(seconds)'); hold on;
subplot(1, 3, 2); title('mean local displacement norm'); hold on;
subplot(1, 3, 3); title('mean scaled local displacement norm'); hold on;


% TODO: should really pre-compute mean norm accross dimensions? N/S
for s = 1:nScales
    scaletimes = squeeze(times(:, s, :));
    scaleLocalNorms = squeeze(cellfun(@(x) mean(x(:)), normLocalDisplVol(:, s, :)));
    scaleScaledLocalNorms = squeeze(cellfun(@(x) mean(x(:)), normScaledLocalDisplVol(:, s, :)));

    subplot(1, 3, 1); ax = gca; ax.ColorOrderIndex = 1;
    pt = plot((s-1) * nInnerReps  + (1:nInnerReps), log(scaletimes)', '.-'); 

    subplot(1, 3, 2); ax = gca; ax.ColorOrderIndex = 1;
    pn = plot((s-1) * nInnerReps  + (1:nInnerReps), scaleLocalNorms', '.-'); 

    subplot(1, 3, 3); ax = gca; ax.ColorOrderIndex = 1; 
    psn = plot((s-1) * nInnerReps  + (1:nInnerReps), scaleScaledLocalNorms', '.-'); 
end

legend(IDs);

%%
figure(23); hold on;
for n = 1:numel(IDs)
    ID = IDs{n};
    subplot(numel(IDs), 1, n); title(sprintf('DICE %s', ID)); hold on;
    clear scalemeandice grp;
        
    for s = 1:nScales
        % plot DICE
        % unclear what to do yet - dice for which label? doing mean for now, but that's pretty limited.
        % perhaps do boxplot of all dice?
%         subplot(1, 3, 4); ax = gca; ax.ColorOrderIndex = 1; 
        
        for i = 1:nInnerReps
            idx = (s-1)*nInnerReps + i;
            scalemeandice{idx} = dices{n, s, i};
            grp{idx} = (idx) * ones(1, numel(scalemeandice{idx}));
        end
    end
    scalemeandice = cat(2, scalemeandice{:});
    grp = cat(2, grp{:});
    boxplot(scalemeandice, grp); hold on;
    
end
