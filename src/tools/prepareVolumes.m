function [source, target, varargout] = prepareVolumes(paths, volPad, opts)
% preprocess the Nii files into volumes to be used

    % prepare source
    source = prepNiiToVol(paths.sourceFile, volPad, opts.maxVolSize);
    
    % prepare target
    target = prepNiiToVol(paths.targetFile, volPad, opts.maxVolSize);
    
    % prepare masks is available
    if strcmp(opts.distance, 'sparse')
        % prepare source mask
        sourceMask = prepNiiToVol(paths.sourceMaskFile, volPad, opts.maxVolSize);

        % prepare target mask
        targetMask = prepNiiToVol(paths.targetMaskFile, volPad, opts.maxVolSize);
        
        varargout{1} = sourceMask;
        varargout{2} = targetMask;
    end
end
