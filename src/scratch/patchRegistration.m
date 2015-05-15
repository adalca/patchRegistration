%% preamble
% TODOS: use atlsa via BUCKNER_ATLAS_PATH

% parameters
patchSize = [5, 5, 5];
resize = 64 * ones(1,3);
smallvolCrop = {15:35,15:35,15:35};

%% load data
% filenames. TODO: use medialDataset
file1 = fullfile(BUCKNER_PATH, 'buckner01', 'buckner01_brain_affinereg_to_b61.nii.gz');
mask1 = fullfile(BUCKNER_PATH, 'buckner01', 'buckner01_brain_affinereg_to_b61_seg.nii.gz');
file2 = fullfile(BUCKNER_PATH, 'buckner03', 'buckner03_brain_affinereg_to_b61.nii.gz');
mask2 = fullfile(BUCKNER_PATH, 'buckner03', 'buckner03_brain_affinereg_to_b61_seg.nii.gz');

% extract bounding box for brain volumes
nii1seg = loadNii(mask1);
nii2seg = loadNii(mask2);
[~, ~, range] = boundingBox(nii1seg.img > 0 | nii2seg.img > 0);

% extract prepared volumes.
vol1 = sim.loadNii(file1, 'mask', mask1, 'crop', range, 'uint82double', true, 'resize', resize);
vol2 = sim.loadNii(file2, 'mask', mask2, 'crop', range, 'uint82double', true, 'resize', resize);
v1sel = vol1(smallvolCrop{:});
v2sel = vol2(smallvolCrop{:});

% visualize extracted volumes.
view3Dopt(vol1, vol2);
view3Dopt(v1sel, v2sel);

%% visualize displacement in quick patch search for sub-volumes
% TODO - maybe move this to an example in patchlib. and reference here as a good thing to look up.
% do a quick local patch search and get the nearest neighbor
[~, ~, pIdx, ~, srcgridsize, refgridsize] = ...
    patchlib.volknnsearch(v1sel, v2sel, patchSize, 'sliding', 'K', 1, 'local', 10);

% visualize the location in 3D
srcgrididx = patchlib.grid(size(v1sel), patchSize, 'sliding');
disp = patchlib.corresp2disp(size(v1sel), refgridsize, pIdx, 'srcGridIdx', srcgrididx, 'reshape', true);
view3Dopt(v1sel, disp{:});

%% 3D registration with MRF overlap

% initialize
newsize = 30; % TODO: warning: croppedVol1/2 can be different size so this resizing is tricky
warning('do ATL');
v1sel = volblur(volresize(double(croppedVol1)/255, [1, 1, 1]*newsize), 1);
v1selseg = volresize(double(croppedVol1seg)/255, [1, 1, 1]*newsize, 'nearest');
v2sel = volblur(volresize(double(croppedVol2)/255, [1, 1, 1]*newsize), 1);
v2selseg = volresize(double(croppedVol2seg)/255, [1, 1, 1]*newsize, 'nearest');
ref = v2sel;
patchSize = [5, 5, 5];
patchOverlap = 'half';

% patch search
tic;
[patches, pDst, pIdx, pRefIdxs, srcgridsize, refgridsize] = patchlib.volknnsearch(v1sel, ...
    ref, patchSize, patchOverlap, 'K', 20, 'location', 0.01, 'local', 5); %'mask', mask, %'NSmethod', 'kdtree'
toc;

% MRF on overlap
tic;
usemex = exist('pdist2mex', 'file') == 3;
edgefn = @(a1,a2,a3,a4) patchlib.correspdst(a1, a2, a3, a4, [], usemex); 
edgefn = @(a1,a2,a3,a4) discretecorrespdst(a1, a2, a3, a4, [], usemex); 
[qp, ~, ~, ~, pi] = ...
    patchlib.patchmrf(patches, srcgridsize, pDst, patchSize, patchOverlap , 'edgeDst', edgefn, ...
    'lambda_node', 0.1, 'lambda_edge', 100, 'pIdx', pIdx, 'refgridsize', refgridsize);
resimg3 = patchlib.quilt(qp, srcgridsize, patchSize, patchOverlap); 
idx = patchlib.grid(size(v1sel), patchSize, patchOverlap);
disp = patchlib.corresp2disp(size(v1sel), refgridsize, pi, 'srcGridIdx', idx, 'reshape', true);
view3Dopt(v1sel, resimg3, v2sel, disp{:})
toc;

% interpolate displacement
idxsub = patchlib.grid(size(v1sel), patchSize, patchOverlap, 'sub');
assert(all(size(idxsub{1}) == srcgridsize));
[xi, yi, zi] = ndgrid(1:size(v1sel, 1), 1:size(v1sel, 2), 1:size(v1sel, 3));
disp2 = {};
for i = 1:numel(disp)
    disp2{i} = interpn(idxsub{:}, disp{i}, xi, yi, zi);
