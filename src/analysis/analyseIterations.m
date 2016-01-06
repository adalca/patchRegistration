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
IDs = {'buckner21_736314.108727', 'buckner21_736314.408502', 'buckner21_736314.547912', 'buckner21_736314.645597' ,'buckner21_736314.670990_LE0.01_LN5.00_gs1_2_2_3__ireps2'}
IDs = {'buckner21_736314.697553_LE0.05_LN5.00_gs1_2_2_3_3_3__ireps2', 'buckner03_736314.955567_LE0.05_LN5.00_gs1_2_2_3_3_3__ireps2'};
d = dir('D:\Dropbox (MIT)\Research\patchRegistration\output\*_LE0.05_LN5.00_gs1_2_2_3_3_3*');
IDs = {d.name};

IDs = {'buckner21_736315.310004_LE0.05_LN5.00_gs1_2_2_3_3_3__ireps2', 'buckner21_736315.503964_LE0.05_LN5.00_gs1_2_2_3_3_3__ireps2', 'buckner21_736315.595589_LE0.05_LN5.00_gs1_2_2_3_3_3__ireps2'};

%% get parameters 
% obtain parameters using from the first file in the first id.
d = sys.fulldir(fullfile(MATPATH, IDs{1}, '*.mat'));
q = load(d(2).name);
nScales = q.params.nScales;
nInnerReps = q.params.nInnerReps;

%% gather data
% % TODO: use reg2stats.
% times = zeros(numel(IDs), nScales, nInnerReps);
% norms = cell(numel(IDs), nScales, nInnerReps);
% dices = cell(numel(IDs), nScales, nInnerReps);
% dicelabels = cell(numel(IDs), nScales, nInnerReps);
% data = cell(numel(IDs), nScales, nInnerReps);
% normLocalDisplVol = cell(numel(IDs), nScales, nInnerReps);
% normScaledLocalDisplVol = cell(numel(IDs), nScales, nInnerReps);
% 
% n00 = cell(1, numel(IDs));
% for n = 1:numel(IDs)
%     ID = IDs{n};
%     n00{n} = load(fullfile(MATPATH, ID, sprintf('%d_%d.mat', 0, 0)));             
%     alldicelabels = unique([n00{n}.volumes.sourceSeg(:); n00{n}.volumes.targetSeg(:)]);
%     [dices{n, nScales+1, 1}, dicelabels{n, nScales+1, 1}] = dice(n00{n}.volumes.sourceSeg, n00{n}.volumes.targetSeg, alldicelabels);
%     
%     for s = 1:nScales
%         for i = 1:nInnerReps
%             % load volume
%             data{n, s, i} = load(fullfile(MATPATH, ID, sprintf('%d_%d.mat', s, i)));             
%             
%             % extract useful data
%             times(n, s, i) = data{n, s, i}.state.runTime;
%             norms{n, s, i} = data{n, s, i}.displVolumes.localDispl;
% 
%             % compute point-wise norms for localDispl and scaledLocalDispl
%             dsquared = cellfunc(@(x) x.^ 2, data{n, s, i}.displVolumes.localDispl);
%             normLocalDisplVol{n, s, i} = sqrt(sum(cat(4, dsquared{:}), 4));
% 
%             scaledLocalDispl = resizeWarp(data{n, s, i}.displVolumes.localDispl, size(data{n, s, i}.volumes.scSource)); 
%             dsquared = cellfunc(@(x) x.^ 2, scaledLocalDispl);
%             normScaledLocalDisplVol{n, s, i} = sqrt(sum(cat(4, dsquared{:}), 4));
%     
%             % compute displ
%             wd = resizeWarp(data{n,s,i}.displVolumes.cdispl, size(n00{n}.volumes.source));
%             srcSegWarped = volwarp(n00{n}.volumes.sourceSeg, wd, n00{n}.opts.warpDir, 'interpmethod', 'nearest');
%             [dices{n, s, i}, dicelabels{n, s, i}] = dice(srcSegWarped, n00{n}.volumes.targetSeg, alldicelabels);
%         end
%     end
% end

%%
% v = [];
% for s = 1:nScales
%     for i = 1:nInnerReps
%         % rescale warp
%         w = resizeWarp(data{n, s, i}.displVolumes.cdispl, size(n00{n}.volumes.source));
%         v{i, s} = volwarp(n00{n}.volumes.source, w, n00{n}.opts.warpDir);
%         smallv{i, s} = volresize(data{n,s,i}.volumes.scSourceWarped, size(n00{n}.volumes.source), 'nearest');
%     end
%     view3Dopt([n00{n}.volumes.source; v(:, s); smallv(:, s); w(:)]);
%     pause();
%     caf;
% end
% view3Dopt([n00{n}.volumes.source, v(:)']);

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

idnames = cellfunc(@(id, p) sprintf('%s l_n:%3.2f l_e:%3.2f', id, p.params.mrf.lambda_node, p.params.mrf.lambda_edge), IDs, n00);
legend(idnames);

%%
plotDICEsubplots(idnames, n00, dices, dicelabels, 23); % all labels
plotDICEsubplots(idnames, n00, dices, dicelabels, 24, [4, 43]) % ventricles
plotDICEsubplots(idnames, n00, dices, dicelabels, 25, [17, 53]) % hippocampus

%%
speclabels = {alldicelabels, [4, 43], [17, 53], [2, 41], [3, 42]};
plotDICEfinals(IDs, n00, dices, dicelabels, 31, speclabels);
set(gca, 'xTickLabels', {'all', 'ventricles', 'hippocampi', 'white-matter', 'cortex'});

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