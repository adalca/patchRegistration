function [params, dices, dicelabels, subjNames] = gatherDiceStats(path)
% [params, dices, dicelabels] = gatherDiceStats(path)
%
% given a parent folder, go through each folder assuming the naming
%   /fullpath/name_param1_param2_param3
%   example:
%   /fullpath/buckner01_0.01_3_1
% this example has 4 "parameters" - a subject number and 3 parameters 
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
    isfolder = cellfun(@(s) ~strcmp(s(1), '.'), folders);
    folders = folders(isfolder);
    nRuns = numel(folders);
    
    % extract all subject Names
    names = cellfunc(@(s) strsplit(s, '_'), folders);
    nParams = numel(names{1});
    subjNames = unique(cellfunc(@(s) s{1}, names));
    
    % go through each folder
    params = nan(nRuns, nParams);
    for i = 1:nRuns
        
        % parse folder name, should be string_float_float_...
        C = strsplit(folders{i}, '_');
        C(2:end) = cellfunc(@(x) str2double(x), C(2:end));
        
        % assign parameters
        nParams(i, 1) = find(strcmp(C{1}, subjNames));
        nParams(i, 2:end) = cat(2, C{2:end});
        
        % load dice.
        statsfile = fullfile(path, folders{i}, 'out', 'stats.mat');
        q = load(statsfile, 'dices', 'finalLabels');
        
        % for now, assume finalLabels is the same for everyone. Should make
        % this more flexible?
        if i == 1, 
            dicelabels = q.finalLabels;
            dices = nan(nRuns, size(dicelabels));
        else
            msg = 'for now, assume finalLabels is the same for everyone';
            assert(all(dicelabels == q.finalLabels), msg);
        end
        dices(i, :) = q.dices;
    end
    