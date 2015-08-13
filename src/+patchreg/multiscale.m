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
    minSize = 16; %usually good to use 16.
    minScale = min(minSize, min([size(source), size(target)])/2);
    srcSizes = arrayfunc(@(x) 2 .^ linspace(log2(minScale), log2(x), nScales), size(source));
    trgSizes = arrayfunc(@(x) 2 .^ linspace(log2(minScale), log2(x), nScales), size(target));

    % initiate a zero displacement
    displ = repmat({zeros(size(source))}, [1, ndims(source)]);    
    
    % go through the multiple scales
    h = figuresc();
    himgs = {}; titles = {};
    for s = 1:nScales
        fprintf('multiscale: running scale %d with size\n', s);
        
        % resizing the original source and target images to s
        srcSize = cellfun(@(x) round(x(s)), srcSizes);
        scTarget = volresize(target, srcSize);
        trgSize = cellfun(@(x) round(x(s)), trgSizes);
        scSource = volresize(source, trgSize);
        disp(srcSize)
        
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
                titles = {titles{:}, 'warped source', 'target', 'prevdispl_y', 'prevdispl_x', ...
                    'localdispl_y', 'localdispl_x', 'displ_y', 'displ_x'};
                localhimgs = {scSourceWarped, scTarget, dbdispl{:}, localDispl{:}, displ{:}};
                himgs = {himgs{:}, localhimgs{:}};
                
                subgrid = [nScales, nInnerReps * numel(localhimgs)];
                view2D(himgs, 'figureHandle', h, 'subgrid', subgrid, 'titles', titles);
                
            elseif ndims(source) == 3
                % TODO: measure amount of change in new localDispl
                %dbdispl = resizeWarp(displ, size(source));
                %view3Dopt(source, volwarp(source, dbdispl), target, dbdispl{:});
                % TODO: do a 2d of mid-frame?
            end
        end
        
        if s > 3 %|| s > 1
            disp(s);
        end
    end
    
    % compose the final image using the resulting displacements
    sourceWarped = volwarp(source, displ);
    
    if nargout >= 3
        [~, ~, srcgridsize] = patchlib.grid(size(source), patchSize, patchOverlap);
        varargout{1} = patchlib.quilt(qp, srcgridsize, patchSize, patchOverlap); 
    end
end
