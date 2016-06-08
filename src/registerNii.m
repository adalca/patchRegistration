function displ = registerNii(varargin)
% patch-based discrete registration
% - pathsFile is a .ini file that contains all necessary paths
% - paramsFile is a .ini file that contains all the necessary parameters,
% - varargin takes in optional files for sourceMask and targetMask, in case
% registration is sparse

    % parse inputs
    [vols, paths, params] = niftireg.parseInputs(varargin{:});
    
    % Patch Registration    
    displ = patchreg.multiscale(vols, params);

    % save niftis if necessary
    niftireg.displ2niftis(displ, vols.moving, vols.fixed, paths, params);
end
