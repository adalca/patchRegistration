#!/bin/bash
# run dice on buckner registration

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
dataName='buckner'
ANTS_PATH="/data/vision/polina/scratch/adalca/patchSynthesis/data/buckner/ants/";
BUCKNER_PATH="/data/vision/polina/projects/stroke/work/patchSynthesis/data/${dataName}/proc/brain_pad10/";
BUCKNER_ATLAS_PATH="/data/vision/polina/projects/stroke/work/patchSynthesis/data/${dataName}/atlases/brain_pad10/";
OUTPUT_PATH="/data/vision/polina/scratch/patchRegistration/output/";
PROJECT_PATH="/data/vision/polina/users/adalca/patchRegistration/git/"
CLUST_PATH="/data/vision/polina/users/adalca/patchRegistration/MCC/";

# command shell file
mccSh="${CLUST_PATH}MCC_diceNii/run_diceNii.sh"

# this version's running path
runver="sparse_ds7_pad10_lambdaedge_gridspacing_innerreps";

###############################################################################
# Running Code
###############################################################################

# execute
veroutpath="${OUTPUT_PATH}/buckner/${runver}/"
for subjfolder in `ls ${veroutpath}`
do
  sourceFolder="${veroutpath}${subjfolder}/final/"
  subjid=`echo $subjfolder | cut -d _ -f 1`
  sourceWarpedSegFileNii="${sourceFolder}/buckner61-seg-in-${subjid}-raw_via_${subjid}-2-buckner61-invWarp.nii.gz";
  targetSegFileNii="${BUCKNER_PATH}${subjid}/${subjid}_proc_ds7_seg.nii.gz";
  mkdir "${veroutpath}${subjfolder}/out"
  savePath="${veroutpath}${subjfolder}/out/stats.mat";

  lcmd="${mccSh} $mcr $sourceWarpedSegFileNii $targetSegFileNii $savePath"
  echo $lcmd

  # create sge file
  sgeopath="${veroutpath}/${subjfolder}/sge/"
  sge_par_o="--sge \"-o ${sgeopath}\""
  sge_par_e="--sge \"-e ${sgeopath}\""
  sge_par_q="" #--sge \"-q qOnePerHost \""
  sgerunfile="${sgeopath}/reg2StatsPerSubject.sh"
  cmd="${PROJECT_PATH}sge/qsub-run -c $sge_par_o $sge_par_e $sge_par_q ${lcmd} > ${sgerunfile}"
  echo $cmd
  eval $cmd

  # run sge
  sgecmd="qsub ${sgerunfile}"
  echo $sgecmd
  $sgecmd

  # sleep for a bit to give sge time to deal with the new job (?)
  # sleep 1
done
