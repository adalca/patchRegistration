% Buckner
% Gather DICE analysis from BUCKNER PBR, 
% select all entries that belong to the first 20 subjects, 
% and select the top parameters
% show DICE of rest of subjects given top parameters
% show some example slices of outlines 
% use labelOutlines() below to extract outlines from propagated atlas segmentations
% use 
% Repeat for ANTs 

path = '/data/vision/polina/scratch/patchRegistration/output/buckner/sparse_ds7_pad10_lambdaedge_gridspacing_innerreps/';
[params, dices, dicelabels, subjNames] = gatherDiceStats(path);
plotMultiParameterDICE(params(size(params,1)/2, :), dices(size(params,1)/2, :), dicelabels, diceLabelNames, paramNames);

bigParams = repmat(params, [size(dices, 2) ,1]);
bigDices = reshape(dices, [numel(dices),1]);  

for param = 1:size(params,2)
    stats = grpstats(dices,params(:,param),'mean');
end