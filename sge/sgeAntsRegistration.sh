#!/bin/bash
# run ANTs registration (raw input data)
#
# run:
# ./sgeAntsRegistration dataType proctype <dsRate>
# e.g.:
# ./sgeAntsRegistration stroke wholevol

###############################################################################
# Settings
###############################################################################

if [ "$#" -lt 2 ] ; then
  echo "Usage: $0 datatype proctype <dsRate>" >&2
  exit 1
fi
datatype="$1"
proctype="$2"
if [ "$#" -lt 3 ] ; then dsRate="7"; else dsRate="$3"; fi

# prepare SGE variables necessary to move SGE environment away from AFS.
export SGE_LOG_PATH=/data/vision/polina/scratch/adalca/patchSynthesis/sge/
export SGE_O_PATH=${SGE_LOG_PATH}
export SGE_O_HOME=${SGE_LOG_PATH}

PROJECT_PATH="/data/vision/polina/users/adalca/patchRegistration/git/"
CLUST_PATH="/data/vision/polina/users/adalca/patchRegistration/MCC/";
indir="/data/vision/polina/projects/stroke/work/patchSynthesis/data/${datatype}/proc/${proctype}/";
atlas="/data/vision/polina/projects/stroke/work/patchSynthesis/data/${datatype}/atlases/${proctype}/${datatype}61_brain_proc.nii.gz"
atlasSeg="/data/vision/polina/projects/stroke/work/patchSynthesis/data/${datatype}/atlases/${proctype}/${datatype}61_seg_proc.nii.gz"
atlasMask="/data/vision/polina/projects/stroke/work/patchSynthesis/data/${datatype}/atlases/${proctype}/${datatype}61_mask_proc.nii.gz"
outdir="/data/vision/polina/scratch/patchRegistration/output/${datatype}/ANTs_v103_brainpad10_ds7us7reg_noaffine_multiparam/"
mkdir -p $outdir

# setup
ants="/data/vision/polina/shared_software/ANTS/build/bin/ANTS"
warp="/data/vision/polina/shared_software/ANTS/build/bin/WarpImageMultiTransform"
mcr=/data/vision/polina/shared_software/MCR/v82/
mccSh="${CLUST_PATH}MCC_mccReg2raw/run_mccReg2raw.sh"

# parameters
ccparams="1,5"
nAffineIters="1000x1000x1000x1000"
nAffineIters="0"
nIters="201x201x201"
# reParams="9.000,0.200"
regParams1="9.000 8.000 3.000"
regParams2="0.200 0.100 0.100"
regParams1="3.000 9.000"
regParams2="0.000 0.200"
regParamsBoth="3.00,0.00 9.00,0.20"

###############################################################################
# Running Code
###############################################################################
# for i in `ls $indir`
# bad: P0054 14382 13888 13916 14133 14209 12191 12469 P0175 P0180
# ok: P0060 P0180 14157 13853 13909
cnt=0
for i in P0060 P0180 14157 13853 13909
do
  for regParams in $regParamsBoth
  do
    # regParams="${rp1},${rp2}"
    regParamsName=${regParams/,/_}

  	# input files
  	subjname=$i
  	rawinfile="${indir}/${subjname}/${subjname}_proc_ds${dsRate}.nii.gz"
  	reginfile="${indir}/${subjname}/${subjname}_ds${dsRate}_us${dsRate}_reg.nii.gz"
  	sourceDsXUsXMaskFile="${indir}/${subjname}/${subjname}_ds${dsRate}_us${dsRate}_dsmask.nii.gz"
  	atlSeg2SubjRegMat="${indir}/${subjname}/${subjname}_ds${dsRate}_us${dsRate}_reg.mat"

  	# output files and folders
  	subjpath="${outdir}/${subjname}_${regParamsName}/" # subject output path
    mkdir -p ${subjpath}
    mkdir -p "${subjpath}final/"
  	coreName="${subjname}-2-${datatype}61" # base of name for ants output
  	outfilecore="${subjpath}/final/${subjname}-2-${datatype}61-"
    outfileSeg="${subjpath}/final/${datatype}61-seg-in-${subjname}_via_${coreName}-invWarp.nii.gz"
  	outfileSegRaw="${subjpath}/final/${datatype}61-seg-in-${subjname}-raw_via_${coreName}-invWarp.nii.gz"

    #  setup commands
  	antscmd="$ants 3 -m CC[${reginfile},${atlas},${ccparams}] \
  		-t Syn[0.25] -o ${outfilecore} --number-of-affine-iterations ${nAffineIters} -i ${nIters} -r Gauss[${regParams}]"
    warpcmd="$warp 3 $atlasSeg $outfileSeg -R ${reginfile} ${outfilecore}Warp.nii.gz ${outfilecore}Affine.txt --use-NN"
    lcmd="${mccSh} $mcr $rawinfile $sourceDsXUsXMaskFile $outfileSeg $atlSeg2SubjRegMat $outfileSegRaw"

    #  v2
    # antscmd="$ants 3 -m CC[${rawinfile},${atlas},${ccparams}] \
    #   -t Syn[0.25] -o ${outfilecore} --number-of-affine-iterations ${nAffineIters} -i ${nIters} -r Gauss[${regParams}]"
    # warpcmd="$warp 3 $atlasSeg $outfileSegRaw -R ${rawinfile}  ${outfilecore}Warp.nii.gz ${outfilecore}Affine.txt --use-NN"
    # lcmd=""

    # antscmd="$ants 3 -m CC[${atlas},${rawinfile},${ccparams}] \
    #   -t Syn[0.25] -o ${outfilecore} --number-of-affine-iterations ${nAffineIters} -i ${nIters} -r Gauss[${regParams}] -x $atlasMask "
    # warpcmd="$warp 3 $atlasSeg $outfileSeg -R ${rawinfile} -i ${outfilecore}Affine.txt ${outfilecore}InverseWarp.nii.gz --use-NN"
    # lcmd=""

  	# prepare SGE
  	sgesubjpath="${subjpath}sge/"
  	mkdir -p ${sgesubjpath}
  	sgerunfile="${sgesubjpath}ants-${coreName}-warp.sh"
  	cmdsfile="${sgesubjpath}ants-${coreName}-warp-cmds.sh"
    #
  	printf "${antscmd} ;  \n\n ${warpcmd} ; \n\n${lcmd} \n " > ${cmdsfile}
  	chmod a+x ${cmdsfile}

  	# create sge file
  	sge_par_o="--sge \"-o ${sgesubjpath}\""
  	sge_par_e="--sge \"-e ${sgesubjpath}\""
    sge_par_l="--sge \"-l mem_free=100G \""
  	cmd="${PROJECT_PATH}sge/qsub-run -c $sge_par_o $sge_par_e $sge_par_l ${cmdsfile} > ${sgerunfile}"
  	# echo $cmd
  	eval $cmd

  	# run sge
    chmod a+x ${sgerunfile} # for us to be able to run manually
  	sgecmd="qsub ${sgerunfile}"
  	echo -e "$sgecmd\n"
  	$sgecmd

  	# sleep for a bit to give sge time to deal with the new job (?)
  	# sleep 1
  done
  # sleep 1
  cnt=`expr $cnt + 1`
  if [ "$cnt" -eq "100" ] ; then
    exit 0;
  fi
done
