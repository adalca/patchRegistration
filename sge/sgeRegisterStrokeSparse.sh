#!/bin/bash
# run sparse stroke registration


if [ "$#" -ne 0 ] ; then
  echo "Usage: $0 " >&2
  exit 1
fi

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
STROKE_PATH="/data/vision/polina/projects/stroke/work/patchSynthesis/data/stroke/proc/brain_pad10/";
STROKE_ATLAS_PATH="/data/vision/polina/projects/stroke/work/patchSynthesis/data/stroke/atlases/brain_pad10/";
OUTPUT_PATH="/data/vision/polina/scratch/patchRegistration/output/";
PROJECT_PATH="/data/vision/polina/users/adalca/patchRegistration/git/"
CLUST_PATH="/data/vision/polina/users/adalca/patchRegistration/MCC/";
paramsinifile="${PROJECT_PATH}/configs/stroke/strokeParams.ini";
optsinifile="${PROJECT_PATH}/configs/stroke/strokeOpts.ini";

# command shell file
mccSh="${CLUST_PATH}MCC_registerNii/run_registerNii.sh"

# this version's running path
runver="stroke/PBR_v5";

# parameters
lambda_edge="0.1 0.05 0.01 0.005" #"0.1 0.15 0.2"
# lambda_edge="0.01"
gridSpacingTemplate='"[1;1;2;2;3;3;${gs}]"' # use ${gs} to decide where varGridSpacing goes
echo "$gridSpacingTemplate"
varGridSpacing="3 5 7"
innerReps="1 2"

###############################################################################
# Running Code
###############################################################################

# prepare general running folder
veroutpath="${OUTPUT_PATH}/${runver}/"
mkdir -p $veroutpath;

# copy myself. # unfortunately this complicates the folder :(
# myfolder="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )";
# myself=${myfolder}/`basename "$0"`
# cp $myself $veroutpath

# run jobs
# 10529 10530 10534 10537
for subjid in 10543 10546 10553 10557 10558 10564 10566 10567 10571 10575 #`ls ${STROKE_PATH}`
do

  for le in $lambda_edge
  do

    for gs in $varGridSpacing
    do

      for ni in $innerReps
      do
        # prepare output folder for this setting
        runfolder="${veroutpath}/${subjid}_${le}_${gs}_${ni}/"
        mkdir -p $runfolder
        outfolder="${runfolder}/out/"
        mkdir -p $outfolder
        finalfolder="${runfolder}/final/"
        mkdir -p $finalfolder
        sgeopath="${runfolder}/sge/"
        mkdir -p $sgeopath

        # sge file which we will execute
        sgerunfile="${sgeopath}/register.sh"

        # need to output/prepare paths.ini for each subject. Can use standard bucknerParams.ini and bucknerOpts.ini
        pathsinifile="${runfolder}/paths.ini"
        echo "; paths" > ${pathsinifile}
        echo "sourceFile = ${STROKE_PATH}${subjid}/${subjid}_ds7_us7_reg.nii.gz" >> ${pathsinifile}
        echo "targetFile = ${STROKE_ATLAS_PATH}stroke61_brain_proc_ds7_us7.nii.gz" >> ${pathsinifile}
        echo "sourceMaskFile = ${STROKE_PATH}${subjid}/${subjid}_ds7_ds7_dsmask_reg.nii.gz" >> ${pathsinifile}
        echo "targetSegFile = ${STROKE_ATLAS_PATH}stroke61_seg_proc.nii.gz" >> ${pathsinifile}

        echo "; output paths" >> ${pathsinifile}
        echo "savepathout = ${outfolder}" >> ${pathsinifile}
        echo "savepathfinal = ${finalfolder}" >> ${pathsinifile}

        echo "; names" >> ${pathsinifile}
        echo "sourceName = ${subjid}" >> ${pathsinifile}
        echo "targetName = stroke61" >> ${pathsinifile}

        echo "; scales" >> ${pathsinifile}
        srcScales="sourceScales = {"
        tarScales="targetScales = {"
        srcMaskScales="sourceMaskScales = {"
        for scale in 1 2 3 4 5 6 7
        do
          srcScales=${srcScales}"'${STROKE_PATH}${subjid}/${subjid}_ds7_us${scale}_reg.nii.gz' "
          tarScales=${tarScales}"'${STROKE_ATLAS_PATH}stroke61_brain_proc_ds7_us${scale}.nii.gz' "
          srcMaskScales=${srcMaskScales}"'${STROKE_PATH}${subjid}/${subjid}_ds7_us${scale}_dsmask_reg.nii.gz' "
        done
        echo "${srcScales}}" >> ${pathsinifile}
        echo "${tarScales}}" >> ${pathsinifile}
        echo "${srcMaskScales}}" >> ${pathsinifile}

        # prepare registration parameters and job
        par1="\"params.mrf.lambda_edge=${le};\"";
        gstext=`eval "echo ${gridSpacingTemplate}"`
        par2="\"params.gridSpacing=bsxfun(@times,[1,1,1],$gstext);\"";
        par3="\"params.nInnerReps=${ni};\"";
        outname="${outfolder}/%d_%d.mat"
        lcmd="${mccSh} $mcr ${pathsinifile} ${paramsinifile} ${optsinifile} $par1 $par2 $par3"

        # create sge file
        sge_par_o="--sge \"-o ${sgeopath}\""
        sge_par_e="--sge \"-e ${sgeopath}\""
        sge_par_l="--sge \"-l mem_free=150G \""
        sge_par_q="" #--sge \"-q qOnePerHost \""
        cmd="${PROJECT_PATH}sge/qsub-run -c $sge_par_q $sge_par_o $sge_par_e $sge_par_l ${lcmd} > ${sgerunfile}"
        echo $cmd
        eval $cmd

        # run sge
        chmod a+x ${sgerunfile}
        sgecmd="qsub ${sgerunfile}"
        echo -e "$sgecmd\n"
        $sgecmd

        # sleep for a bit to give sge time to deal with the new job (?)
        # sleep 10
      done
    done
  done
done
