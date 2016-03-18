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
bucknerinpath = [INPUT, 'ADNI_T1_baselines/proc/brain_pad10/'];
strokeinpath = [INPUT, 'stroke/proc/brain_pad10/'];

OUTPATH = '/data/vision/polina/scratch/patchRegistration/output/';
bppath = [OUTPATH, 'buckner/sparse_ds7_pad10_lambdaedge_gridspacing_innerreps/'];
bppath = [OUTPATH, 'ADNI_T1_baselines/PBR_v101_wholevol/'];
bapath = [OUTPATH, 'buckner/ANTs_v3_raw_fromDs7us7Reg_continueAffine_multiparam/'];
bapath = [OUTPATH, 'ADNI_T1_baselines/ANTs_v102_brainpad10_ds7us7reg_multiparam/'];
bapath = [OUTPATH, 'ADNI_T1_baselines/ANTs_v103_brainpad10_ds9us9reg_noaffine_multiparam/'];
sppath = [OUTPATH, 'stroke/PBR_v5'];
sppath = [OUTPATH, 'stroke/PBR_v101_brain_pad10'];
sapath = [OUTPATH, 'stroke/ANTs_v3_raw_fromDs7us7Reg_continueAffine_multiparam/']; 
sapath = [OUTPATH, 'stroke/ANTs_v102_brainpad10_ds7us7reg_multiparam/'];

saveImagesPath = '/data/vision/polina/scratch/patchRegistration/output/miccai2016figures/mar15';

buckneroutpaths = {bapath, bppath};
strokeoutpaths = {sapath, sppath};
bucknerpathnames = {'buckner-ANTs', 'buckner-PBR'};
strokepathnames = {'stroke-ANTs', 'stroke-PBR'};

segInRawFiletpl = '%s61-seg-in-%s-raw_via_%s-2-%s61-invWarp.nii.gz';
rawSubjFiletpl = '%s_proc_ds9.nii.gz';

segInSubjFiletpl = '%s61-seg-in-%s_via_%s-2-%s61-invWarp.nii.gz';
subjFiletpl = '%s_ds9_us9_reg.nii.gz';
