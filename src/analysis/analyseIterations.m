%% analyseIterations
% Analyze iteration runtimes and effect on final results (most norm of displacement contributions
% for now)

%% setup
MATPATH = 'D:\Downloads\';
ID = '736288.7041';

% get all of the matrfiles
d = sys.fulldir(fullfile(MATPATH, [ID, '*.mat']));
q = load(d(1).name);
nScales = q.parameters.nScales;
nInnerReps = q.parameters.nInnerReps;

%% gather data
times = cell(nScales, nInnerReps);
norms = cell(nScales, nInnerReps);
data = cell(nScales, nInnerReps);
for s = 1:nScales
    for i = 1:nInnerReps
        data{s, i} = load([MATPATH, sprintf('%s_%d_%d.mat', ID, s, i)]);             
        times{s, i} = data{s, i}.tics;
        norms{s, i} = data{s, i}.normDispl.local;
    end
end

% compute point-wise norms for localDispl and scaledLocalDispl
for s = 1:nScales
    for i = 1:nInnerReps
        dsquared = cellfunc(@(x) x.^ 2, data{s, i}.volumes.localDispl);
        normLocalDisplVol{s, i} = sqrt(sum(cat(4, dsquared{:}), 4));
        
        dsquared = cellfunc(@(x) x.^ 2, data{s, i}.volumes.scaledLocalDispl);
        normScaledLocalDisplVol{s, i} = sqrt(sum(cat(4, dsquared{:}), 4));
        
    end
end


%% visualize

% visualize histograms
figuresc(); 
for s = 1:nScales
    for i = 1:nInnerReps
        subplot(nScales, nInnerReps, sub2ind([nInnerReps, nScales], i, s));
        hist(normLocalDisplVol{s, i}(:));
        title(sprintf('hist(norm(localDispl))) \n %s scale:%d iter:%d', ID, s, i)); 
    end
end

% visualize
figuresc(); hold on;
subplot(1, 3, 1); title('times'); ylabel('seconds'); hold on;
subplot(1, 3, 2); title('mean local displacement norm'); hold on;
subplot(1, 3, 3); title('mean scaled local displacement norm'); hold on;

% TODO: should really pre-compute mean norm accross dimensions.
for s = 1:nScales
    scaletimes = [times{s, :}];
    scaleLocalNorms = cellfun(@(x) mean(x(:)), normLocalDisplVol(s, :));
    scaleScaledLocalNorms = cellfun(@(x) mean(x(:)), normScaledLocalDisplVol(s, :));
    
    
    subplot(1, 3, 1); 
    plot((s-1) * nInnerReps  + (1:nInnerReps), scaletimes, '.-'); 
    
    subplot(1, 3, 2); 
    plot((s-1) * nInnerReps  + (1:nInnerReps), scaleLocalNorms, '.-'); 
    
    subplot(1, 3, 3); 
    plot((s-1) * nInnerReps  + (1:nInnerReps), scaleScaledLocalNorms, '.-'); 
end

