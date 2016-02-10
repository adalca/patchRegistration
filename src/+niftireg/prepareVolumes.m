function [source, target, varargout] = prepareVolumes(paths, volPad, opts)
% preprocess the nifti files into volumes to be used in the registration algorithm
% 
% [source, target] = prepareVolumes(paths, volPad, opts)
% [source, target, sourceMask, targetMask] = prepareVolumes(paths, volPad, opts)
%
% if opts.scaleMethod is 'load', then we pre-load all images in cells source and target
%   otherwise source and target are each a volume
% either option can optionally load sparse data 
%
% opts: scaleMethod, distance

    doload = strcmp(opts.scaleMethod, 'load');
    dosparse = strcmp(opts.distance, 'sparse');

    if ~doload
        % prepare source
        source = niftireg.prepNiiToVol(paths.sourceFile, volPad, opts.maxVolSize);

        % prepare target
        target = niftireg.prepNiiToVol(paths.targetFile, volPad, opts.maxVolSize);

        % prepare masks is available
        if dosparse
            % prepare source mask
            if isfield(paths, 'sourceMaskFile') && ~isempty(paths.sourceMaskFile)
                sourceMask = niftireg.prepNiiToVol(paths.sourceMaskFile, volPad, opts.maxVolSize);
            else
                warning('No source mask found. Using all-ones');
                sourceMask = ones(size(source));
            end

            % prepare target mask
            if isfield(paths, 'targetMaskFile') && ~isempty(paths.targetMaskFile)
                targetMask = niftireg.prepNiiToVol(paths.targetMaskFile, volPad, opts.maxVolSize);
            else
                warning('No target mask found. Using all-ones');
                targetMask = ones(size(target));
            end
        end
        
    else % doload
        % prepare source and target cells
        sourceScales = eval(paths.sourceScales);
        targetScales = eval(paths.targetScales);
        source = cellfunc(@(x) niftireg.prepNiiToVol(x, volPad), sourceScales);
        target = cellfunc(@(x) niftireg.prepNiiToVol(x, volPad), targetScales);
        
        % prepare sparse structures
        if dosparse
            if isfield(paths, 'sourceMaskScales') && ~isempty(paths.sourceMaskScales)
                sourceMaskScales = eval(paths.sourceMaskScales);
                sourceMask = cellfunc(@(x) niftireg.prepNiiToVol(x, volPad), sourceMaskScales);
            else
                warning('No source mask found. Using all-ones');
                sourceMask = cellfunc(@(x) ones(size(x)), source);
            end
            
            if isfield(paths, 'targetMaskScales') && ~isempty(paths.targetMaskScales)
                targetMaskScales = eval(paths.targetMaskScales);
                targetMask = cellfunc(@(x) niftireg.prepNiiToVol(x, volPad), targetMaskScales);
            else
                warning('No target mask found. Using all-ones');
                targetMask = cellfunc(@(x) ones(size(x)), target);
            end
        end
    end
    
    varargout{1} = sourceMask;
    varargout{2} = targetMask;
end
