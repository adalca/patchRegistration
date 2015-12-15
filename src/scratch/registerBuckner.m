function registerBuckner(BUCKNER_PATH, BUCKNER_ATLAS_PATH, OUTPUT_PATH, subjid)
% run buckner subject-to-atlas multiscale warp.

    %% Set up run
    o3 = ones(1, 3);
    
    % parameters
    params.patchSize = o3 * 3; % patch size for comparing patches.
    params.searchSize = o3 * 3; % search region size. Note: >> local = (searchSize-1)/2.
    params.gridSpacing = bsxfun(@times, o3, [1, 2, 2, 3]'); % define grid spacing by scale
    params.nScales = size(params.gridSpacing, 1); % take from gridSpacing
    params.nInnerReps = 2;
    
    params.mrf.lambda_node = 0.1; %5;
    params.mrf.lambda_edge = 0.1; 
    params.mrf.inferMethod = @UGM_Infer_LBP; % @UGM_Infer_LBP or @UGM_Infer_MF
    
    % options
    opts.warpDir = 'backward'; % 'backward' or 'forward'
    opts.warpReg = 'mrf'; % 'none' or 'mrf' or 'quilt'
    opts.warpRes = 'full'; % 'full' or 'atscale'
    opts.verbose = 1; % 1 for simple, 2 for complex/debug
    opts.distanceMethod = 'stateDist'; % 'stateDist' or 'volknnsearch'
    opts.location = 0.001;
    opts.maxVolSize = 160; % max data size along largest dimension
    opts.localSpatialPot = false; % TODO: move to mrf params
    
    params.volPad = o3 * 0; % this is mainly needed due nan-filling-in at edges. :(.

    % input volumes filenames for buckner
    paths.sourceFile = fullfile(BUCKNER_PATH, subjid, [subjid, '_brain_iso_2_ds5_us5_size_reg.nii.gz']);
    paths.targetFile = fullfile(BUCKNER_ATLAS_PATH, 'buckner61_brain_proc.nii.gz');
    
    % prepare save path
    dirName = sprintf('%s_%f', subjid, now);
    mkdir(OUTPUT_PATH, dirName);
    opts.savefile = sprintf('%s%s/%s', OUTPUT_PATH, dirName, '%d_%d.mat');
    
    %% carry out the registration
    [sourceWarped, displ] = register(paths, params, opts);
    
    %% save segmentations if necessary
    load(sprintf(opts.savefile, 0, 0), 'volumes');
    
    % segmentation files <optional>
    paths.sourceSegFile = fullfile(BUCKNER_PATH, subjid, [subjid, '_brain_iso_2_ds5_us5_size_reg_seg.nii.gz']);
    paths.targetSegFile = fullfile(BUCKNER_ATLAS_PATH, 'buckner61_seg_proc.nii.gz');
    
    if isfield(paths, 'sourceSegFile') && isfield(paths, 'targetSegFile')
        volumes.sourceSeg = padarray(volresize(nii2vol(paths.sourceSegFile), size(volumes.source), 'nearest'), params.volPad, 'both');
        volumes.targetSeg = padarray(volresize(nii2vol(paths.targetSegFile), size(volumes.target), 'nearest'), params.volPad, 'both');
    end
    
    % save
    save(sprintf(opts.savefile, 0, 0), 'volumes', '-append');
    