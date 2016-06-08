#!/bin/bash
# run stroke registration

###############################################################################
# General options
###############################################################################

preptype="brain_pad10"
datatype="stroke"
dsRate="7"
lambdaEdgeFile="lambdaEdgeFile.txt"
runver="PBR_v607_brainpad_scale4"; # this version's running version

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

lambdaEdgeOptions="0.01 0.025 0.05 0.075 0.1 0.125 0.15 0.175 0.2 0.225 0.25 0.275 0.3 0.325 0.35 0.375 0.4 0.425 0.45 0.475 0.5"
gridSpacingTemplate='"[1;2;2;3;4;${gs}]"' # use ${gs} to decide where varGridSpacing goes
varGridSpacing="5"
innerReps="3"
smallSubjects="14133 14209 14382 P0175 P0180 P0054 12191"
hardSubjects="13888 10558 10557 10534 10529 10591 10578 10575 10567 10566 10564 10592 10604"
segmSubjects="10537 10534 10530 10529 13888 14133 14209 14382 P0175 P0870 12191 P0054 P0180"
awfulSubjects="10553 10575 10588 10605 10696 10702 10704 10827 10830 10842 10935 10958 10990 10991 11063 11065 11105 11152 11218 11369 11394 11437 11470 11482 11560 11568 11571 11630 11666 11697 11698 11796 11824 11858 11973 11999 12018 12041 12057 12138 12142 12191 12206 12227 12354 12466 12472 12519 12567 12579 12586 12601 12633 12679 12681 12717 12760 12797 12896 13524 13603 13619 13750 13768 13860 13909 13916 13938 14052 14131 14157 14164 14197 14209 14217 14270 14382 14400 14538 14684 14766 14851 14863 15113 15119 15145 30002 30004c 30018 30019 30020 30025 30033 30150 30151 30235 30264 P0054 P0080 P0132 P0142 P0149 P0152 P0157 P0180 P0186 P0212 P0250 P0282 P0293 P0310 P0312 P0334 P0346 P0351 P0353 P0371 P0373 P0376 P0410 P0417 P0444 P0448 P0456 P0478 P0489 P0540 P0618 P0626 P0628 P0631 P0633 P0688 P0693 P0710 P0735 P0768 P0794 P0795 P0831 P0834 P0846 P0867"
improvableSubjects="10534 10558 10630 10592 10596 10604 10610 10613 10647 10661 10662 10692 10703 10770 10779 10803 10807 10809 10954 11154 11168 11288 11418 11439 11487 11615 11635 11638 11734 11746 11748 11768 11883 12022 12059 12060 12085 12137 12239 12284 12294 12299 12302 12309 12365 12493 12520 12536 12547 12548 12596 12597 12604 12618 12620 12674 12684 12689 12695 12720 12733 12758 12909 13029 13123 13237 13370 13617 13671 13704 13715 13717 13737 13748 13770 13835 13888 13918 14056 14072 14079 14104 14234 14252 14492 14511 14568 14627 14628 14630 14690 14703 14747 15150 30009 30023 30149 30198 30237 30243 30246 30248 30267 P0014 P0084 P0128 P0154 P0161 P0164 P0168 P0175 P0181 P0188 P0191 P0197 P0200 P0266 P0279 P0281 P0292 P0296 P0299 P0307 P0354 P0356 P0366 P0374 P0393 P0415 P0416 P0479 P0509 P0511 P0547 P0556 P0561 P0568 P0639 P0640 P0642 P0667 P0687 P0695 P0703 P0711 P0717 P0736 P0742 P0744 P0750 P0766 P0774 P0782 P0785 P0792 P0796 P0804 P0808 P0820 P0828 P0838 P0839 P0842 P0848 P0854 P0856 P0861"

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
        lineWithUnderscores=${line//,/-}
        runfolder="${veroutpath}/${subjid}_${lineWithUnderscores}_${gs}_${ni}/"
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
