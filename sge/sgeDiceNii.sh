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
ANTS_PATH="/data/vision/polina/scratch/adalca/patchSynthesis/data/buckner/ants/";
BUCKNER_PATH="/data/vision/polina/scratch/adalca/patchSynthesis/data/buckner/proc/";
BUCKNER_ATLAS_PATH="/data/vision/polina/scratch/adalca/patchSynthesis/data/buckner/atlases/";
OUTPUT_PATH="/data/vision/polina/scratch/patchRegistration/output/";
PROJECT_PATH="/data/vision/polina/users/adalca/patchRegistration/git/"
CLUST_PATH="/data/vision/polina/users/adalca/patchRegistration/MCC/";

# command shell file
mccSh="${CLUST_PATH}MCC_diceNii/run_diceNii.sh"

# this version's running path
runver="sparse_v5_span_at4Scales_lambdaedge_gridspacing_innerreps";

###############################################################################
# Running Code
###############################################################################

# execute
veroutpath="${ANTS_PATH}"
for subjfolder in `ls ${veroutpath}`
do
  sourceFolder="${veroutpath}${subjfolder}"
  #subjid=`echo $subjfolder | cut -d _ -f 1`
  sourceWarpedSegFileNii="${sourceFolder}/buckner61_seg_to_${subjfolder}_brain_roc_Ds7_Ds7-to-atlas.nii.gz";
  targetSegFileNii="${BUCKNER_PATH}${subjfolder}/${subjfolder}_brain_iso_2_ds7_us7_size_reg_seg.nii.gz";
  mkdir "${sourceFolder}/out"
  savePath="${sourceFolder}/out/stats.mat"; 
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
  sleep 1
done
