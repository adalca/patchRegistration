function [vols, paths, params] = parseInputs(pathsFile, paramsFile, varargin)
% Parse input files as defined for nifti registration. 
% [vols, paths, params] = parseInputs(pathsFile, paramsFile)
% [vols, paths, params] = parseInputs(pathsFile, paramsFile, modifiers...)
%
% params are general -- as defined by patchreg
% paths should include nifti files

    assert(all(cellfun(@ischar, varargin)), 'all inputs must be strings');

    % load in config files
    paths = ini2struct(pathsFile);
    params = ini2struct(paramsFile);
    
    % evaluate any modifiers passed in
    % e.g. 'params.mrf.lambda_edge = 0.1';
    for i = 1:numel(varargin)
        eval(varargin{i}); 
    end
    
    % prepare nifti data
    vols = niftireg.prepareVolumes(paths, params);
    if iscell(vols.moving)
        assert(params.scale.nScales == numel(vols.moving), 'nScales don''t match');
    end
    