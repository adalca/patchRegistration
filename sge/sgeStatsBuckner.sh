#!/bin/bash
# run statistics on buckner registration

###############################################################################
# Settings
###############################################################################

# MCR file. This has to match the MCC version used in mcc.sh
mcr=/data/vision/polina/shared_software/MCR/v82/

# project paths
BUCKNER_PATH="/data/vision/polina/scratch/adalca/patchSynthesis/data/buckner/proc/";
BUCKNER_ATLAS_PATH="/data/vision/polina/scratch/adalca/patchSynthesis/data/buckner/atlases/";
OUTPUT_PATH="/data/vision/polina/scratch/patchRegistration/output/";
PROJECT_PATH="/data/vision/polina/users/adalca/patchRegistration/git/"
CLUST_PATH="/data/vision/polina/users/adalca/patchRegistration/MCC/";

# command shell file
mccSh="${CLUST_PATH}MCC_registerBuckner/run_registerBuckner.sh"

# this version's running path
runver="span_at4Scales_lambdaedge_gridspacing_innerreps";

###############################################################################
# Running Code
###############################################################################

# execute
veroutpath="${OUTPUT_PATH}/runs_${runver}/"
for subjfolder in "${veroutpath}/*"
do
  infolder = "${veroutpath}/${subjfolder}/"
  outfile = "${infolder}/stats.mat"
  lcmd="${mccSh} $mcr $infolder $outfile"

  # create sge file
  sgerunfile = "${infolder}/sge/reg2stats.sh"
  sge_par_o="--sge \"-o ${sgeopath}\""
  sge_par_e="--sge \"-e ${sgeopath}\""
  cmd="${PROJECT_PATH}sge/qsub-run -c $sge_par_o $sge_par_e ${lcmd} > ${sgerunfile}"
  echo $cmd
  eval $cmd

  # run sge
  sgecmd="qsub ${sgerunfile}"
  echo $sgecmd
  $sgecmd

  sleep 1
done
