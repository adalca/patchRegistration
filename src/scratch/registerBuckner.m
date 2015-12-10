function registerBuckner(BUCKNER_PATH, BUCKNER_ATLAS_PATH, OUTPUT_PATH, subjid)
% run buckner subject-to-atlas multiscale warp.

    %% Set up run
    o3 = ones(1, 3);
    
    % parameters
    params.patchSize = o3 * 3; % patch size for comparing patches.
    params.searchSize = o3 * 3; % search region size. Note: >> local = (searchSize-1)/2.
    params.gridSpacing = bsxfun(@times, o3, [1, 3, 5, 5]'); % define grid spacing by scale
    params.nScales = size(params.gridSpacing, 1); % take from gridSpacing
    params.nInnerReps = 2;
    params.mrf.lambda_node = 5;
    params.mrf.lambda_edge = 0.005; 
    params.mrf.inferMethod = @UGM_Infer_LBP; % @UGM_Infer_LBP or @UGM_Infer_MF
    
    % options
    opts.warpDir = 'forward'; % 'backward' or 'forward'
    opts.warpReg = 'mrf'; % 'none' or 'mrf' or 'quilt'
    opts.warpRes = 'full'; % 'full' or 'atscale'
    opts.verbose = 1; % 1 for simple, 2 for complex/debug
    opts.distanceMethod = 'stateDist'; % 'stateDist' or 'volknnsearch'
    opts.location = 0.1;
    opts.maxVolSize = 70; % max data size along largest dimension
    
    params.volPad = o3 * 0; % this is mainly needed due nan-filling-in at edges. :(.

    % files
    paths.sourceFile = fullfile(BUCKNER_PATH, subjid, [subjid, '_brain_iso_2_ds5_us5_size_reg.nii.gz']);
    paths.targetFile = fullfile(BUCKNER_ATLAS_PATH, 'buckner61_brain_proc.nii.gz');
    
    % segmentation files <optional>
    paths.sourceSegFile = fullfile(BUCKNER_PATH, subjid, [subjid, '_brain_iso_2_ds5_us5_size_reg_seg.nii.gz']);
    paths.targetSegFile = fullfile(BUCKNER_ATLAS_PATH, 'buckner61_seg_proc.nii.gz');
    
    % output path
    paths.output = OUTPUT_PATH;
    
    %% Carry out the registration
    register(paths, params, opts);
    
