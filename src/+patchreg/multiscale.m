function [sourceWarped, displ, varargout] = ...
    multiscale(source, target, sourceSegm, targetSegm, patchSize, patchOverlap, nScales, nInnerReps, infer_method, warpDir, varargin)
%
%
% Rough algorithm:
% Run patchlib.volknnsearch and lib2patches to get mrf unary potentials automatically. 
% Then call patchmrf and use patchlib.correspdst for the pair potentials. 
% Then repeat
%
% infer_method offers the possibility to choose inference methods: LoopyBP,
% MeanField, Fast PD
%

    % pre-compute the source and target sizes at each scale.
    % e.g. 2.^linspace(log2(32), log2(256), 4)
    minSize = 16; %usually good to use 16.
    minScale = min(minSize, min([size(source), size(target)])/2);
    srcSizes = arrayfunc(@(x) 2 .^ linspace(log2(minScale), log2(x), nScales), size(source));
    trgSizes = arrayfunc(@(x) 2 .^ linspace(log2(minScale), log2(x), nScales), size(target));

    % initiate a zero displacement
    firstSize = cellfun(@(x) round(x(1)), srcSizes);
    %firstGrid = patchlib.grid(firstSize, patchSize, patchOverlap);
    displ = repmat({zeros(firstSize)}, [1, ndims(source)]); 
    
    % compute ID for run:
    % TODO: the paths should be moved outside of multiscale.
    if ispc
        savePath = 'D:/Dropbox (MIT)/Research/patchRegistration/output/';
    else
        savePath = '/data/vision/polina/scratch/abobu/patchRegistration/output/';
    end
    dirName = sprintf('%f_gridSpacing%d_%d_%d', now, patchSize - patchOverlap);
    mkdir(savePath, dirName);
    savePath = sprintf('%s%s/', savePath, dirName);
    
    % go through the multiple scales
    h = figuresc();
    himgs = {}; titles = {};
    for s = 1:nScales
        fprintf('multiscale: running scale %d with size\n', s);
        
        % resizing the original source and target images to s
        srcSize = cellfun(@(x) round(x(s)), srcSizes);
        scTarget = volresize(target, srcSize);
        scTargetSegm = volresize(targetSegm, srcSize, 'nearest');
        trgSize = cellfun(@(x) round(x(s)), trgSizes);
        scSource = volresize(source, trgSize);
        scSourceSegm = volresize(sourceSegm, trgSize, 'nearest');
        disp(srcSize)
        
        % resize the warp distances and then apply them to the resized source
        displ = resizeWarp(displ, srcSize);
        
        % warp several times
        for t = 1:nInnerReps           
            % warp the source to match the current displacement
            scSourceWarped = volwarp(scSource, displ, warpDir);

            % find the new warp (displacements)
            a = tic();
            [~, localDispl, qp] = patchreg.singlescale(scSourceWarped, scTarget, patchSize, ...
                patchOverlap, infer_method, warpDir, 'currentdispl', displ, varargin{:});
            fprintf('multiscale: running scale %d with size\n'        , s);
            tics = toc(a);

            dbdispl = displ; % for debug
            displ = composeWarps(displ, localDispl);
            assert(isclean([displ{:}]));
            scaledLocalDispl = resizeWarp(localDispl, size(source)); 
            
            normLocalDispl = cellfun(@(x) norm(x(:))/numel(x), localDispl);
            normScaledLocalDispl = cellfun(@(x) norm(x(:))/numel(x), scaledLocalDispl);
            normCurrentDispl = cellfun(@(x) norm(x(:))/numel(x), displ);
            
            local = 1;
            searchPatch = ones(1, ndims(scSourceWarped)) .* local .* 2 + 1;
            sourceWarpedSegm = volwarp(scSourceSegm, displ, warpDir, 'interpmethod', 'nearest');
            diceCoeff = dice(sourceWarpedSegm, scTargetSegm);
            
            normDispl = struct('local', normLocalDispl, 'scaledLocal', normScaledLocalDispl, 'current', normCurrentDispl);  
            volumes = struct('source', scSource, 'target', scTarget, 'sourceSegm', scSourceSegm, 'targetSegm', scTargetSegm, 'localDispl', {localDispl}, 'scaledLocalDispl', {scaledLocalDispl}, 'currentDispl', {displ});
            parameters = struct('patchSize', patchSize, 'searchPatch', searchPatch, 'patchOverlap', patchOverlap, 'nScales', nScales, 'nInnerReps', nInnerReps, 'inferMethod', infer_method, 'lambdaNode', 1, 'lambdaEdge', 1, 'inferenceThreshold', 10^-4);
            
            %save things
            outputName = sprintf('%d_%d.mat', s, t);
            save([savePath outputName], 'volumes', 'tics', 'normDispl', 'diceCoeff', 'parameters');
            
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
        
        % displ = mrfgrid2dense(displ, srcSize, patchSize, patchOverlap);
        
    end
    
    % compose the final image using the resulting displacements
    sourceWarped = volwarp(source, displ, warpDir);
    
    if nargout >= 3
        [~, ~, srcgridsize] = patchlib.grid(size(source), patchSize, patchOverlap);
        varargout{1} = patchlib.quilt(qp, srcgridsize, patchSize, patchOverlap); 
    end
end
