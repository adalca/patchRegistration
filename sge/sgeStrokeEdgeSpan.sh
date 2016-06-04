#!/bin/bash
# run stroke registration

###############################################################################
# Settings
###############################################################################

preptype="brain_pad10"

datatype="stroke"

dsRate="7"

lambda_edge="["
lambda_node="["
for var in "$@"
do
  lambda_edge=$lambda_edge"$var,"
  lambda_node=$lambda_node"1,"
done
lambda_node=$lambda_node"1]"
nScales=`expr $# + 1`

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
runver="PBR_v63_brainpad";

# parameters
echo "${lambda_edge}0.01]" > lambdaEdgeFile.txt
echo "${lambda_edge}0.03]" >> lambdaEdgeFile.txt
echo "${lambda_edge}0.05]" >> lambdaEdgeFile.txt
echo "${lambda_edge}0.075]" >> lambdaEdgeFile.txt
echo "${lambda_edge}0.1]" >> lambdaEdgeFile.txt
echo "${lambda_edge}0.125]" >> lambdaEdgeFile.txt
echo "${lambda_edge}0.15]" >> lambdaEdgeFile.txt
echo "${lambda_edge}0.175]" >> lambdaEdgeFile.txt
echo "${lambda_edge}0.2]" >> lambdaEdgeFile.txt
echo "${lambda_edge}0.225]" >> lambdaEdgeFile.txt
echo "${lambda_edge}0.25]" >> lambdaEdgeFile.txt
echo "${lambda_edge}0.275]" >> lambdaEdgeFile.txt
echo "${lambda_edge}0.3]" >> lambdaEdgeFile.txt
echo "${lambda_edge}0.325]" >> lambdaEdgeFile.txt
echo "${lambda_edge}0.35]" >> lambdaEdgeFile.txt
echo "${lambda_edge}0.375]" >> lambdaEdgeFile.txt
echo "${lambda_edge}0.4]" >> lambdaEdgeFile.txt
echo "${lambda_edge}0.425]" >> lambdaEdgeFile.txt
echo "${lambda_edge}0.45]" >> lambdaEdgeFile.txt
echo "${lambda_edge}0.475]" >> lambdaEdgeFile.txt
echo "${lambda_edge}0.5]" >> lambdaEdgeFile.txt

gridSpacingTemplate='"[1;2;2;3;4;${gs}]"' # use ${gs} to decide where varGridSpacing goes
varGridSpacing="5"
innerReps="3"
smallSubjects="14133 14209 14382 P0175 P0180 P0054 12191"
hardSubjects="13888 10558 10557 10534 10529 10591 10578 10575 10567 10566 10564 10592 10604"
segmSubjects="10537 10534 10530 10529 10522 14209 P0870 12191 P0054 P0180"

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
for subjid in $segmSubjects #`ls ${INPUT_PATH}`
do
echo $subjid
  while read line;
  do
    le=$line
    for gs in $varGridSpacing
    do
      for ni in $innerReps
      do
        # prepare output folder for this setting
        runfolder="${veroutpath}/${subjid}_${line}_${gs}_${ni}/"
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
	echo "; names" > ${pathsinifile}
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
        nScalesPlusOne=`expr ${nScales} + 1`
	for scale in `seq ${nScalesPlusOne}` # 1 2 3 4 5 6 `
        do
          if [ $scale -eq 1 ]
	      then continue
          fi
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
        par5="\"params.patchSize=bsxfun(@times,[1,1,1],[5,5,7,7,9,9]')\"";
	par6="\"params.nScales=$nScales\"";
        outname="${outfolder}/%d_%d.mat"
        lcmd="${mccSh} $mcr ${pathsinifile} ${paramsinifile} ${optsinifile} $par1 $par2 $par3 $par4 $par5 $par6"

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
        # sleep 1
      done
    done
  done < lambdaEdgeFile.txt
  cnt=`expr $cnt + 1`
  if [ "$cnt" -eq "100" ] ; then
    exit 0;
  fi
done
