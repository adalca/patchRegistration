function displ = multiscale(source, target, params, opts, varargin)
% MULTISCALE run a full patch-based registration.
%
% displ = multiscale(source, target, params, opts)
%   params: struct with: patchSize, searchSize, gridSpacing, nScales, nInnerReps
%   opts: struct with: inferMethod, warpDir, warpReg, verbose, distMethod, <savefile>
%
% displ = multiscale(source, target, params, opts, varargin) see singlescale(...)
%
% inferMethod offers the possibility to choose inference methods: LoopyBP, MeanField, Fast PD
%
% TODO: better documentation :)

    % pre-compute the source and target sizes at each scale.
    % e.g. 2.^linspace(log2(32), log2(256), 4)
    minSize = 16; % usually good to use 16.
    minScale = min(minSize, min([size(source), size(target)])/2);
    srcSizes = arrayfunc(@(x) round(2 .^ linspace(log2(minScale), log2(x), params.nScales)), size(source));
    trgSizes = arrayfunc(@(x) round(2 .^ linspace(log2(minScale), log2(x), params.nScales)), size(target));

    % initiate a zero displacement
    firstSize = cellfun(@(x) round(x(1)), srcSizes);
    displ = repmat({zeros(firstSize)}, [1, ndims(source)]); 
    
    % go through the multiple scales
    for s = 1:params.nScales        
        
        % resizing the original source and target images to s
        scSrcSize = cellfun(@(x) x(s), srcSizes);
        scSource = volresize(source, scSrcSize);
        scTargetSize = cellfun(@(x) x(s), trgSizes);
        scTarget = volresize(target, scTargetSize);
        
        % resize the warp distances to the current scale size
        displ = resizeWarp(displ, scSrcSize);
        
        % warp several times
        for t = 1:params.nInnerReps 
            
            % if verbose, print a bit of information
            if opts.verbose
               fprintf('multiscale: running scale %d iteration %d with size %s\n', s, t, ...
                   sprintf('%d ', scSrcSize));
            end
            
            % warp the source to match the use the current displacement
            scSourceWarped = volwarp(scSource, displ, opts.warpDir);

            % find the new warp (displacements)
            sstic = tic();
            localDispl = patchreg.singlescale(scSourceWarped, scTarget, params, opts, ...
                'currentdispl', displ, varargin{:});
            sstime = toc(sstic);

            % compose previous warp with newfound warp
            cdispl = composeWarps(displ, localDispl);
            
            % if save mode is on, save relevant teration information
            if isfield(opts, 'savefile') && ~isempty(opts.savefile)
                state = struct('scale', s, 'iter', t, 'scSrcSize', scSrcSize, ...
                    'scTargetSize', scTargetSize, 'runTime', sstime); %#ok<NASGU>
                displVolumes = struct('displ', {displ}, 'localDispl', {localDispl}, ...
                    'cdispl', {cdispl}); %#ok<NASGU>
                volumes = struct('scSource', scSource, 'scTarget', scTarget, ...
                    'scSourceWarped', scSourceWarped); %#ok<NASGU>
                filename = sprintf(opts.savefile, s, t);
                save(filename, 'params', 'opts', 'state', 'displVolumes', 'volumes');
            end 
            
            % final warp for this iteration is the composed warp
            displ = cdispl;
        end
    end
end
