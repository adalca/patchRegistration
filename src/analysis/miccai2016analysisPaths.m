%% Analyse and prepare data for the MICCAI 2016 submission of patch-based registration
% assumes data organization:
% /outpath/datatype/runname/subjid_param1_param2_.../
%   /final/datatype61-seg-in-%s-raw_via_%s-2-datatype61-invWarp.nii.gz
%   /final/datatype61-seg-in-%s_via_%s-2-datatype61-invWarp.nii.gz
%   /out/stats.amt
% /inpath/datatype/proc/brain_pad10/subjid/
%
% where datatype is buckner or stroke, runname is something like PBR_v5

%% setup paths
INPUT = '/data/vision/polina/scratch/patchRegistration/inputs/';
bucknerinpath = [INPUT, 'buckner/proc/brain_pad10/'];
strokeinpath = [INPUT, 'stroke/proc/brain_pad10/'];

OUTPATH = '/data/vision/polina/scratch/patchRegistration/output/';
bppath = [OUTPATH, 'buckner/sparse_ds7_pad10_lambdaedge_gridspacing_innerreps/'];
bapath = [OUTPATH, 'buckner/ANTs_v3_raw_fromDs7us7Reg_continueAffine_multiparam/'];
sppath = [OUTPATH, 'stroke/PBR_v5'];
sapath = [OUTPATH, 'stroke/ANTs_v3_raw_fromDs7us7Reg_continueAffine_multiparam']; %ANTs_v3_raw_fromDs7us7Reg_continueAffine_multiparam

saveImagesPath = '/data/vision/polina/scratch/patchRegistration/output/miccai2016figures/mar15';

buckneroutpaths = {bppath, bapath};
strokeoutpaths = {sppath, sapath};
bucknerpathnames = {'buckner-PBR', 'buckner-ANTs'};
strokepathnames = {'stroke-PBR', 'stroke-ANTs'};

segInRawFiletpl = '%s61-seg-in-%s-raw_via_%s-2-%s61-invWarp.nii.gz';
rawSubjFiletpl = '%s_proc_ds7.nii.gz';

segInSubjFiletpl = '%s61-seg-in-%s_via_%s-2-%s61-invWarp.nii.gz';
subjFiletpl = '%s_ds7_us7_reg.nii.gz';
