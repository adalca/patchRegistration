function [params, subjNames, folders] = gatherRunParams(path, verbose)
% Gather Dice Data for the registration project.
%
% see gatherDiceStats.m
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

    narginchk(1, 2);
    if nargin < 2, verbose = false; end

    % get folders in path
    d = dir(path);
    
    % extract all folder names
    folders = {d.name};
    isfolder = cellfun(@(s) isdir(fullfile(path,s)) && (numel(regexpi(s, '.+_'))~=0), folders);
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
        params(i, 1) = find(strcmp(C{1}, subjNames));
        params(i, 2:end) = cat(2, C{2:end});
    end
    