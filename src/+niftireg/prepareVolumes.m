function vols = prepareVolumes(paths, params)
% preprocess the nifti files into volumes to be used in the registration algorithm
% 
% vols = prepareVolumes(paths, params) load nifti volumes of moving and fixed image. 
%
%   if params.scale.method is 'resize', paths.in.moving and paths.in.fixed should provide nifti
%   paths to the moving and fixed image, respectively. In addition, if paths.in.movingMask and
%   paths.in.fixedMask are provided, they will be loaded in as the appropriate masks. If these masks
%   are provided in the paths but are empty, they are initialized as all ones.
%
%   if params.scale.method is 'load', paths.in.movingScales and paths.in.fixedScales should provide
%   a string with an array of nifti paths: e.g. '{''/path/to/firstscale.nii.gz'',
%   ''/path/to/secondscale.nii.gz''}' we then we pre-load all images in cells moving and fixed.
%   Masks can be provided through movingMaskScales and fixedMaskScales. 
%
%   Finally, if paths.in.initDispl is provided, it is loaded in.
%
% volumes is a struct that has 'moving' and 'fixed' fields, and optionally movingMask, fixedMask,
% and initDispl.
%
% params used: params.scale.method

    movingMask = [];
    fixedMask = [];
    if ~strcmp(params.scale.method, 'load')
        % prepare moving
        moving = nii2vol(paths.in.moving);

        % prepare fixed
        fixed = nii2vol(paths.in.fixed);

        % prepare moving mask
        if isfield(paths.in, 'movingMask') && ~isempty(paths.in.movingMask)
            movingMask = double(nii2vol(paths.in.movingMask));
        elseif isfield(paths.in, 'movingMask')
            if params.verbose; fprintf('No moving mask found. Using all-ones\n'); end
            movingMask = ones(size(moving));
        end

        % prepare fixed mask
        if isfield(paths.in, 'fixedMask') && ~isempty(paths.in.fixedMask)
            fixedMask = double(nii2vol(paths.in.fixedMask));
        elseif isfield(paths.in, 'fixedMask')
            if params.verbose; fprintf('No fixed mask found. Using all-ones\n'); end
            fixedMask = ones(size(fixed));
        end
        
    else % doload
        % prepare moving and fixed cells
        movingScales = eval(paths.in.movingScales);
        fixedScales = eval(paths.in.fixedScales);
        moving = cellfunc(@nii2vol, movingScales);
        fixed = cellfunc(@nii2vol, fixedScales);
        
        % prepare sparse structures
        if isfield(paths.in, 'movingMaskScales') && ~isempty(paths.in.movingMaskScales)
            movingMaskScales = eval(paths.in.movingMaskScales);
            movingMask = cellfunc(@(x) double(nii2vol(x)), movingMaskScales);
        elseif isfield(paths.in, 'movingMaskScales')
            if params.verbose; fprintf('No moving mask found. Using all-ones\n'); end
            movingMask = cellfunc(@(x) ones(size(x)), moving);
        end

        if isfield(paths.in, 'fixedMaskScales') && ~isempty(paths.in.fixedMaskScales)
            fixedMaskScales = eval(paths.in.fixedMaskScales);
            fixedMask = cellfunc(@(x) double(nii2vol(x)), fixedMaskScales);
        elseif isfield(paths.in, 'fixedMaskScales')
            if params.verbose; fprintf('No fixed mask found. Using all-ones\n'); end
            fixedMask = cellfunc(@(x) ones(size(x)), fixed);
        end
    end
    
    if isfield(paths.in, 'initDispl') 
        vols.initDispl = nii2vol(paths.in.initDispl);
    end
    
    vols.moving = moving;
    if ~isempty(movingMask), vols.movingMask = movingMask; end
    vols.fixed = fixed;
    if ~isempty(fixedMask), vols.fixedMask = fixedMask; end
end
