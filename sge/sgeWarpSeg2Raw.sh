#!/bin/bash
# warp segmentations from 'affine' space to raw space
#
# sgeWarpSeg2Raw.sh dataset runver
#
# examples
# >$ sgeWarpSeg2Raw.sh buckner runs_sparse_v5_span_at4Scales_lambdaedge_gridspacing_innerreps <dsFact>
# >$ sgeWarpSeg2Raw.sh stroke PBR_v3 <dsFact>

if [ "$#" -lt 2 ] ; then
  echo "Usage: $0 dataName runver <dsFact>" >&2
  exit 1
fi

###############################################################################
# Parameters
###############################################################################

# this version's info
dataName=$1 # stroke or buckner
runver=$2 # e.g. PBR_v3
if [ "$#" -lt 3 ] ; then dsRate="7"; else dsRate="$3"; fi

# prepare data
PROC_PATH="/data/vision/polina/projects/stroke/work/patchSynthesis/data/${dataName}/proc/brain_pad10/";
ATLAS_PATH="/data/vision/polina/projects/stroke/work/patchSynthesis/data/${dataName}/atlases/brain_pad10/";
ATLAS_FILE_SUFFIX="${dataName}61";

###############################################################################
# Program Settings
###############################################################################

# prepare SGE variables necessary to move SGE environment away from AFS.
export SGE_LOG_PATH=/data/vision/polina/scratch/adalca/patchSynthesis/sge/
export SGE_O_PATH=${SGE_LOG_PATH}
export SGE_O_HOME=${SGE_LOG_PATH}

# MCR file. This has to match the MCC version used in mcc.sh
mcr=/data/vision/polina/shared_software/MCR/v82/

# project paths
OUTPUT_PATH="/data/vision/polina/scratch/patchRegistration/output/${dataName}/";
PROJECT_PATH="/data/vision/polina/users/adalca/patchRegistration/git/"
CLUST_PATH="/data/vision/polina/users/adalca/patchRegistration/MCC/";

# command shell file
mccSh="${CLUST_PATH}MCC_mccReg2raw/run_mccReg2raw.sh"

###############################################################################
# Running Code
###############################################################################

# execute
veroutpath="${OUTPUT_PATH}/${runver}/"
for subjfolder in `ls ${veroutpath}`
do
  subjid=`echo $subjfolder | cut -d _ -f 1`
  sourceDsXFile="${PROC_PATH}${subjid}/${subjid}_proc_ds${dsRate}.nii.gz"
  sourceDsXUsXMaskFile="${PROC_PATH}${subjid}/${subjid}_ds${dsRate}_us${dsRate}_dsmask.nii.gz"
  atlSeg2SubjRegNii="${veroutpath}${subjfolder}/final/${ATLAS_FILE_SUFFIX}-seg-in-${subjid}_via_${subjid}-2-${ATLAS_FILE_SUFFIX}-invWarp.nii.gz"
  atlSeg2SubjRegMat="${PROC_PATH}${subjid}/${subjid}_ds${dsRate}_us${dsRate}_reg.mat"
  saveSourceRawSegNii="${veroutpath}${subjfolder}/final/${ATLAS_FILE_SUFFIX}-seg-in-${subjid}-raw_via_${subjid}-2-${ATLAS_FILE_SUFFIX}-invWarp.nii.gz"
  lcmd="${mccSh} $mcr $sourceDsXFile $sourceDsXUsXMaskFile $atlSeg2SubjRegNii $atlSeg2SubjRegMat $saveSourceRawSegNii"

  if [ -f $saveSourceRawSegNii ] ; then
     continue;
  fi

  # create sge file
  sgeopath="${veroutpath}/${subjfolder}/sge/"
  sge_par_o="--sge \"-o ${sgeopath}\""
  sge_par_e="--sge \"-e ${sgeopath}\""
  sge_par_l="--sge \"-l mem_free=100G \""
  sge_par_q="" #--sge \"-q qOnePerHost \""
  sgerunfile="${sgeopath}/mccReg2raw.sh"
  cmd="${PROJECT_PATH}sge/qsub-run -c $sge_par_o $sge_par_e $sge_par_l $sge_par_q ${lcmd} > ${sgerunfile}"
  echo $cmd
  eval $cmd
  chmod a+x ${sgerunfile}

  # run sge
  sgecmd="qsub ${sgerunfile}"
  echo $sgecmd
  $sgecmd

  # sleep for a bit to give sge time to deal with the new job (?)
  # sleep 1
done
