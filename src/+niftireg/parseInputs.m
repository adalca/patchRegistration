function [source, target, paths, params, opts] = ...
    parseInputs(pathsFile, paramsFile, optsFile, varargin)
% Parse input files as defined by nifti registration. Specifically, params and opts are general --
% as defined by patchreg. paths should include nifti files.


    % load in config files
    opts = ini2struct(optsFile);
    paths = ini2struct(pathsFile);
    params = ini2struct(paramsFile);
    
    if isnumeric(paths.sourceName), paths.sourceName = sprintf('%d', paths.sourceName); end
    if isnumeric(paths.targetName), paths.targetName = sprintf('%d', paths.targetName); end
    
    % process options
    params.nScales = size(params.gridSpacing, 1);
    if strcmp(opts.scaleMethod, 'load') % load option has 
        params.volPad = [0, 0, 0];
    end  
    opts.savefile = [paths.savepathout '/%d_%d.mat'];
    mkdir(paths.savepathfinal);
    mkdir(paths.savepathout);
    
    % evaluate any modifiers passed in
    % e.g. 'params.mrf.lambda_edge = 0.1';
    for i = 1:numel(varargin)
        eval(varargin{i});
    end
    
    % prepare nifti data
    [source, target, params.sourceMask, params.targetMask] = ...
            niftireg.prepareVolumes(paths, params.volPad, opts);
    if iscell(source)
        assert(params.nScales == numel(source), 'nScales don''t match');
    end
    