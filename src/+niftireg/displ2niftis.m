function displ2niftis(varargin)
% warp and save nifti volumes given registration field
%   displ2niftis(displ, source, target, paths, params)
%
%   displ2niftis(registerNiiArguments...)
   
    % for now, we are not careful about headers.
    warning('displ2niftis: Output niftis ignores appropriate header data.')

    % parse inputs
    if iscell(varargin{1}) % called via matlab
        [displ, moving, fixed, paths, params] = varargin{:};
        if isfield(paths.out, 'displ') && ~isempty(paths.out.displ)
            saveNii(make_nii(cat(5, displ{:})), paths.out.displ);
        end
    else % assuming same inputs as registerNii
        [moving, fixed, paths, params] = niftireg.parseInputs(varargin{:});
        displ = dimsplit(5, nii2vol(paths.out.displ));
        displ = displ(:)';
    end

    % prepare "original" volumes to warp 
    if strcmp(params.scale.method, 'load')
        moving = moving{end};
        fixed = fixed{end};
    end

    % get inverse displacement
    if any(cellfun(@(v) isfield(paths.out, v), {'invDispl', 'fixed', 'fixedSeg'}))
        fn = @(v,d) volwarpForwardApprox(v, d, 'nLayers', 2);
        displInv = invertwarp(displ, fn);   
        if isfield(paths.out, 'invDispl') && ~isempty(paths.out.invDispl)
            saveNii(make_nii(cat(5, displInv{:})), paths.out.invDispl)
        end
    end
    
    % compose the final images using the resulting displacements
    if isfield(paths.out, 'moving') && ~isempty(paths.out.moving)
        movingWarped = volwarp(moving, displ, params.warp.dir);
        saveNii(make_nii(movingWarped), paths.out.moving);
    end
    if isfield(paths.out, 'fixed') && ~isempty(paths.out.fixed)
        fixedWarped = volwarp(fixed, displInv, params.warp.dir);
        saveNii(make_nii(fixedWarped), paths.out.fixed);
    end

    % warp segmentations
    if isfield(paths.in, 'movingSeg') && isfield(paths.out, 'movingSeg') , 
        movingSeg = nii2vol(paths.in.movingSeg); 
        movingWarpedSeg = volwarp(movingSeg, displ, params.warp.dir, 'interpMethod', 'nearest'); 
        saveNii(make_nii(movingWarpedSeg), paths.out.movingSeg); 
    end
    if isfield(paths.in, 'fixedSeg') && isfield(paths.out, 'fixedSeg'), 
        fixedSeg = nii2vol(paths.in.fixedSeg); 
        fixedWarpedSeg = volwarp(fixedSeg, displInv, params.warp.dir, 'interpMethod', 'nearest');
        saveNii(make_nii(fixedWarpedSeg), paths.out.fixedSeg); 
    end
end
