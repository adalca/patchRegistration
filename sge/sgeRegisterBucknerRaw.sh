#!/bin/bash 
# run statistics on buckner registration raw

###############################################################################
# Settings
###############################################################################

# prepare SGE variables necessary to move SGE environment away from AFS.
export SGE_LOG_PATH=/data/vision/polina/scratch/adalca/patchSynthesis/sge/
export SGE_O_PATH=${SGE_LOG_PATH}
export SGE_O_HOME=${SGE_LOG_PATH}

# MCR file. This has to match the MCC version used in mcc.sh
mcr=/data/vision/polina/shared_software/MCR/v82/

# project paths
BUCKNER_PATH="/data/vision/polina/scratch/adalca/patchSynthesis/data/buckner/proc/";
BUCKNER_ATLAS_PATH="/data/vision/polina/scratch/adalca/patchSynthesis/data/buckner/atlases/";
OUTPUT_PATH="/data/vision/polina/scratch/patchRegistration/output/";
PROJECT_PATH="/data/vision/polina/users/adalca/patchRegistration/git/"
CLUST_PATH="/data/vision/polina/users/adalca/patchRegistration/MCC/";

# command shell file
mccSh="${CLUST_PATH}MCC_mccReg2raw/run_mccReg2raw.sh"

# this version's running path
runver="sparse_v5_span_at4Scales_lambdaedge_gridspacing_innerreps";

###############################################################################
# Running Code
###############################################################################

# execute
veroutpath="${OUTPUT_PATH}/runs_${runver}/"
for subjfolder in `ls ${veroutpath}`
do
  subjid=`echo $subjfolder | cut -d _ -f 1`
  sourceDsXFile="${BUCKNER_PATH}${subjid}/${subjid}_brain_roc_downsampled5.nii.gz"
  sourceDsXUsXMaskFile="${BUCKNER_PATH}${subjid}/${subjid}_brain_downsampled5_reinterpolated5_dsmask.nii.gz" 
  atlSeg2SubjRegNii="${BUCKNER_PATH}${subjid}/${subjid}_brain_downsampled5_reinterpolated5_reg_seg.nii.gz" 
  atlSeg2SubjRegMat="${BUCKNER_PATH}${subjid}/${subjid}_brain_downsampled5_reinterpolated5_reg.mat"
  saveSourceRawSegNii="${veroutpath}${subjfolder}/final/buckner61-seg-in-${subjid}-raw_via_${subjid}2buckner61-invWarp.nii.gz"
  lcmd="${mccSh} $mcr $sourceDsXFile $sourceDsXUsXMaskFile $atlSeg2SubjRegNii $atlSeg2SubjRegMat $saveSourceRawSegNii"

  # create sge file
  sgeopath="${veroutpath}/${subjfolder}/sge/"
  sge_par_o="--sge \"-o ${sgeopath}\""
  sge_par_e="--sge \"-e ${sgeopath}\""
  sge_par_q="" #--sge \"-q qOnePerHost \""
  sgerunfile="${sgeopath}/mccReg2raw.sh"
  cmd="${PROJECT_PATH}sge/qsub-run -c $sge_par_o $sge_par_e $sge_par_q ${lcmd} > ${sgerunfile}"
  echo $cmd
  eval $cmd

  # run sge
  sgecmd="qsub ${sgerunfile}"
  echo $sgecmd
  $sgecmd

  # sleep for a bit to give sge time to deal with the new job (?)
  sleep 1
done
