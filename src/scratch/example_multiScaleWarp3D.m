function [sourceWarped, displ] = example_multiScaleWarp3D(OUTPUT_PATH, BUCKNER_PATH)
% example run of subject-to-subject multiscale warp.
% requires: OUTPUT_PATH, BUCKNER_PATH

    %% Set up run
    
    % parameters
    params.patchSize = [1, 1, 1] * 3; % patch size for comparing patches.
    params.gridSpacing = [1, 1, 1] * 1; % grid spacing
    params.searchSize = [1, 1, 1] * 3; % search region size. Note: >> local = (searchSize-1)/2.
    params.nScales = 5;
    params.nInnerReps = 2;
    opts.inferMethod = @UGM_Infer_LBP; % @UGM_Infer_LBP or @UGM_Infer_MF
    opts.warpDir = 'backward'; % 'backward' or 'forward'
    opts.warpReg = 'mrf'; % 'none' or 'mrf' or 'quilt'
    opts.verbose = true;
    
    % max data size along largest dimension
    MAX_VOL_SIZE = 94;

    % files. TODO: should switch to registering to atlas
    sourceFile = fullfile(BUCKNER_PATH, 'buckner02_brain_affinereg_to_b61.nii.gz');
    targetFile = fullfile(BUCKNER_PATH, 'buckner03_brain_affinereg_to_b61.nii.gz');
    
    % segmentation files. Only really necessary for some quick visualization at the end.
    sourceSegFile = fullfile(BUCKNER_PATH, 'buckner02_brain_affinereg_to_b61_seg.nii.gz');
    targetSegFile = fullfile(BUCKNER_PATH, 'buckner03_brain_affinereg_to_b61_seg.nii.gz');
    
    %% Prepare run
    % prepare source
    niiSource = loadNii(sourceFile);
    szRatio = max(size(niiSource.img)) ./ MAX_VOL_SIZE;
    newSrcSize = round(size(niiSource.img) ./ szRatio);
    source = padarray(volresize(double(niiSource.img)/255, newSrcSize), params.patchSize, 'both');
    
    % prepare target
    niiTarget = loadNii(targetFile);
    szRatio = max(size(niiTarget.img)) ./ MAX_VOL_SIZE;
    newTarSize = round(size(niiTarget.img) ./ szRatio);
    target = padarray(volresize(double(niiTarget.img)/255, newTarSize), params.patchSize, 'both');
    
    % prepare save path
    dirName = sprintf('%f_gridSpacing%d_%d_%d', now, params.gridSpacing);
    mkdir(OUTPUT_PATH, dirName);
    opts.savefile = sprintf('%s%s/%s', OUTPUT_PATH, dirName, '%d_%d.mat');
    
    %% Patch Registration
    % do multi scale registration
    displ = patchreg.multiscale(source, target, params, opts);
    
    %% Immediate Output Processing
    % This is just some quick visualization. Analysis should be done separately
    
    % compose the final image using the resulting displacements
    sourceWarped = volwarp(source, displ, opts.warpDir);
    
    % TODO: try to do quilt instead of warp. Soemthing like:
    % [~, ~, srcgridsize] = patchlib.grid(size(source), patchSize, patchOverlap);
    % alternativeWarped = patchlib.quilt(qp, srcgridsize, patchSize, patchOverlap); 
    
    % display results
    if ndims(source) == 2 %#ok<ISMAT>
        patchview.figure();
        drawWarpedImages(source, target, sourceWarped, displ); 
    
    elseif ndims(source) == 3
        % prepare segmentations
        sourceSegm = padarray(volresize(nii2vol(sourceSegFile), newSrcSize, 'nearest'), params.patchSize, 'both');
        targetSegm = padarray(volresize(nii2vol(targetSegFile), newTarSize, 'nearest'), params.patchSize, 'both');

        sourceSegmWarped = volwarp(sourceSegm, displ, opts.warpDir, 'interpmethod', 'nearest');
        
        % visualize
        view3Dopt(source, target, sourceWarped, ...
            sourceSegm, targetSegm, sourceSegmWarped, ...
            displ{:});
    end
    