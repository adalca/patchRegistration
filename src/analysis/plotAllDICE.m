fpath = ['/data/vision/polina/scratch/patchRegistration/output/', ...
'runs_sparse_span_at4Scales_lambdaedge_gridspacing_innerreps/buckner*'];
d = sys.fulldir(fpath);

data = nan(1, numel(d));
datajaccard = nan(1, numel(d));
idx = nan(numel(d), 4);
for i = 1:numel(d)
    % first, get format. This is not general :(
    % use parameters in n00?
    [~, fname] = fileparts(d(i).name);
    z = strsplit(fname, '_');
    znr = str2num(z{1}(end-1:end));

    try
        n00 = load(fullfile(d(i).name, 'out', '0_0.mat'), 'params');
        sta = load(fullfile(d(i).name, 'out', 'stats.mat'), 'dices', 'dicelabels', 'jaccards', 'jaccardlabels');
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
    datajaccard(i) = sta.jaccards{n00.params.nScales, end}(sta.jaccardlabels{n00.params.nScales, end}(:) == 4);
end