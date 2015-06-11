function [sourceWarped, displ] = ...
    multiscale(source, target, patchSize, patchOverlap, nScales, nInnerReps, varargin)
%
%
% Rough algorithm:
% Run patchlib.volknnsearch and lib2patches to get mrf unary potentials automatically. 
% Then call patchmrf and use patchlib.correspdst for the pair potentials. 
% Then repeat
%
        
    % pre-compute the source and target sizes at each scale.
    % e.g. 2.^linspace(log2(32), log2(256), 4)
    minScale = min(16, min([size(source), size(target)])/2);
    srcSizes = arrayfunc(@(x) 2 .^ linspace(log2(minScale), log2(x), nScales), size(source));
    trgSizes = arrayfunc(@(x) 2 .^ linspace(log2(minScale), log2(x), nScales), size(target));

    % initiate a zero displacement
    displ = repmat({zeros(size(source))}, [1, ndims(source)]);    
    
    % go through the multiple scales
    for s = 1:nScales
        fprintf('multiscale: running scale %d\n', s);
        
        % resizing the original source and target images to s
        srcSize = cellfun(@(x) x(s), srcSizes);
        scTarget = volresize(target, srcSize);
        trgSize = cellfun(@(x) x(s), trgSizes);
        scSource = volresize(source, trgSize);
        
        % resize the warp distances and then apply them to the resized source
        displ = resizeWarp(displ, srcSize);
        
        % warp several times
        for t = 1:nInnerReps           
            % warp the source to match the current displacement
            scSourceWarped = volwarp(scSource, displ);

            % find the new warp (displacements)
            [~, localDispl] = ...
                patchreg.singlescale(scSourceWarped, scTarget, patchSize, patchOverlap, varargin{:});
            displ = composeWarps(displ, localDispl);
            assert(isclean([displ{:}]));
            
            % do some debug displaying
            % figure(1);
            % subplot(nInnerReps, 1, t); imshow([sourceSWarped, targetS, localDisp{:}, disp{:}]);
        end
    end
    
    % compose the final image using the resulting displacements
    sourceWarped = volwarp(source, displ, 'interpmethod', 'nearest');    
end
