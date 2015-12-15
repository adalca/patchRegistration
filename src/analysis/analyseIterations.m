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
IDs = {'736305.902631_gridSpacing3_3_3', '736305.896896_gridSpacing5_5_5', '736305.900467_gridSpacing7_7_7', '736305.936354_gridSpacing11_11_11'};
IDs = {'736305.896896_gridSpacing5_5_5', '736305.963139_gridSpacing5_5_5'};
IDs = {'736306.814598', '736306.822436'};
IDs = {'736306.827685', '736306.837518'};
IDs = {'736307.753497', '736307.761347', '736307.769803', '736307.774934', '736307.778891'};
IDs = {'736307.834847', '736307.887335'};
IDs = {'736308.385976'};%, 
IDs = {'736308.479164'};
IDs = {'736308.665375', '736308.793910'}

%% get parameters 
% obtain parameters using from the first file in the first id.
d = sys.fulldir(fullfile(MATPATH, IDs{1}, '*.mat'));
q = load(d(2).name);
nScales = q.params.nScales;
nInnerReps = q.params.nInnerReps;

%% gather data
times = zeros(numel(IDs), nScales, nInnerReps);
norms = cell(numel(IDs), nScales, nInnerReps);
dices = cell(numel(IDs), nScales, nInnerReps);
dicelabels = cell(numel(IDs), nScales, nInnerReps);
data = cell(numel(IDs), nScales, nInnerReps);
normLocalDisplVol = cell(numel(IDs), nScales, nInnerReps);
normScaledLocalDisplVol = cell(numel(IDs), nScales, nInnerReps);

n00 = cell(1, numel(IDs));
for n = 1:numel(IDs)
    ID = IDs{n};
    n00{n} = load(fullfile(MATPATH, ID, sprintf('%d_%d.mat', 0, 0)));             
    alldicelabels = unique([n00{n}.volumes.sourceSeg(:); n00{n}.volumes.targetSeg(:)]);
    [dices{n, nScales+1, 1}, dicelabels{n, nScales+1, 1}] = dice(n00{n}.volumes.sourceSeg, n00{n}.volumes.targetSeg, alldicelabels);
    
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
            wd = resizeWarp(data{n,s,i}.displVolumes.cdispl, size(n00{n}.volumes.source));
            srcSegWarped = volwarp(n00{n}.volumes.sourceSeg, wd, n00{n}.opts.warpDir, 'interpmethod', 'nearest');
            [dices{n, s, i}, dicelabels{n, s, i}] = dice(srcSegWarped, n00{n}.volumes.targetSeg, alldicelabels);
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
plotDICEsubplots(IDs, n00, dices, dicelabels, 23); % all labels
plotDICEsubplots(IDs, n00, dices, dicelabels, 24, [4, 43]) % ventricles
plotDICEsubplots(IDs, n00, dices, dicelabels, 25, [17, 53]) % hippocampus


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