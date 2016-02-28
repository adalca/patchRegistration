#!/bin/bash
# run sparse buckner registration

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
paramsinifile="${PROJECT_PATH}/configs/buckner/bucknerParams7.ini";
optsinifile="${PROJECT_PATH}/configs/buckner/bucknerOpts.ini";

# command shell file
mccSh="${CLUST_PATH}MCC_registerNii/run_registerNii.sh"

# this version's running path
runver="sparse_v5_span_at4Scales_lambdaedge_gridspacing_innerreps";

# parameters
lambda_edge="0.002 0.005 0.01 0.05"
lambda_edge="0.01"
gridSpacingTemplate='"[1;2;2;3;3;3;${gs}]"' # use ${gs} to decide where varGridSpacing goes
echo "$gridSpacingTemplate"
varGridSpacing="3 5 7"
innerReps="1 2"

###############################################################################
# Running Code
###############################################################################

# prepare general running folder
veroutpath="${OUTPUT_PATH}/runs_${runver}/"
mkdir -p $veroutpath;

# copy myself. # unfortunately this complicates the folder :(
# myfolder="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )";
# myself=${myfolder}/`basename "$0"`
# cp $myself $veroutpath

# run jobs
for subjid in `ls ${BUCKNER_PATH}`
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
        echo "sourceFile = ${BUCKNER_PATH}${subjid}/${subjid}_brain_downsampled7_reinterpolated7_reg.nii.gz" >> ${pathsinifile}
        echo "targetFile = ${BUCKNER_ATLAS_PATH}buckner61_brain_proc.nii.gz" >> ${pathsinifile}
        echo "sourceMaskFile = ${BUCKNER_PATH}${subjid}/${subjid}_brain_downsampled7_reinterpolated7_dsmask_reg.nii.gz" >> ${pathsinifile}
        echo "targetMaskFile = ${BUCKNER_ATLAS_PATH}buckner61_brain_proc_allones.nii.gz" >> ${pathsinifile}
        echo "sourceSegFile = ${BUCKNER_PATH}${subjid}/${subjid}_brain_iso_2_ds7_us7_size_reg_seg.nii.gz" >> ${pathsinifile}
        echo "targetSegFile = ${BUCKNER_ATLAS_PATH}buckner61_seg_proc.nii.gz" >> ${pathsinifile}

        echo "; output paths" >> ${pathsinifile}
        echo "savepathout = ${outfolder}" >> ${pathsinifile}
        echo "savepathfinal = ${finalfolder}" >> ${pathsinifile}

        echo "; names" >> ${pathsinifile}
        echo "sourceName = ${subjid}" >> ${pathsinifile}
        echo "targetName = buckner61" >> ${pathsinifile}

        echo "; scales" >> ${pathsinifile}
        srcScales="sourceScales = {"
        tarScales="targetScales = {"
        srcMaskScales="sourceMaskScales = {"
        tarMaskScales="targetMaskScales = {"
        for scale in 1 2 3 4 5 6 7
        do
          srcScales=${srcScales}"'${BUCKNER_PATH}${subjid}/${subjid}_brain_downsampled7_reinterpolated${scale}_reg.nii.gz' "
          tarScales=${tarScales}"'${BUCKNER_ATLAS_PATH}buckner61_brain_proc_ds7_us${scale}.nii.gz' "
          srcMaskScales=${srcMaskScales}"'${BUCKNER_PATH}${subjid}/${subjid}_brain_downsampled7_reinterpolated${scale}_dsmask_reg.nii.gz' "
          tarMaskScales=${tarMaskScales}"'${BUCKNER_ATLAS_PATH}buckner61_brain_proc_ds7_us${scale}_allones.nii.gz' "
        done
        echo "${srcScales}}" >> ${pathsinifile}
        echo "${tarScales}}" >> ${pathsinifile}
        echo "${srcMaskScales}}" >> ${pathsinifile}
        #echo "${tarMaskScales}}" >> ${pathsinifile}


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
        sge_par_l="--sge \"-l mem_free=100G \""
        sge_par_q="--sge \"-q qOnePerHost \""
        cmd="${PROJECT_PATH}sge/qsub-run -c $sge_par_q $sge_par_o $sge_par_e $sge_par_l ${lcmd} > ${sgerunfile}"
        echo $cmd
        eval $cmd

        # run sge
        chmod a+x ${sgerunfile}
        sgecmd="qsub ${sgerunfile}"
        echo -e "$sgecmd\n"
        $sgecmd

        # sleep for a bit to give sge time to deal with the new job (?)
         #sleep 10
      done
    done
  done
done
