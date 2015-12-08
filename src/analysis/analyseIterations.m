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
IDs = {'736290.096482_gridSpacing3_3_3'};
IDs = {'736302.738655_gridSpacing3_3_3', '736303.072168_gridSpacing5_5_5', '736302.580069_gridSpacing9_9_9'};
IDs = {'736305.896896_gridSpacing5_5_5', '736305.900467_gridSpacing7_7_7', '736305.902631_gridSpacing3_3_3', '736305.936354_gridSpacing11_11_11'};

%% get parameters 
% obtain parameters using from the first file in the first id.
d = sys.fulldir(fullfile(MATPATH, IDs{1}, '*.mat'));
q = load(d(1).name);
nScales = q.params.nScales;
nInnerReps = q.params.nInnerReps;
    
%% TODO: I (Adrian) have now broken this. 
% Before, we used to compute all kinds of normalizations and volume warps *inside* the registration
% code. Instead, here we just assume we have the bare minimum dumped from the registration code, and
% we compute what is necessary here. This allows the code to be more modular and cleaner.

% debug
% scaledLocalDispl = resizeWarp(localDispl, size(source)); 
% normLocalDispl = cellfun(@(x) norm(x(:))/numel(x), localDispl);
% normScaledLocalDispl = cellfun(@(x) norm(x(:))/numel(x), scaledLocalDispl);
% normCurrentDispl = cellfun(@(x) norm(x(:))/numel(x), displ);
% 
% local = 1;
% searchPatch = ones(1, ndims(scSourceWarped)) .* local .* 2 + 1;
% sourceWarpedSegm = volwarp(scSourceSegm, displ, warpDir, 'interpmethod', 'nearest');
% diceCoeff = dice(sourceWarpedSegm, scTargetSegm);
% 
% normDispl = struct('local', normLocalDispl, 'scaledLocal', normScaledLocalDispl, 'current', normCurrentDispl);  
% volumes = struct('source', scSource, 'target', scTarget, 'sourceSegm', scSourceSegm, 'targetSegm', scTargetSegm, 'localDispl', {localDispl}, 'scaledLocalDispl', {scaledLocalDispl}, 'currentDispl', {displ});
% parameters = struct('patchSize', patchSize, 'searchPatch', searchPatch, 'patchOverlap', patchOverlap, 'nScales', nScales, 'nInnerReps', nInnerReps, 'inferMethod', infer_method, 'lambdaNode', 1, 'lambdaEdge', 1, 'inferenceThreshold', 10^-4);
% 
% % save things
% outputName = sprintf('%d_%d.mat', s, t);
% save([savePath outputName], 'volumes', 'tics', 'normDispl', 'diceCoeff', 'parameters');
% 
% % The following computations should be moved to analysis, not registration...
% % compute segmentation volumes but perhaps this is not necessary, but rather should be done only
% % when evaluating?
% scTargetSegm = volresize(debug.volumes.targetSegm, srcSize, 'nearest');
% scSourceSegm = volresize(debug.volumes.sourceSegm, trgSize, 'nearest');


%% gather data
times = zeros(numel(IDs), nScales, nInnerReps);
norms = cell(numel(IDs), nScales, nInnerReps);
dices = cell(numel(IDs), nScales, nInnerReps);
data = cell(numel(IDs), nScales, nInnerReps);
normLocalDisplVol = cell(numel(IDs), nScales, nInnerReps);
normScaledLocalDisplVol = cell(numel(IDs), nScales, nInnerReps);
for n = 1:numel(IDs)
    ID = IDs{n};
    n00 = load(fullfile(MATPATH, ID, sprintf('%d_%d.mat', 0, 0)));             
    
    for s = 1:nScales
        for i = 1:nInnerReps
            % load volume
            data{n, s, i} = load(fullfile(MATPATH, ID, sprintf('%d_%d.mat', s, i)));             
            
            % extract useful data
            times(n, s, i) = data{n, s, i}.state.runTime;
            norms{n, s, i} = data{n, s, i}.displVolumes.localDispl;


            %  = data{n, s, i}.diceCoeff;
            
            % compute point-wise norms for localDispl and scaledLocalDispl
            dsquared = cellfunc(@(x) x.^ 2, data{n, s, i}.displVolumes.localDispl);
            normLocalDisplVol{n, s, i} = sqrt(sum(cat(4, dsquared{:}), 4));

            scaledLocalDispl = resizeWarp(data{n, s, i}.displVolumes.localDispl, size(data{n, s, i}.volumes.scSource)); 
            dsquared = cellfunc(@(x) x.^ 2, scaledLocalDispl);
            normScaledLocalDisplVol{n, s, i} = sqrt(sum(cat(4, dsquared{:}), 4));
    
            % compute displ
            data{n,s,i}.opts.warpDirn = 'backward';
            scSrcSeg = volresize(n00.volumes.sourceSeg, data{n,s,i}.state.scSrcSize, 'nearest');
            scTarSeg = volresize(n00.volumes.targetSeg, data{n,s,i}.state.scTargetSize, 'nearest');
            scSrcSegWarped = volwarp(scSrcSeg, data{n,s,i}.displVolumes.cdispl, data{n,s,i}.opts.warpDirn, 'interpmethod', 'nearest');
            dices{n, s, i} = dice(scSrcSegWarped, scTarSeg);

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


%% Old Visualization code from patchreg.multiscale

% h = figuresc();
% himgs = {}; titles = {};
% % do some debug displaying for 2D data
% if ndims(source) == 2 %#ok<ISMAT>
%     titles = {titles{:}, 'warped source', 'target', 'prevdispl_y', 'prevdispl_x', ...
%         'localdispl_y', 'localdispl_x', 'displ_y', 'displ_x'};
%     localhimgs = {scSourceWarped, scTarget, dbdispl{:}, localDispl{:}, displ{:}};
%     himgs = {himgs{:}, localhimgs{:}};
%     
%     subgrid = [nScales, nInnerReps * numel(localhimgs)];
%     view2D(himgs, 'figureHandle', h, 'subgrid', subgrid, 'titles', titles);
%     
% elseif ndims(source) == 3
%     % TODO: measure amount of change in new localDispl
%     %dbdispl = resizeWarp(displ, size(source));
%     %view3Dopt(source, volwarp(source, dbdispl), target, dbdispl{:});
%     % TODO: do a 2d of mid-frame?
% end