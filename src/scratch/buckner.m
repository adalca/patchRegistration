volsize = 128 * [1, 1, 1];

%% load
nii2vr = loadNii('D:\Research\patchSynthesis\data\buckner\buckner02\buckner02_brain_downsampled_interpolated_reg.nii.gz');
vol2 = padarray(volresize(double(nii2vr.img)/255, volsize), patchSize, 'both');
nii2mr = loadNii('D:\Research\patchSynthesis\data\buckner\buckner02\buckner02_brain_downsampled_dsmask_reg.nii.gz');
mask2 = padarray(volresize(double(nii2mr.img), volsize), patchSize, 'both');

nii3vr = loadNii('D:\Research\patchSynthesis\data\buckner\buckner03\buckner03_brain_downsampled_interpolated_reg.nii.gz');
vol3 = padarray(volresize(double(nii3vr.img)/255, volsize), patchSize, 'both');
nii3mr = loadNii('D:\Research\patchSynthesis\data\buckner\buckner03\buckner03_brain_downsampled_dsmask_reg.nii.gz');
mask3 = padarray(volresize(double(nii3mr.img), volsize), patchSize, 'both');

%%

patchSize = [3, 3, 3, 2];
patchOverlap = [1, 1, 1, 0];
nScales = 12;
nInnerReps = 1;

source = cat(4, vol2, mask2);
target = cat(4, vol3, mask3);

[nii2moved, displ] = patchreg.multiscale(source, target, ...
    patchSize, patchOverlap, nScales, nInnerReps, 'searchargs', {'searchfn', @wtdstl1});



%% TODO - try actual registration of original images
patchSize = [3, 3, 3];
patchOverlap = [1, 1, 1]*2;
nScales = 4;
nInnerReps = 1;

[nii2moved, displ] = patchreg.multiscale(vol2, vol3, patchSize, patchOverlap, nScales, nInnerReps, 'searchargs', {'location', 0.01});

a = load('dbdispl262');
displ = a.dbdispl;

% use displ to do quilting. can compare to original.
libidx = disp2corresp(displ, patchSize, size(vol3));
[~, ~, gridsize] = patchlib.grid(size(vol3), patchSize);
libidx = cropVolume(libidx, ones(1, ndims(vol2)), gridsize);
nanmap = isnan(libidx);
libidx(nanmap) = 1;

% rebuild original for sanity(ish)
lib = patchlib.vol2lib(vol3, patchSize);
patches = patchlib.lib2patches(lib, libidx(:));
patches(nanmap, :) = inf;
q = patchlib.quilt(patches, gridsize);
view3Dopt(vol2, q);

% rebuild parts
lib = patchlib.vol2lib(vol3 .* mask3, patchSize);
patches = patchlib.lib2patches(lib, libidx(:));
patches(nanmap, :) = 0;
masklib = patchlib.vol2lib(mask3, patchSize);
maskpatches = patchlib.lib2patches(masklib, libidx(:));
maskpatches(nanmap, :) = 0;
q2 = patchlib.quilt(patches, gridsize, 'weights', maskpatches);
m2 = patchlib.quilt(maskpatches, gridsize);
view3Dopt(vol2, vol2.*mask2, vol2.*mask2 + q2.*(1-mask2));
% TODO: NEED SCORE OF PATCH MATCHING, etc! Can even match now after the fact via 'patches'
% TODO: vote aggreement, etc.

%%

