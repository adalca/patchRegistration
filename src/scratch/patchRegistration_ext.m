% some old code from registration and some ideas
% IDEAS:
% - do subject to atlas?
% - try slice registration and movign forward with demons move fwd code... or just... grab patches?
% - moving forward is easy, see demons code. It''s just an interpolation method?

%%
% % patch quilt
% resimg = patchlib.quilt(patches(:,:,1), srcgridsize, patchSize, patchOverlap);  
% resimg2 = patchlib.quilt(patches, srcgridsize, patchSize, patchOverlap);  
% disp = patchlib.corresp2disp(srcgridsize, refgridsize, pIdx(:, 1), 'reshape', true);
% view3Dopt(v1sel, ref, resimg, disp{:});

%% visualize displacement in quick patch search for sub-volumes
% TODO - maybe move this to an example in patchlib. and reference here as a good thing to look up.
% do a quick local patch search and get the nearest neighbor
[~, ~, pIdx, ~, srcgridsize, refgridsize] = ...
    patchlib.volknnsearch(v1sel, v2sel, patchSize, 'sliding', 'K', 1, 'local', 10);

% visualize the location in 3D
srcgrididx = patchlib.grid(size(v1sel), patchSize, 'sliding');
disp = patchlib.corresp2disp(size(v1sel), refgridsize, pIdx, 'srcGridIdx', srcgrididx, 'reshape', true);
view3Dopt(v1sel, disp{:});

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
