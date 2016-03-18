#!/bin/bash
# run dice on ${dataName} registration
# sgeDiceNii dataType runver dsRate

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
dataName='ADNI_T1_baselines'
dataName="$1"
dsRate="$3"
ANTS_PATH="/data/vision/polina/scratch/adalca/patchSynthesis/data/${dataName}/ants/";
BUCKNER_PATH="/data/vision/polina/projects/stroke/work/patchSynthesis/data/${dataName}/proc/brain_pad10/";
BUCKNER_ATLAS_PATH="/data/vision/polina/projects/stroke/work/patchSynthesis/data/${dataName}/atlases/brain_pad10/";
OUTPUT_PATH="/data/vision/polina/scratch/patchRegistration/output/";
PROJECT_PATH="/data/vision/polina/users/adalca/patchRegistration/git/"
CLUST_PATH="/data/vision/polina/users/adalca/patchRegistration/MCC/";

# command shell file
mccSh="${CLUST_PATH}MCC_diceNii/run_diceNii.sh"

# this version's running path
runver="sparse_ds7_pad10_lambdaedge_gridspacing_innerreps";
runver="ANTs_v3_raw_fromDs7us7Reg_continueAffine_multiparam"
runver="ANTs_v102_brainpad10_ds7us7reg_multiparam"
runver="$2"

###############################################################################
# Running Code
###############################################################################

# execute
veroutpath="${OUTPUT_PATH}/${dataName}/${runver}/"
for subjfolder in `ls ${veroutpath}`
do
  sourceFolder="${veroutpath}${subjfolder}/final/"
  subjid=`echo $subjfolder | cut -d _ -f 1`
  sourceWarpedSegFileNii="${sourceFolder}/${dataName}61-seg-in-${subjid}-raw_via_${subjid}-2-${dataName}61-invWarp.nii.gz";
  targetSegFileNii="${BUCKNER_PATH}${subjid}/${subjid}_proc_ds${dsRate}_seg.nii.gz";
  mkdir "${veroutpath}${subjfolder}/out" > /dev/null 2> /dev/null
  savePath="${veroutpath}${subjfolder}/out/stats.mat";

  if [ ! -f ${sourceWarpedSegFileNii} ] ; then echo "skipping ${subjid} due to missing ${sourceWarpedSegFileNii}"; continue; fi
  if [ ! -f $targetSegFileNii ] ; then echo "skipping ${subjid} due to missing ${targetSegFileNii}"; continue; fi
  if [ -f $savePath ] ; then echo "skipping ${subjid} since ${savePath} already exists."; continue; fi

  lcmd="${mccSh} $mcr $sourceWarpedSegFileNii $targetSegFileNii $savePath"
  echo $lcmd

  # create sge file
  sgeopath="${veroutpath}/${subjfolder}/sge/"
  sge_par_o="--sge \"-o ${sgeopath}\""
  sge_par_e="--sge \"-e ${sgeopath}\""
      sge_par_l="--sge \"-l mem_free=100G \""
  sge_par_q="" #--sge \"-q qOnePerHost \""
  sgerunfile="${sgeopath}/reg2StatsPerSubject_${subjid}.sh"
  cmd="${PROJECT_PATH}sge/qsub-run -c $sge_par_o $sge_par_e $sge_par_q $sge_par_l ${lcmd} > ${sgerunfile}"
  # echo $cmd
  eval $cmd

  # run sge
  sgecmd="qsub ${sgerunfile}"
  echo $sgecmd
  $sgecmd

  # sleep for a bit to give sge time to deal with the new job (?)
  # sleep 1
done
