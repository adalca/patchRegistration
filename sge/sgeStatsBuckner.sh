#!/bin/bash
# run statistics on buckner registration

# prepare SGE variables
export SGE_LOG_PATH=/data/vision/polina/scratch/adalca/patchSynthesis/sge/
export SGE_O_PATH=${SGE_LOG_PATH}
export SGE_O_HOME=${SGE_LOG_PATH}
mkdir -p $SGE_LOG_PATH
echo $SGE_O_HOME

# MCR file. This has to match the MCC version used in mcc.sh
mcr=/data/vision/polina/shared_software/MCR/v82/

# project paths
BUCKNER_PATH="/data/vision/polina/scratch/adalca/patchSynthesis/data/buckner/proc/";
BUCKNER_ATLAS_PATH="/data/vision/polina/scratch/adalca/patchSynthesis/data/buckner/atlases/";
OUTPUT_PATH="/data/vision/polina/scratch/patchRegistration/output/";
PROJECT_PATH="/data/vision/polina/users/adalca/patchRegistration/git/"
CLUST_PATH="/data/vision/polina/users/adalca/patchRegistration/MCC/";

# this version's running path
runver="span_le_ds";

# command shell file
mccSh="${CLUST_PATH}MCC_registerBuckner/run_reg2stats.sh"

# execute
veroutpath="${OUTPUT_PATH}/runs_${runver}/"
for subjfolder in "${veroutpath}/*"
do
  infolder = "${veroutpath}/${subjfolder}/"
  outfile = "${infolder}/stats.mat"

  sgeopath = "${infolder}/sge/"
  mkdir -p $sgeopath

  cmd="${PROJECT_PATH}sge/qsub-run ${mccSh} $mcr $infolder $outfile -o $sgeopath -e $sgeopath"
  echo $cmd
  $cmd

  sleep 1
done
