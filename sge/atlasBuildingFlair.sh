#!/bin/sh

# prepare SGE variables necessary to move SGE environment away from AFS.
export SGE_LOG_PATH=/data/vision/polina/scratch/adalca/patchSynthesis/sge/
export SGE_O_PATH=${SGE_LOG_PATH}
export SGE_O_HOME=${SGE_LOG_PATH}

# MCR file. This has to match the MCC version used in mcc.sh
mcr=/data/vision/polina/shared_software/MCR/v82/

PROC_PATH="/data/vision/polina/projects/stroke/work/patchSynthesis/data/ADNI_FLAIR_firsts/proc/"
PROJECT_PATH="/data/vision/polina/users/adalca/patchRegistration/git/"

ants="/data/vision/polina/shared_software/ANTS/build/bin/ANTS"
warp="/data/vision/polina/shared_software/ANTS/build/bin/WarpImageMultiTransform"

ccparams="1,16"
nAffineIters="1000x1000x1000x1000x1000"
nIters="0"

processSegFlairAtlexe="/data/vision/polina/users/adalca/patchSynthesis/subspace/MCC/MCC_processSegFlairAtl/run_processSegFlairAtl.sh"
processFlairUsexe="/data/vision/polina/users/adalca/patchSynthesis/subspace/MCC/MCC_processFlairUs/run_processFlairUs.sh"
robexexe="/data/vision/polina/shared_software/ROBEX/runROBEX.sh"

for i in `cat /data/vision/polina/projects/stroke/work/patchSynthesis/data/ADNI_FLAIR_firsts/proc/wholevol_common_list.txt`
do
  name=$i
  T1file=${PROC_PATH}brain_pad10_T1s/${name}/${name}_iso_2_ds5_us5_size_reg.nii.gz
  T1segfile=${PROC_PATH}brain_pad10_T1s/${name}/${name}_ds5_us5_reg_seg.nii.gz
  T1maskfile=${PROC_PATH}brain_pad10_T1s/${name}/${name}_ds5_us5_reg_mask.nii.gz
  FLAIRfilegz=${PROC_PATH}wholevol/${name}/${name}.nii.gz
  FLAIRfile=${PROC_PATH}wholevol/${name}/${name}.nii
  FLAIRbrainfile=${PROC_PATH}wholevol/${name}/${name}_brain.nii
  FLAIRdsfile=${PROC_PATH}wholevol/${name}/${name}_ds.nii.gz
  FLAIRdsMaskfile=${PROC_PATH}wholevol/${name}/${name}_ds_dsmask.nii.gz
  mv $FLAIRfilegz $FLAIRfile
  outfile=${PROC_PATH}brain_pad10_T1s/${name}/${name}_flair_to__iso_2_ds5_us5_size_reg.nii.gz
  maskoutfile=${PROC_PATH}brain_pad10_T1s/${name}/${name}_flair_to__iso_2_ds5_us5_size_reg_dsmask.nii.gz
  outcore=${PROC_PATH}brain_pad10_T1s/${name}/${name}_flair_to__iso_2_ds5_us5_size_reg_ANTs

  processSegFlairAtlcmd="$processSegFlairAtlexe $mcr ${T1segfile} ${T1maskfile}"
  processFlairUs="$processFlairUsexe $mcr ${FLAIRfile} 550 ${FLAIRdsfile} ${FLAIRdsMaskfile}"
  robexcmd="${robexexe} ${FLAIRdsfile} ${FLAIRbrainfile}"

  antscmd="$ants 3 -m MI[${T1file},${FLAIRbrainfile},${ccparams}] --rigid-affine true -x ${T1maskfile}
	 -o $outcore --number-of-affine-iterations ${nAffineIters} -i ${nIters}"
  antscmd="$ants 3 -m MI[${T1file},${FLAIRbrainfile},${ccparams}] -o $outcore -i ${nIters}"

  warmcmd="$warp 3 $FLAIRdsfile $outfile -R ${T1file} ${outcore}Affine.txt"
  warmcmdmask="$warp 3 $FLAIRdsMaskfile $maskoutfile -R ${T1file} ${outcore}Affine.txt"

  sgesubjpath="${PROC_PATH}/sge/"
  mkdir -p ${sgesubjpath}
  sgerunfile="${sgesubjpath}reg_${name}_FLAIR_to_T1.sh"

  # create sge file
	sge_par_o="--sge \"-o ${sgesubjpath}\""
	sge_par_e="--sge \"-e ${sgesubjpath}\""
	cmd="${PROJECT_PATH}sge/qsub-run -c $sge_par_o $sge_par_e ${warmcmdmask} > ${sgerunfile}"
  chmod a+x ${sgerunfile}
	echo $cmd
	eval $cmd

	# run sge
	sgecmd="qsub ${sgerunfile}"
	echo -e "$sgecmd\n"
	$sgecmd

  # echo $cmd

  # sleep 30
  # $antscmd
  # echo $warmcmd
  # $warmcmd

  # echo $i
  # sleep 1000

done
