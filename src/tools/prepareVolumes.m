function [source, target, varargout] = prepareVolumes(paths, params, opts)
% preprocess the Nii files into volumes to be used

    %% Prepare volumes
    % prepare source
    source = prepNiiToVol(paths.sourceFile, params.volPad, opts.maxVolSize);
    
    % prepare target
    target = prepNiiToVol(paths.targetFile, params.volPad, opts.maxVolSize);
    
    % prepare masks is available
    if strcmp(opts.distance, 'sparse')
        % prepare source mask
        sourceMask = prepNiiToVol(paths.sourceMaskFile, params.volPad, opts.maxVolSize);

        % prepare target mask
        targetMask = prepNiiToVol(paths.targetMaskFile, params.volPad, opts.maxVolSize);
        
        varargout{1} = sourceMask;
        varargout{2} = targetMask;
    end
end