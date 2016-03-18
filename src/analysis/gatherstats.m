

fpath = ['/data/vision/polina/scratch/patchRegistration/output/', ...
    'runs_span_at4Scales_lambdaedge_gridspacing_innerreps/buckner*'];
d = sys.fulldir(fpath);

data = nan(1, numel(d));
idx = nan(numel(d), 4);
for i = 1:numel(d)
    % first, get format. This is not general :(
    % use parameters in n00?
    [~, fname] = fileparts(d(i).name);
    z = strsplit(fname, '_');
    znr = str2num(z{1}(end-1:end));
    znr
%     if znr > 1
%         break;
%     end
    
    try
        n00 = load(fullfile(d(i).name, 'out', '0_0.mat'), 'params');
        sta = load(fullfile(d(i).name, 'out', 'stats.mat'), 'dices', 'dicelabels');
    catch
        
        fprintf('skipping %s\n', fname);
        continue;
    end
    
    % n00.params.gridSpacing
    % d(i).name
    
    % still hardcoded, need to fix
    idx(i, 1) = znr;
    idx(i, 2) = n00.params.mrf.lambda_edge;
    idx(i, 3) = n00.params.gridSpacing(end);
    idx(i, 4) = n00.params.nInnerReps;
    
    data(i) = sta.dices{n00.params.nScales, end}(sta.dicelabels{n00.params.nScales, end}(:) == 4);
    
    % is this final?
end
%% compute medians
ids = unique(idx(:, 1));
ids(isnan(ids)) = [];
un = cellfunc(@unique, dimsplit(2, idx(:, 2:4)));
un = cellfunc(@(x) x(~isnan(x)), un);
nd = ndgrid2cell(un{:});

for i = 1:numel(nd{1})
    % get location in 3d matrix of parameters
    loc = cellfunc(@(x, u) find(x(i) == u), nd, un');
    ind = sub2ind(size(nd{1}), loc{:}); % ind in a 3-d matrix
    
    % get locations in data matrix
    c = cellfunc(@(x, y) x(i) == y, nd, dimsplit(2, idx(:, 2:4))');
    dataind = sum(cat(2, c{:}), 2) == 3;
    assert(sum(dataind) <= numel(ids));
    medians(ind) = data(ind);
end


%% plot
s = idx(:, 4) == 4;

% take mean accross idx 1, then plot dice vs lambda_edge vs gridSpacing in 3d
figure();
plot3(idx(s, 2), idx(s, 3), data(s), '.'); 
xlabel('lambda_edge'); ylabel('gridSpacing'); zlabel('dice');

%%
figure();
s = true; 
c1 = s & idx(:, 3) == 3 & idx(:, 4) == 2;
c2 = s & idx(:, 3) == 3 & idx(:, 4) == 4;
subplot(1, 2, 1);
plot(idx(c1, 2), data(c1), '.'); hold on;
plot(idx(c2, 2), data(c2), '.');
xlabel('lambdaEdge'); ylabel('dice'); 
legend({'2 inner reps', '4 inner reps'});

c1 = s & idx(:, 2) == 0.01 & idx(:, 4) == 2;
c2 = s & idx(:, 2) == 0.01 & idx(:, 4) == 4;
subplot(1, 2, 2);
plot(idx(c1, 3), data(c1), '.'); hold on;
plot(idx(c2, 3), data(c2), '.');
xlabel('gridSpacing'); ylabel('dice'); 
legend({'2 inner reps', '4 inner reps'});


%%



% esp plot
plot(idx(idx(:, 4)==2, 2), data(idx(:, 4)==2), '.'); hold on; 
plot(idx(idx(:, 4)==4, 2), data(idx(:, 4)==4), '.'); 
xlabel('lambda_edge');
ylabel('dice of one ventrile');
legend({'2 inner reps', '4 inner reps'});

