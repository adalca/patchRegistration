#!/bin/bash
# run sparse buckner registration

###############################################################################
# Settings
###############################################################################

preptype="wholevol"
preptype="brain_pad10"

datatype="buckner"
datatype="stroke"

dsRate="9"

# prepare SGE variables necessary to move SGE environment away from AFS.
export SGE_LOG_PATH=/data/vision/polina/scratch/adalca/patchSynthesis/sge/
export SGE_O_PATH=${SGE_LOG_PATH}
export SGE_O_HOME=${SGE_LOG_PATH}

# MCR file. This has to match the MCC version used in mcc.sh
mcr=/data/vision/polina/shared_software/MCR/v82/

# project paths
INPUT_PATH="/data/vision/polina/projects/stroke/work/patchSynthesis/data/${datatype}/proc/${preptype}/";
ATLAS_PATH="/data/vision/polina/projects/stroke/work/patchSynthesis/data/${datatype}/atlases/${preptype}/";
OUTPUT_PATH="/data/vision/polina/scratch/patchRegistration/output/";
PROJECT_PATH="/data/vision/polina/users/adalca/patchRegistration/git/"
CLUST_PATH="/data/vision/polina/users/adalca/patchRegistration/MCC/";
paramsinifile="${PROJECT_PATH}/configs/buckner/bucknerParams${dsRate}.ini";
optsinifile="${PROJECT_PATH}/configs/buckner/bucknerOpts.ini";

# command shell file
mccSh="${CLUST_PATH}MCC_registerNii/run_registerNii.sh"
# mccSh="${CLUST_PATH}MCC_mccDispl2niftis/run_mccDispl2niftis.sh"

# this version's running path
runver="PBR_v101_wholevol";

# parameters
lambda_edge="0.005 0.01 0.03 0.05 0.1"
gridSpacingTemplate='"[1;1;2;2;3;3;4;4;${gs}]"' # use ${gs} to decide where varGridSpacing goes
echo "$gridSpacingTemplate"
varGridSpacing="4"
innerReps="3"

###############################################################################
# Running Code
###############################################################################

# prepare general running folder
veroutpath="${OUTPUT_PATH}/${datatype}/${runver}/"
mkdir -p $veroutpath;

# copy myself. # unfortunately this complicates the folder :(
# myfolder="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )";
# myself=${myfolder}/`basename "$0"`
# cp $myself $veroutpath

# run jobs
cnt=0
for subjid in `ls ${INPUT_PATH}`
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
        echo "sourceFile = ${INPUT_PATH}${subjid}/${subjid}_ds${dsRate}_us${dsRate}_reg.nii.gz" >> ${pathsinifile}
        echo "targetFile = ${ATLAS_PATH}${datatype}61_brain_proc.nii.gz" >> ${pathsinifile}
        echo "sourceMaskFile = ${INPUT_PATH}${subjid}/${subjid}_ds${dsRate}_us${dsRate}_dsmask_reg.nii.gz" >> ${pathsinifile}
        echo "sourceSegFile = ${INPUT_PATH}${subjid}/${subjid}_ds${dsRate}_us${dsRate}_reg_seg.nii.gz" >> ${pathsinifile}
        echo "sourceRawSegFile = ${INPUT_PATH}${subjid}/${subjid}_proc_ds${dsRate}_seg.nii.gz" >> ${pathsinifile}
        echo "targetSegFile = ${ATLAS_PATH}${datatype}61_seg_proc.nii.gz" >> ${pathsinifile}

        echo "; output paths" >> ${pathsinifile}
        echo "savepathout = ${outfolder}" >> ${pathsinifile}
        echo "savepathfinal = ${finalfolder}" >> ${pathsinifile}

        echo "; names" >> ${pathsinifile}
        echo "sourceName = ${subjid}" >> ${pathsinifile}
        echo "targetName = ${datatype}61" >> ${pathsinifile}

        echo "; scales" >> ${pathsinifile}
        srcScales="sourceScales = {"
        tarScales="targetScales = {"
        srcMaskScales="sourceMaskScales = {"
        tarMaskScales="targetMaskScales = {"
        for scale in `seq ${dsRate}` # 1 2 3 4 5 6 `
        do
          srcScales=${srcScales}"'${INPUT_PATH}${subjid}/${subjid}_ds${dsRate}_us${scale}_reg.nii.gz' "
          tarScales=${tarScales}"'${ATLAS_PATH}${datatype}61_brain_proc_ds${dsRate}_us${scale}.nii.gz' "
          srcMaskScales=${srcMaskScales}"'${INPUT_PATH}${subjid}/${subjid}_ds${dsRate}_us${scale}_dsmask_reg.nii.gz' "
          tarMaskScales=${tarMaskScales}"'${INPUT_PATH}${subjid}/${subjid}_ds${dsRate}_us${scale}_dsmask_reg.nii.gz' "
        done
        echo "${srcScales}}" >> ${pathsinifile}
        echo "${tarScales}}" >> ${pathsinifile}
        echo "${srcMaskScales}}" >> ${pathsinifile}
        # echo "${tarMaskScales}}" >> ${pathsinifile} # note, not adding target masks!

        # prepare registration parameters and job
        par1="\"params.mrf.lambda_edge=[${le}, ${le}, ${le}, ${le}, ${le}, ${le}, ${le}];\"";
        gstext=`eval "echo ${gridSpacingTemplate}"`
        par2="\"params.gridSpacing=bsxfun(@times,[1,1,1],$gstext);\"";
        par3="\"params.nInnerReps=${ni};\"";
        outname="${outfolder}/%d_%d.mat"
        lcmd="${mccSh} $mcr ${pathsinifile} ${paramsinifile} ${optsinifile} $par1 $par2 $par3"

        # create sge file
        sge_par_o="--sge \"-o ${sgeopath}\""
        sge_par_e="--sge \"-e ${sgeopath}\""
        sge_par_l="--sge \"-l mem_free=100G \""
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
         #sleep 10
      done
    done
  done
  cnt=`expr $cnt + 1`
  if [ "$cnt" -eq "100" ] ; then
    exit 0;
  fi
done
