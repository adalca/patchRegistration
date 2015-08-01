%% preamble
% TODOS: use atlsa via BUCKNER_ATLAS_PATH
warning('work with ATLAS');

% parameters
patchSize = [3, 3, 3];
resize = 32 * ones(1,3);
smallvolCrop = {1:32, 1:32, 1:32};

%% load data
% filenames. TODO: use medialDataset
file1 = fullfile(BUCKNER_PATH, 'buckner02', 'buckner02_brain_affinereg_to_b61.nii.gz');
mask1 = fullfile(BUCKNER_PATH, 'buckner02', 'buckner02_brain_affinereg_to_b61_seg.nii.gz');
file2 = fullfile(BUCKNER_PATH, 'buckner03', 'buckner03_brain_affinereg_to_b61.nii.gz');
mask2 = fullfile(BUCKNER_PATH, 'buckner03', 'buckner03_brain_affinereg_to_b61_seg.nii.gz');

% extract bounding box for brain volumes
nii1seg = loadNii(mask1);
nii2seg = loadNii(mask2);
[~, ~, range] = boundingBox(nii1seg.img > 0 | nii2seg.img > 0);

% extract prepared volumes.
vol1 = sim.loadNii(file1, 'mask', mask1, 'crop', range, 'uint82double', true, 'resize', resize);
vol1seg = sim.loadNii(mask1, 'mask', mask1, 'crop', range, 'resize', resize, 'resizeInterpMethod', 'nearest');
vol2 = sim.loadNii(file2, 'mask', mask2, 'crop', range, 'uint82double', true, 'resize', resize);
vol2seg = sim.loadNii(mask2, 'mask', mask2, 'crop', range, 'resize', resize, 'resizeInterpMethod', 'nearest');

% extract even smaller volumes
v1sel = vol1(smallvolCrop{:});
v2sel = vol2(smallvolCrop{:});
v1selseg = vol1seg(smallvolCrop{:});
v2selseg = vol2seg(smallvolCrop{:});

% visualize extracted volumes.
view3Dopt(vol1, vol2);
view3Dopt(v1sel, v2sel);

%% 3D registration with MRF overlap
% setup
patchOverlap = 'sliding';
usemex = exist('pdist2mex', 'file') == 3;
edgefn = @(a1,a2,a3,a4) patchlib.correspdst(a1, a2, a3, a4, [], usemex); % TODO:force no cross-over?

% patch search
tic;
[patches, pDst, pIdx, pRefIdxs, srcgridsize, refgridsize] = patchlib.volknnsearch(v1sel, ...
    v2sel, patchSize, patchOverlap, 'K', 27, 'location', 0.01, 'local', 1, 'fillK', true); 
toc;

% MRF on overlap
tic;
[qp, ~, ~, ~, pi] = ...
    patchlib.patchmrf(patches, srcgridsize, pDst, patchSize, patchOverlap , 'edgeDst', edgefn, ...
    'lambda_node', 0.1, 'lambda_edge', 0.1, 'pIdx', pIdx, 'refgridsize', refgridsize);
idx = patchlib.grid(size(v1sel), patchSize, patchOverlap);
disp = patchlib.corresp2disp(size(v1sel), refgridsize, pi, 'srcGridIdx', idx, 'reshape', true);
disp = patchlib.interpDisp(disp, patchSize, patchOverlap, size(v1sel)); % interpolate displacement
for i = 1:numel(disp), disp{i}(isnan(disp{i})) = 0; end
toc;

% recreate volumes.
v1wfwd = volwarp(v1sel, disp); % linear by default
v2wbwd = volwarp(v2sel, disp, 'backward'); % linear by default
% TODO: work with quilts as well?
%   v1quiltfromv2 = patchlib.quilt(qp, srcgridsize, patchSize, patchOverlap); 

% visualize warps
view3Dopt(v1sel, v2sel, v1wfwd, v2wbwd);

% compute dice of v1selseg and: v2selsegmoved and v2selseg.
v1segwfwd = volwarp(v1selseg, disp, 'interpmethod', 'nearest');
v2segwbwd = volwarp(v2selseg, disp, 'backward', 'interpmethod', 'nearest');
d1 = dice(v1selseg, v2selseg, 'all');
d2 = dice(v1selseg, v2segwbwd, 'all');
d3 = dice(v2selseg, v1selseg, 'all');
d4 = dice(v2selseg, v1segwfwd, 'all');
figure(); boxplot([d2', d4'] - [d1', d3']);

%% upsample the warp

% upsample warp all the way to the original, and move segments at that level
% this only works if there was no smallvolCrop
largeresize = 64*ones(1, 3);
vol1large = sim.loadNii(file1, 'mask', mask1, 'crop', range, 'uint82double', true, 'resize', largeresize);
vol1largeseg = sim.loadNii(mask1, 'mask', mask1, 'crop', range, 'resize', largeresize, 'resizeInterpMethod', 'nearest');
vol2large = sim.loadNii(file2, 'mask', mask2, 'crop', range, 'uint82double', true, 'resize', largeresize);
vol2largeseg = sim.loadNii(mask2, 'mask', mask2, 'crop', range, 'resize', largeresize, 'resizeInterpMethod', 'nearest');
warpNew = warpresize(disp, size(vol1large));

% move the images and visualize
v1largewfwd = volwarp(vol1large, warpNew); % this takes forever
v2largewbwd = volwarp(vol2large, warpNew, 'backward');
view3Dopt(vol1large, vol2large, v1largewfwd, v2largewbwd);

% see
v1largesegwfwd = volwarp(vol1largeseg, warpNew, 'interpmethod', 'nearest');
v2largesegwbwd = volwarp(vol2largeseg, warpNew, 'backward', 'interpmethod', 'nearest');
d1 = dice(vol1largeseg, vol2largeseg, 'all');
d2 = dice(vol1largeseg, v2largesegwbwd, 'all');
d3 = dice(vol2largeseg, vol1largeseg, 'all');
d4 = dice(vol2largeseg, v1largesegwfwd, 'all');
figure(); boxplot([d2', d4'] - [d1', d3']);

%% Other registration scripts
patchRegistration_cardiac; % cardiac
patchRegistrationCT; % CT
patchRegistration2D; % 2D
