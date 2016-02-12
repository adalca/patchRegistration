#!/bin/bash
# run ANTs registration

###############################################################################
# Settings
###############################################################################

# prepare SGE variables necessary to move SGE environment away from AFS.
export SGE_LOG_PATH=/data/vision/polina/scratch/adalca/patchSynthesis/sge/
export SGE_O_PATH=${SGE_LOG_PATH}
export SGE_O_HOME=${SGE_LOG_PATH}

PROJECT_PATH="/data/vision/polina/users/adalca/patchRegistration/git/"
indir="/data/vision/polina/scratch/adalca/patchSynthesis/data/buckner/proc/"
atlas="/data/vision/polina/scratch/adalca/patchSynthesis/data/buckner/atlases/buckner61_brain_proc.nii.gz"
atlasSeg="/data/vision/polina/scratch/adalca/patchSynthesis/data/buckner/atlases/buckner61_seg_proc.nii.gz"
outdir="/data/vision/polina/scratch/adalca/patchSynthesis/data/buckner/ants/"
mkdir -p $outdir

ants="/data/vision/polina/shared_software/ANTS/build/bin/ANTS"
warp="/data/vision/polina/shared_software/ANTS/build/bin/WarpImageMultiTransform"

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
	infile="${indir}/${subjname}/${subjname}_brain_downsampled7_reinterpolated7.nii.gz"

	# output files and folders
	coreName="Ds7Us7-to-atlas_"
	subjpath="${outdir}/${subjname}/"
	sgesubjpath="${subjpath}/sge/"
	sgerunfile="${sgesubjpath}/${coreName}"
	mkdir -p $sgesubjpath
	outfilecore="${subjpath}/${subjname}_${coreName}"
	outfileSeg="${outfilecore}_atlasSeg-to-Ds7Us7.nii.gz"

	antscmd="$ants 3 -m CC[${infile},${atlas},${ccparams}]
		-t Syn[0.25] -o $outfilecore --number-of-affine-iterations ${nAffineIters} -i ${nIters} -r Gauss[${regParams}]"
  warmcmd="$warp 3 $atlasSeg $outfileSeg -R ${infile} -i ${outfilecore}Affine.txt ${outfilecore}InverseWarp.nii.gz -useNN"
	combcmd="${antscmd};${warmcmd}"

	# create sge file
	sge_par_o="--sge \"-o ${sgesubjpath}\""
	sge_par_e="--sge \"-e ${sgesubjpath}\""
	cmd="${PROJECT_PATH}sge/qsub-run -c $sge_par_o $sge_par_e ${antscmd} > ${sgerunfile}"
	echo $cmd
	eval $cmd

	# run sge
	sgecmd="qsub ${sgerunfile}"
	echo -e "$sgecmd\n"
	$sgecmd

	# sleep for a bit to give sge time to deal with the new job (?)
	sleep 1
done
