ANTsOutPath = '/data/vision/polina/scratch/patchRegistration/output/stroke/ANTs_v526_brainpad10_ds7us7reg_noaffine_multiparam_backward/';
[paramsANTs, subjNamesANTs, foldersANTs] = gatherRunParams(ANTsOutPath);
subjectName='10534';
ANTsID = find(strncmp(foldersANTs, subjectName, numel(subjectName)));
ANTsID = ANTsID(1);
segANTsnii = loadNii(fullfile(ANTsOutPath, foldersANTs{ANTsID}, '/final/', sprintf('/stroke61-seg-in-%s_via_stroke61-2-%s-warp.nii.gz', subjectName, subjectName)));
inoutDesiredLabels = [4, 43];
segANTs = ismember(segANTsnii.img, inoutDesiredLabels);
scVol=source{1};

scSegANTs = volresize(segANTs, size(source{1}), 'nearest');
scCentroid = centroid3D(scSegANTs);

strokeAtlasPath = '/data/vision/polina/projects/stroke/work/patchSynthesis/data/stroke/atlases/brain_pad10/';
scSegPBRnii = loadNii(fullfile(strokeAtlasPath, '/stroke61_seg_proc_ds7_us2.nii.gz'));
scSegPBR = scSegPBRnii.img;

warpDir='backward';
warpedSeg = volwarp(scSegPBR, cdispl, warpDir, 'interpMethod', 'nearest');
outlineLabels = [4, 43, 3, 42];
warpedSegReduced = ismember(warpedSeg, outlineLabels);
assert(isequal(size(scVol),size(warpedSeg)));
[rgbImages, ~] = showVolStructures2D(scVol(:, :, scCentroid), warpedSegReduced(:, :, scCentroid), {'axial'}, 3, 1, 1, [], 'nearest');
imagesc(rgbImages)