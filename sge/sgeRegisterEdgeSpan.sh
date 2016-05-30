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

# this version's running path
runver="PBR_v527_brainpad";

# parameters
lambda_edge="0.03 0.05 0.075 0.1 0.125"
lambda_edge1="0.01 0.01 0.03 0.03 0.05 0.05 0.075"
lambda_edge2="0.01 0.03 0.03 0.05 0.05 0.075 0.1"
lambda_edge3="0.03 0.03 0.03 0.03 0.03 0.03 0.03"
lambda_edge4="0.03 0.03 0.05 0.05 0.075 0.075 0.1"
lambda_edge5="0.03 0.05 0.05 0.075 0.075 0.1 0.125"
lambda_edge6="0.05 0.05 0.05 0.05 0.05 0.05 0.05"
lambda_edge7="0.05 0.05 0.075 0.075 0.1 0.1 0.125"
lambda_edge8="0.05 0.075 0.075 0.1 0.1 0.125 0.15"
lambda_edge9="0.075 0.075 0.075 0.075 0.075 0.075 0.075"
lambda_edge10="0.075 0.075 0.075 0.1 0.1 0.125 0.125"
lambda_edge11="0.1 0.1 0.1 0.1 0.1 0.1 0.1"
declare -a lambda_edge=(${lambda_edge1} ${lambda_edge2} ${lambda_edge3} ${lambda_edge4} ${lambda_edge5} ${lambda_edge6} ${lambda_edge7} ${lambda_edge8} ${lambda_edge9} ${lambda_edge10} ${lambda_edge11})
lambda_node="[1, 1, 1, 1, 1, 1, 1]"
gridSpacingTemplate='"[1;1;2;2;3;3;4;4;${gs}]"' # use ${gs} to decide where varGridSpacing goes
echo "$gridSpacingTemplate"
varGridSpacing="5"
innerReps="3"
smallSubjects="13888 14133 14209 14382 P0175 P0180 P0054 12191"
hardSubjects="13888 10558 10557 10534 10529 10591 10578 10575 10567 10566 10564 10592 10604"
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
  for i in {1..11}
  do
    le="[${lambda_edge[(${i}-1)*7+0]}, ${lambda_edge[(${i}-1)*7+1]}, ${lambda_edge[(${i}-1)*7+2]}, ${lambda_edge[(${i}-1)*7+3]}, ${lambda_edge[(${i}-1)*7+4]}, ${lambda_edge[(${i}-1)*7+5]}, ${lambda_edge[(${i}-1)*7+6]}]"
    for gs in $varGridSpacing
    do

      for ni in $innerReps
      do
        # prepare output folder for this setting
        runfolder="${veroutpath}/${subjid}_${i}_${gs}_${ni}/"
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
        par1="\"params.mrf.lambda_edge=${le};\"";
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
