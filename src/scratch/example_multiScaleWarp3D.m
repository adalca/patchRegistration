function example_multiScaleWarp3D(PREBUCKNER_PATH, OUTPUT_PATH)
% example run of subject-to-subject multiscale warp.
% requires: OUTPUT_PATH, PREBUCKNER_PATH

    %% Set up run
    
    % parameters
    params.patchSize = [1, 1, 1] * 3; % patch size for comparing patches.
    params.gridSpacing = [1, 1, 1] * 3; % grid spacing
    params.searchSize = [1, 1, 1] * 3; % search region size. Note: >> local = (searchSize-1)/2.
    params.nScales = 4;
    params.nInnerReps = 2;
    params.volPad = [5, 5, 5];     
    
    opts.inferMethod = @UGM_Infer_LBP; % @UGM_Infer_LBP or @UGM_Infer_MF
    opts.warpDir = 'forward'; % 'backward' or 'forward'
    opts.warpReg = 'mrf'; % 'none' or 'mrf' or 'quilt'
    opts.verbose = 2; % 1 for simple, 2 for complex/debug
    opts.distanceMethod = 'stateDist'; % 'stateDist' or 'volknnsearch'
    opts.location = 0.01;
    
    % max data size along largest dimension
    opts.maxVolSize = 70;

    % files. TODO: should switch to registering to atlas
    paths.sourceFile = fullfile(PREBUCKNER_PATH, 'buckner02_brain_affinereg_to_b61.nii.gz');
    paths.targetFile = fullfile(PREBUCKNER_PATH, 'buckner03_brain_affinereg_to_b61.nii.gz');
    
    % segmentation files. Only really necessary for some quick visualization at the end.
    paths.sourceSegFile = fullfile(PREBUCKNER_PATH, 'buckner02_brain_affinereg_to_b61_seg.nii.gz');
    paths.targetSegFile = fullfile(PREBUCKNER_PATH, 'buckner03_brain_affinereg_to_b61_seg.nii.gz');
    
    paths.output = OUTPUT_PATH;
    
    %% Carry out the registration
    register(paths, params, opts)    