end
view3Dopt(v1sel, resimg3, v2sel, disp2{:})

% translate im2sel via new disp (maybe)
v2selmoved = iminterpolate(v2sel, disp2{2}, disp2{1}, disp2{3});
v2selsegmoved = iminterpolate(v2selseg, disp2{2}, disp2{1}, disp2{3}, 'nearest');
v2selsegmoved(isnan(v2selsegmoved)) = 0;

view3Dopt(v1sel, v2selmoved, v2sel, v1selseg, v2selsegmoved, v2selseg)

% compute dice of v1selseg and: v2selsegmoved and v2selseg.
d1 = dice(v1selseg, v2selseg, 'all');
d2 = dice(v1selseg, v2selsegmoved, 'all');
figure(); boxplot(d2' - d1');

% TODO: upsample warp all the way to the original, and move segments at that level
warpNew = warpresize(disp2, size(croppedVol1seg));
v2fullsegmoved = iminterpolate(croppedVol2seg, warpNew{2}, warpNew{1}, warpNew{3}, 'nearest');
v2fullmoved = iminterpolate(double(croppedVol2)/255, warpNew{2}, warpNew{1}, warpNew{3});
d1 = dice(croppedVol1seg, croppedVol2seg, 'all');
d2 = dice(croppedVol1seg, v2fullsegmoved, 'all');

view3Dopt(croppedVol1, v2fullmoved, croppedVol2, croppedVol1seg, v2fullsegmoved, croppedVol2seg)




% TODO: move to atlas?


% % patch quilt
% resimg = patchlib.quilt(patches(:,:,1), srcgridsize, patchSize, patchOverlap);  
% resimg2 = patchlib.quilt(patches, srcgridsize, patchSize, patchOverlap);  
% disp = patchlib.corresp2disp(srcgridsize, refgridsize, pIdx(:, 1), 'reshape', true);
% view3Dopt(v1sel, ref, resimg, disp{:});

% warp result? via DEMONS function? First need to interpolate warps? need MRF for that.


%% try using a mask?
% IDEA: use masks to determine which patches to look up. only look up patches with high gradients.
% setup a small window mask
x = size2ndgrid(size(v1sel));
xr = cellfun(@(x) abs(x - newsize/2) < 10, x, 'UniformOutput', false);
mask = xr{1} & xr{2} & xr{3};

% setup a gradient-based mask
g3 = volGradients(v1sel, [3, 3, 3], 1, [1, 1, 1], 'cell');
g5 = volGradients(v1sel, [5, 5, 5], 1, [1, 1, 1], 'cell');
g = sum(abs(cat(4, g3{:})), 4);
mask = g > 0.6;



%% 3d registration.
load vols;
src = vols(1).full(75:175, 75:175, 75:175);
ref = vols(2).full(75:175, 75:175, 75:175);
% src = volresize(vols(1).full(50:200, 50:200, 50:200), [50, 50, 50]);
% ref = volresize(vols(2).full(50:200, 50:200, 50:200), [50, 50, 50]);
patchSize = [5, 5, 5];
[patches, pDst, pIdx, pRefIdxs, srcgridsize, refgridsize] = ...
    patchlib.volknnsearch(src, ref, patchSize , 'mrf', 'K', 50, 'location', 0.01, 'local', 3); 

srcgrididx = patchlib.grid(size(src), patchSize, 'mrf');
resimg = patchlib.quilt(patches(:,:,1), srcgridsize, patchSize, 'mrf');  
disp = patchlib.corresp2disp(size(src), refgridsize, pIdx(:, 1), 'reshape', true, ...
    'srcGridIdx', srcgrididx);

edgefn = @(a1,a2,a3,a4) patchlib.correspdst(a1, a2, a3, a4, [], true);
edgefn = @discretecorrespdst;
[qp, ~, ~, pi] = ...
    patchlib.patchmrf(patches, srcgridsize, pDst, patchSize , 'edgeDst', edgefn, ...
    'lambda_node', 0.1, 'lambda_edge', 10, 'pIdx', pIdx, 'refgridsize', refgridsize, ...
    'gridIdx', srcgrididx, 'srcSize', size(src));
disp2 = patchlib.corresp2disp(size(src), refgridsize, pi, 'reshape', true, ...
    'srcGridIdx', srcgrididx);
resimg2 = patchlib.quilt(qp, srcgridsize, patchSize, 'mrf'); resimg(1, 1) = 0.7;

%%
% error('try slice registration and movign forward with demons move fwd code... or just... grab patches?')
% error('moving forward is easy, see demons code. It''s just an interpolation method?');


%% Other registration scripts
patchRegistration_cardiac; % cardiac
patchRegistrationCT; % CT
patchRegistration2D; % 2D
