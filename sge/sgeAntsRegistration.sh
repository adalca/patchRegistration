
# TODO: need to set this up in SGE.

indir="/data/vision/polina/scratch/adalca/patchSynthesis/data/buckner/proc/"
atlas="/data/vision/polina/scratch/adalca/patchSynthesis/data/buckner/atlases/buckner61_brain_proc.nii.gz"
outdir="/data/vision/polina/scratch/adalca/patchSynthesis/data/buckner/ants/"

# /data/vision/polina/shared_software/ANTS/build/bin/ANTS 3 -m CC[/data/vision/polina/scratch/adalca/patchSynthesis/data/buckner/proc/buckner35/buckner35_brain_downsampled7_reinterpolated7_reg.nii.gz,/data/vision/polina/scratch/adalca/patchSynthesis/data/buckner/atlases/buckner61_brain_proc.nii.gz,1,4] -t Syn[0.25] -o /data/vision/polina/scratch/adalca/patchSynthesis/data/buckner/tmp/buckner35-antsrun --number-of-affine-iterations 0 -i 201x201x201 -r Gauss[9.000,0.200] 

# /data/vision/polina/shared_software/ANTS/build/bin/WarpImageMultiTransform 3 /data/vision/polina/scratch/adalca/patchSynthesis/data/buckner/atlases/buckner61_seg_proc.nii.gz /data/vision/polina/scratch/adalca/patchSynthesis/data/buckner/tmp/buckner35-antsrun-atl2b35_seg.nii.gz  -R /data/vision/polina/scratch/adalca/patchSynthesis/data/buckner/proc/buckner35/buckner35_brain_downsampled7_reinterpolated7_reg.nii.gz -i /data/vision/polina/scratch/adalca/patchSynthesis/data/buckner/tmp/buckner35-antsrunAffine.txt /data/vision/polina/scratch/adalca/patchSynthesis/data/buckner/tmp/buckner35-antsrunInverseWarp.nii.gz  -useNN



for i in $indir/*
do
	bname=`basename $i`

	infile="$indir"
	
	
	
done