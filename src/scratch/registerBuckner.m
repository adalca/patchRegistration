function fname = registerBuckner(BUCKNER_PATH, BUCKNER_ATLAS_PATH, OUTPUT_PATH, subjid, varargin)
% run buckner subject-to-atlas multiscale warp.

    %% Set up run
    o3 = ones(1, 3);
    
    % parameters
    params.patchSize = o3 * 3; % patch size for comparing patches.
    params.patchSize = bsxfun(@times, o3, [9, 9, 9, 9]'); 
    params.searchSize = o3 * 3; % search region size. Note: >> local = (searchSize-1)/2.
    params.gridSpacing = bsxfun(@times, o3, [1, 2, 2, 3]'); % define grid spacing by scale
    params.nScales = size(params.gridSpacing, 1); % take from gridSpacing
    params.nInnerReps = 2;
    params.mrf.lambda_node = 1; %5;
    params.mrf.lambda_edge = 0.01; 
    params.mrffn = @patchlib.patchmrf; % patchlib.patchmrf or patchmrf_PR
    params.mrf.inferMethod = @UGM_Infer_LBP; % @UGM_Infer_LBP or @UGM_Infer_MF or % @UGM_Infer_LBP_PR
    
    % options
    opts.warpDir = 'backward'; % 'backward' or 'forward'
    opts.warpReg = 'mrf'; % 'none' or 'mrf' or 'quilt'
    opts.warpRes = 'full'; % 'full' or 'atscale'
    opts.verbose = 1; % 1 for simple, 2 for complex/debug
    opts.distanceMethod = 'stateDist'; % 'stateDist' or 'volknnsearch'
    opts.location = 0.001;
    opts.maxVolSize = 160; % max data size along largest dimension
    opts.localSpatialPot = false; % TODO: move to mrf params
    opts.distance = 'sparse'; % 'euclidean' or 'seuclidean'
    
    params.volPad = o3 * 5; % this is mainly needed due nan-filling-in at edges. :(.

    % input volumes filenames for buckner
    paths.sourceFile = fullfile(BUCKNER_PATH, subjid, [subjid, '_brain_iso_2_ds5_us5_size_reg.nii.gz']);
    paths.sourceFile = fullfile(BUCKNER_PATH, subjid, [subjid, '_brain_downsampled5_reinterpolated5_reg.nii.gz']);
    paths.targetFile = fullfile(BUCKNER_ATLAS_PATH, 'buckner61_brain_proc.nii.gz');
    if strcmp(opts.distance, 'sparse')
        paths.sourceMaskFile = fullfile(BUCKNER_PATH, subjid, [subjid, '_brain_downsampled5_reinterpolated5_dsmask_reg.nii.gz']);
        paths.targetMaskFile = fullfile(BUCKNER_ATLAS_PATH, 'buckner61_brain_proc_allones.nii.gz');
    end
    
    % evaluate whatever modifiers are put in place
    % e.g. 'params.mrf.lambda_edge = 0.1';
    for i = 1:numel(varargin)
        eval(varargin{i});
    end
    
    %% prepare save path
	if sys.isdir(OUTPUT_PATH)
		paramstr = sprintf('LE%3.2f_LN%3.2f_gs%s_ireps%d', params.mrf.lambda_edge, ...
			params.mrf.lambda_node, sprintf('%d_', params.gridSpacing(:, 1)),  params.nInnerReps);
		dirName = sprintf('%s_%f_%s', subjid, now, paramstr);
		mkdir(OUTPUT_PATH, dirName);
		opts.savefile = sprintf('%s%s/%%d_%%d.mat', OUTPUT_PATH, dirName);
	
	else
	
		opts.savefile = OUTPUT_PATH;
	end
		
		
    
    %% carry out the registration
    tic;
    [sourceWarped, displ] = register(paths, params, opts);
    mastertoc = toc;
    
    %% save segmentations if necessary
    load(sprintf(opts.savefile, 0, 0), 'volumes');
    
    % segmentation files <optional>
    paths.sourceSegFile = fullfile(BUCKNER_PATH, subjid, [subjid, '_brain_iso_2_ds5_us5_size_reg_seg.nii.gz']);
    paths.targetSegFile = fullfile(BUCKNER_ATLAS_PATH, 'buckner61_seg_proc.nii.gz');
    
    if isfield(paths, 'sourceSegFile') && isfield(paths, 'targetSegFile')
        srcSize = size(volumes.source) - params.volPad * 2;
        volumes.sourceSeg = padarray(volresize(nii2vol(paths.sourceSegFile), srcSize, 'nearest'), params.volPad, 'both');
        tarSize = size(volumes.target) - params.volPad * 2;
        volumes.targetSeg = padarray(volresize(nii2vol(paths.targetSegFile), tarSize, 'nearest'), params.volPad, 'both');
    end
    
    % save
    save(sprintf(opts.savefile, 0, 0), 'volumes', 'mastertoc', '-append');
    
    %% return
    fname = opts.savefile;
