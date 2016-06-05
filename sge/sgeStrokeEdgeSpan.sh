    #!/bin/bash
# run stroke registration

###############################################################################
# General options
###############################################################################

preptype="brain_pad10"
datatype="stroke"
dsRate="7"
lambdaEdgeFile="lambdaEdgeFile.txt"
runver="PBR_v63_brainpad"; # this version's running version

lambda_edge="["
lambda_node="["
for var in "$@"
do
  lambda_edge=$lambda_edge"$var,"
  lambda_node=$lambda_node"1,"
done
lambda_node=$lambda_node"1]"

###############################################################################
# Parameters
###############################################################################

lambdaEdgeOptions="0.01 0.03 0.05 0.075 0.1 0.125 0.15 0.175 0.2 0.225 0.25 0.275 0.3 0.325 0.35 0.375 0.4 0.425 0.45 0.475 0.5"
gridSpacingTemplate='"[1;2;2;3;4;${gs}]"' # use ${gs} to decide where varGridSpacing goes
varGridSpacing="5"
innerReps="3"
smallSubjects="14133 14209 14382 P0175 P0180 P0054 12191"
hardSubjects="13888 10558 10557 10534 10529 10591 10578 10575 10567 10566 10564 10592 10604"
segmSubjects="10537 10534 10530 10529 10522 14209 P0870 12191 P0054 P0180"
nScales=`expr $# + 1`

###############################################################################
# Paths
###############################################################################

# prepare SGE variables necessary to move SGE environment away from AFS.
export SGE_LOG_PATH=/data/vision/polina/scratch/adalca/patchSynthesis/sge/
export SGE_O_PATH=${SGE_LOG_PATH}
export SGE_O_HOME=${SGE_LOG_PATH}

# MCR file. This has to match the MCC version used in mcc.sh
mcr=/data/vision/polina/shared_software/MCR/v82/

# project paths
INPUT_PATH="/data/vision/polina/projects/stroke/work/patchSynthesis/data/${datatype}/proc/${preptype}/";
ATLAS_PATH="/data/vision/polina/projects/stroke/work/patchSynthesis/data/${datatype}/atlases/${preptype}/";
ATLAS_FILE_SUFFIX="${datatype}61";
OUTPUT_PATH="/data/vision/polina/scratch/patchRegistration/output/";
PROJECT_PATH="/data/vision/polina/users/adalca/patchRegistration/git/"
CLUST_PATH="/data/vision/polina/users/adalca/patchRegistration/MCC/";
paramsinifile="${PROJECT_PATH}/configs/stroke/strokeParams.ini";
optsinifile="${PROJECT_PATH}/configs/stroke/strokeOpts.ini";

# command shell file
regMccSh="${CLUST_PATH}MCC_registerNii/run_registerNii.sh"
upMccSh="${CLUST_PATH}MCC_upsampleIntermediateWarp/run_upsampleIntermediateWarp.sh"
warpMccSh="${CLUST_PATH}MCC_mccReg2raw/run_mccReg2raw.sh"

# add lambda edge parameters to lambda edge file, from which we will read them one by one.
rm ${lambdaEdgeFile}
for i in ${lambdaEdgeOptions}
do
  echo "${lambda_edge}${i}]" >> ${lambdaEdgeFile}  
done

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
        regcmd="${regMccSh} $mcr ${pathsinifile} ${paramsinifile} ${optsinifile} $par1 $par2 $par3 $par4 $par5 $par6"
        
        # prepare command for upsampling warp
        statFile="${outfolder}/${nScales}_${ni}.mat"
        subjFile="${INPUT_PATH}${subjid}/${subjid}_ds${dsRate}_us${dsRate}_reg.nii.gz"
        atlSegFile="${ATLAS_PATH}/${ATLAS_FILE_SUFFIX}_seg_proc_ds${dsRate}_us${dsRate}.nii.gz"
        atlSeg2SubjRegNii="${runfolder}/final/${ATLAS_FILE_SUFFIX}-seg-in-${subjid}_via_${subjid}-2-${ATLAS_FILE_SUFFIX}-warp_via-scale${nScales}.nii.gz"
        upcmd="${upMccSh} $mcr $statFile $subjFile $atlSegFile $atlSeg2SubjRegNii"
        
        # prepare sge warp
        sourceDsXFile="${INPUT_PATH}${subjid}/${subjid}_proc_ds${dsRate}.nii.gz"
        sourceDsXUsXMaskFile="${INPUT_PATH}${subjid}/${subjid}_ds${dsRate}_us${dsRate}_dsmask.nii.gz"
        atlSeg2SubjRegMat="${INPUT_PATH}${subjid}/${subjid}_ds${dsRate}_us${dsRate}_reg.mat"
        saveSourceRawSegNii="${runfolder}/final/${ATLAS_FILE_SUFFIX}-seg-in-${subjid}-raw_via_${subjid}-2-${ATLAS_FILE_SUFFIX}-warp_via-scale${nScales}.nii.gz"
        rawcmd="${warpMccSh} $mcr $sourceDsXFile $sourceDsXUsXMaskFile $atlSeg2SubjRegNii $atlSeg2SubjRegMat $saveSourceRawSegNii"
        
        # output commands to file
        sgecmdfile="${sgeopath}/register-allcmd.sh"
        printf "${regcmd} \n\n ${upcmd} \n\n ${rawcmd}" > ${sgecmdfile}        
        chmod a+x $sgecmdfile

        # create sge file
        sge_par_o="--sge \"-o ${sgeopath}\""
        sge_par_e="--sge \"-e ${sgeopath}\""
        sge_par_l="--sge \"-l mem_free=100G \""
        sge_par_q="" #--sge \"-q qOnePerHost \""
        cmd="${PROJECT_PATH}sge/qsub-run -c $sge_par_q $sge_par_o $sge_par_e $sge_par_l /bin/sh ${sgecmdfile} > ${sgerunfile}"
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
  done < lambdaEdgeFile.txt
  
  cnt=`expr $cnt + 1`
  if [ "$cnt" -eq "100" ] ; then
    exit 0;
  fi
  
done
