#!/bin/bash
# run sparse buckner registration

###############################################################################
# Settings
###############################################################################

preptype="brain_pad10"

datatype="stroke"

dsRate="7"

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
paramsinifile="${PROJECT_PATH}/configs/stroke/strokeParams.ini";
optsinifile="${PROJECT_PATH}/configs/stroke/strokeOpts.ini";

# command shell file
mccSh="${CLUST_PATH}MCC_registerNii/run_registerNii.sh"
# mccSh="${CLUST_PATH}MCC_mccDispl2niftis/run_mccDispl2niftis.sh"

# this version's running path
runver="PBR_v516_brainpad";

# parameters
lambda_edge="0.005 0.01 0.03 0.05 0.1"
lambda_node="[1, 1, 1, 1, 1, 1, 1]"
gridSpacingTemplate='"[1;1;2;2;3;3;4;4;${gs}]"' # use ${gs} to decide where varGridSpacing goes
echo "$gridSpacingTemplate"
varGridSpacing="3 4 5 7"
innerReps="3"
hardSubjects="12191 12469 13888 13916 P0054"

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
for subjid in $hardSubjects #`ls ${INPUT_PATH}`
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
	echo "; names" >> ${pathsinifile}
	echo "targetName = ${subjid}" >> ${pathsinifile}
	echo "sourceName = ${datatype}61" >> ${pathsinifile}
        echo "; paths" >> ${pathsinifile}
        echo "targetFile = ${INPUT_PATH}${subjid}/${subjid}_ds${dsRate}_us${dsRate}_reg.nii.gz" >> ${pathsinifile}
        echo "sourceFile = ${ATLAS_PATH}${datatype}61_brain_proc_ds${dsRate}_us${dsRate}.nii.gz" >> ${pathsinifile}
        echo "sourceSegFile = ${ATLAS_PATH}${datatype}61_seg_proc_ds${dsRate}_us${dsRate}.nii.gz" >> ${pathsinifile}

        echo "; output paths" >> ${pathsinifile}
        echo "savepathout = ${outfolder}" >> ${pathsinifile}
        echo "savepathfinal = ${finalfolder}" >> ${pathsinifile}

        echo "; scales" >> ${pathsinifile}
        srcScales="sourceScales = {"
        tarScales="targetScales = {"
        tarMaskScales="targetMaskScales = {"
        for scale in `seq ${dsRate}` # 1 2 3 4 5 6 `
        do
          tarScales=${tarScales}"'${INPUT_PATH}${subjid}/${subjid}_ds${dsRate}_us${scale}_reg.nii.gz' "
          srcScales=${srcScales}"'${ATLAS_PATH}${datatype}61_brain_proc_ds${dsRate}_us${scale}.nii.gz' "
          tarMaskScales=${tarMaskScales}"'${INPUT_PATH}${subjid}/${subjid}_ds${dsRate}_us${scale}_dsmask_reg.nii.gz' "
        done
        echo "${srcScales}}" >> ${pathsinifile}
        echo "${tarScales}}" >> ${pathsinifile}
        echo "${tarMaskScales}}" >> ${pathsinifile}
        # echo "${srcMaskScales}}" >> ${pathsinifile} # note, not adding source masks!
	
	echo "; raw source" >> ${pathsinifile}
	echo "targetRawMaskFile = ${INPUT_PATH}${subjid}/${subjid}_ds${dsRate}_us${dsRate}_dsmask.nii.gz" >> ${pathsinifile}
	echo "affineDispl = ${INPUT_PATH}${subjid}/${subjid}_ds${dsRate}_us${dsRate}_reg.mat" >> ${pathsinifile}	

        # prepare registration parameters and job
        par1="\"params.mrf.lambda_edge=[${le}, ${le}, ${le}, ${le}, ${le}, ${le}, ${le}];\"";
        gstext=`eval "echo ${gridSpacingTemplate}"`
        par2="\"params.gridSpacing=bsxfun(@times,[1,1,1],$gstext);\"";
        par3="\"params.nInnerReps=${ni};\"";
	par4="\"params.mrf.lambda_node=${lambda_node}\"";
        outname="${outfolder}/%d_%d.mat"
        lcmd="${mccSh} $mcr ${pathsinifile} ${paramsinifile} ${optsinifile} $par1 $par2 $par3 $par4"

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
