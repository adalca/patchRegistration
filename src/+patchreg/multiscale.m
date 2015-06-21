function [sourceWarped, displ, varargout] = ...
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
    h = figuresc();
    for s = 1:nScales
        fprintf('multiscale: running scale %d\n', s);
        
        % resizing the original source and target images to s
        srcSize = cellfun(@(x) round(x(s)), srcSizes);
        scTarget = volresize(target, srcSize);
        trgSize = cellfun(@(x) round(x(s)), trgSizes);
        scSource = volresize(source, trgSize);
        
        % resize the warp distances and then apply them to the resized source
        displ = resizeWarp(displ, srcSize);
        
        % warp several times
        for t = 1:nInnerReps           
            % warp the source to match the current displacement
            scSourceWarped = volwarp(scSource, displ);

            % find the new warp (displacements)
            [~, localDispl, qp] = patchreg.singlescale(scSourceWarped, scTarget, patchSize, ...
                patchOverlap, 'currentdispl', displ, varargin{:});
            dbdispl = displ; % for debug
            displ = composeWarps(displ, localDispl);
            assert(isclean([displ{:}]));
            
            % do some debug displaying for 2D data
            if ndims(source) == 2 %#ok<ISMAT>
                figure(h);
                r = cat(3, displ{1}, displ{1}*0, displ{2});
                l = cat(3, localDispl{1}, localDispl{1}*0, localDispl{2});
                d = cat(3, dbdispl{1}, dbdispl{1}*0, dbdispl{2});
                subplot(nScales, nInnerReps, (s-1) * nInnerReps + t); 
                im = [repmat(scSourceWarped, [1, 1, 3]), repmat(scTarget, [1, 1, 3]), d, l, r];
                im = imresize(im, size(source) .* [1, 5]);
                imagesc(im);
                drawnow();
            elseif ndims(source) == 3
                dbdispl = resizeWarp(displ, size(source));
                view3Dopt(source, volwarp(source, dbdispl), target, dbdispl{:});
            end
        end
    end
    
    % compose the final image using the resulting displacements
    sourceWarped = volwarp(source, displ);
    
    if nargout == 3
        [~, ~, srcgridsize] = patchlib.grid(size(source), patchSize, patchOverlap);
        varargout{1} = patchlib.quilt(qp, srcgridsize, patchSize, patchOverlap); 
    end
end
