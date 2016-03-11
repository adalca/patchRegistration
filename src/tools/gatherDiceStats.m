function [params, dices, dicelabels, subjNames] = gatherDiceStats(path)
% Gather Dice Data for the registration project.
%
% given a parent path, go through each folder assuming the naming
%   /fullpath/name_param1_param2_param3
%   example:
%   /fullpath/buckner01_0.01_3_1
% this example has 4 "parameters" - a subject number and 3 parameters 
% note the number of parameters isn't fixed. Let's call it nParams
%
% then, gather the dice data from 
%   /fullpath/name_param1_param2_param3/out/stats.mat
% which includes variables: 'dices', and 'finalLabels'
%   
% 
% params is a nRuns-by-nParams matrix of numbers.
% dices is a nRuns-by-nLabels matrix of dice scores
% diceLabels is a nLabels vector of dice ids.
% subjNames is a cell array of containing the subject names extracted from the file names. 
%    so when the first parameter (the subject nr) is 1, the name of that subjet is subjNames{1}

    % get folders in path
    d = dir(path);
    
    % extract all folder names
    folders = {d.name};
    isfolder = cellfun(@(s) isdir(fullfile(path,s)) && ~strcmp(s(1), '.'), folders);
    folders = folders(isfolder);
    nRuns = numel(folders);
    
    % extract all subject Names
    names = cellfunc(@(s) strsplit(s, '_'), folders);
    nParams = numel(names{1});
    subjNames = unique(cellfunc(@(s) s{1}, names));
    
    % go through each folder
    params = nan(nRuns, nParams);
    alldices = cell(nRuns, 1);
    alldicelabels = cell(nRuns, 1);
    for i = 1:nRuns
        
        % parse folder name, should be string_float_float_...
        C = strsplit(folders{i}, '_');
        C(2:end) = cellfunc(@(x) str2double(x), C(2:end));
        
        % assign parameters
        params(i, 1) = find(strcmp(C{1}, subjNames));
        params(i, 2:end) = cat(2, C{2:end});
        
        % load dice scores and labels
        statsfile = fullfile(path, folders{i}, 'out', 'stats.mat');
        try
            q = load(statsfile, 'dices', 'finalLabels');
            alldices{i} = q.dices(:);
            alldicelabels{i} = q.finalLabels(:);
        catch err
            fprintf(1, 'skipping %d due to \n\t%s', double(params(i, 1)), err.identifier);
        end
    end
    
    % get unique labels
    dicelabels = unique(cat(1, alldicelabels{:}));
    
    % assign dices in the appropriate places
    dices = nan(nRuns, numel(dicelabels));
    for i = 1:nRuns
        [~, ia] = intersect(dicelabels, alldicelabels{i});
        dices(i, ia) = alldices{i}';
    end
    