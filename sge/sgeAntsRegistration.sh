#!/bin/bash
# run ANTs registration (raw input data)

###############################################################################
# Settings
###############################################################################

if [ "$#" -lt 1 ] ; then
  echo "Usage: $0 datatype " >&2
  exit 1
fi

datatype="$1"

# prepare SGE variables necessary to move SGE environment away from AFS.
export SGE_LOG_PATH=/data/vision/polina/scratch/adalca/patchSynthesis/sge/
export SGE_O_PATH=${SGE_LOG_PATH}
export SGE_O_HOME=${SGE_LOG_PATH}

PROJECT_PATH="/data/vision/polina/users/adalca/patchRegistration/git/"
CLUST_PATH="/data/vision/polina/users/adalca/patchRegistration/MCC/";
indir="/data/vision/polina/projects/stroke/work/patchSynthesis/data/${datatype}/proc/brain_pad10/";
atlas="/data/vision/polina/projects/stroke/work/patchSynthesis/data/${datatype}/atlases/brain_pad10/${datatype}61_brain_proc.nii.gz"
atlasSeg="/data/vision/polina/projects/stroke/work/patchSynthesis/data/${datatype}/atlases/brain_pad10/${datatype}61_seg_proc.nii.gz"
outdir="/data/vision/polina/scratch/patchRegistration/output/${datatype}/ANTs_raw_v1/"
mkdir -p $outdir

# setup
ants="/data/vision/polina/shared_software/ANTS/build/bin/ANTS"
warp="/data/vision/polina/shared_software/ANTS/build/bin/WarpImageMultiTransform"
mcr=/data/vision/polina/shared_software/MCR/v82/
mccSh="${CLUST_PATH}MCC_mccReg2raw/run_mccReg2raw.sh"

# parameters
ccparams="1,4"
nAffineIters="1000x1000x1000x1000x1000"
nIters="201x201x201"
regParams="9.000,0.200"

###############################################################################
# Running Code
###############################################################################

for i in $indir/*
do
	# input files
	subjname=`basename $i`
	rawinfile="${indir}/${subjname}/${subjname}_proc_ds7.nii.gz"
	reginfile="${indir}/${subjname}/${subjname}_ds7_us7_reg.nii.gz"
	sourceDsXUsXMaskFile="${indir}/${subjname}/${subjname}_ds7_us7_dsmask.nii.gz"
	atlSeg2SubjRegMat="${indir}/${subjname}/${subjname}_ds7_us7_reg.mat"

	# output files and folders
	subjpath="${outdir}/${subjname}/" # subject output path
  mkdir -d ${subjpath}
  mkdir -d "${subjpath}final/"
	coreName="${subjname}-2-${datatype}61" # base of name for ants output
	outfilecore="${subjpath}/final/${subjname}-2-${coreName}-"
	outfileSeg="${subjpath}/final/${coreName}61-seg-in-${subjname}-raw_via_${coreName}-invWarp.nii.gz"

	antscmd="$ants 3 -m CC[${reginfile},${atlas},${ccparams}] \
		-t Syn[0.25] -o ${outfilecore} --number-of-affine-iterations ${nAffineIters} -i ${nIters} -r Gauss[${regParams}]"
  warmcmd="$warp 3 $atlasSeg $outfileSeg -R ${reginfile} -i ${outfilecore}Affine.txt ${outfilecore}InverseWarp.nii.gz --use-NN"

	# prepare SGE
	sgesubjpath="${subjpath}sge/"
	mkdir -p ${sgesubjpath}
	sgerunfile="${sgesubjpath}ants-${coreName}-warp.sh"
	cmdsfile="${sgesubjpath}ants-${coreName}-warp-cmds.sh"
	lcmd="${mccSh} $mcr $rawinfile $sourceDsXUsXMaskFile $outfileSeg $atlSeg2SubjRegMat $outfileSeg"
	printf "${antscmd} ; \n${warmcmd} ; \n ${lcmd} \n " > ${cmdsfile}
	chmod a+x ${cmdsfile}

	# create sge file
	sge_par_o="--sge \"-o ${sgesubjpath}\""
	sge_par_e="--sge \"-e ${sgesubjpath}\""
  sge_par_l="--sge \"-l mem_free=100G \""
	cmd="${PROJECT_PATH}sge/qsub-run -c $sge_par_o $sge_par_e $sge_par_l ${cmdsfile} > ${sgerunfile}"
	echo $cmd
	eval $cmd

	# run sge
	sgecmd="qsub ${sgerunfile}"
	echo -e "$sgecmd\n"
	$sgecmd

	# sleep for a bit to give sge time to deal with the new job (?)
	# sleep 10
done
