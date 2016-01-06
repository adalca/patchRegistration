#!/bin/bash
# run subspace training

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
veroutpath="${OUTPUT_PATH}/runs_${runver}/"
mkdir -p $veroutpath;

# training shell file
mccSh="${CLUST_PATH}MCC_registerBuckner/run_registerBuckner.sh"

# running parameters
for subjid in `ls ${BUCKNER_PATH}`;
do

  for le in 0.01 0.25 0.05 0.1;
  do

    for gs in 3 5 7 9; # 2 3 5 7 9
    do

      for ni in 2 4;
      do

        par1="\"params.mrf.lambda_edge=${le};\"";
        par2="\"'params.gridSpacing(4,:)=${gs}'\"";
        par2="\"'params.gridSpacing=bsxfun(@times,o3,[1,2,2,2,2,3,${gs}]'');'\"";
        par3="\"params.nInnerReps=${ni};\"";

        outname="${veroutpath}/${subjid}_${le}_${gs}_${ni}/"
        mkdir -p $outname
        outname="${outname}/%d_%d.mat"

        # run training.
        cmd="${PROJECT_PATH}sge/qsub-run ${mccSh} $mcr $BUCKNER_PATH $BUCKNER_ATLAS_PATH $outname $subjid $par1 $par2 $par3 -l mem_free=50G"
        echo $cmd
        $cmd

        sleep 5
      done
    done
  done
done
