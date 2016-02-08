function displ = registerNii(pathsFile, paramsFile, optsFile, varargin)
% patch-based discrete registration
% - pathsFile is a .ini file that contains all necessary paths
% - paramsFile is a .ini file that contains all the necessary parameters,
% - optsFile is a .ini file that contains all necessary options
% - varargin takes in optional files for sourceMask and targetMask, in case
% registration is sparse
%
% TODO: use cubic interpolation? see if there is a difference?

    % parse inputs
    [source, target, paths, params, opts] = ...
        niftireg.parseInputs(pathsFile, paramsFile, optsFile, varargin{:});
    
    % Patch Registration    
    displ = patchreg.multiscale(source, target, params, opts);

    % save nifti
    cfn = @(v) cropVolume(v, params.volPad + 1, size(v) - params.volPad);
    displ = cellfunc(@(w) cfn(w), displ);
    displName = sprintf('%s-2-%s-warp', paths.sourceName, paths.targetName);
    displFile = sprintf('%s.nii.gz', displName);
    displNii = make_nii(cat(5, displ{:}));
    saveNii(displNii, [paths.savepathfinal displFile]);
    
    % save final displacement and volumes to niftis
    % TODO: this step assumes segmentations are passed. We should edit this to be a very separate
    % function.
    niftireg.displ2niftis(displ, source, target, paths, params, opts);
    
    % Immediate Output Visualization
    % TODO: this is unfinished!
    niftireg.visualize();
end
