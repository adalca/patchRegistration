%% CT
nii1 = loadNii('D:\research\data\patient0-T0-CT_cropped.nii.gz');
v1slice = (volresize(double(nii1.img(:,:,99)), [48, 28]*1)+3024)/3071;
nii2 = loadNii('D:\research\data\patient0-T50-CT_cropped.nii.gz');
v2slice = (volresize(double(nii2.img(:,:,104)), [48, 28]*1)+3024)/3071;
refslice = v2slice;
[patches, pDst, pIdx, pRefIdxs, srcgridsize, refgridsize] = patchlib.volknnsearch(v1slice, ...
    refslice, patchSize , 'K', 10, 'local', 20, 'location', 0.01);
