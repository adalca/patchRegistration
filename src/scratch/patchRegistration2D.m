%% 2D registration experiments

%% 2D crop
v1slice = double(nii1.img(160:200,120:160,128))/255;
v2slice = double(nii2.img(:,:,128))/255;
refslice = v2slice;

%% 2D downsampled
fact = 96;
v1slice = imresize(double(nii1.img(:,:,139))/255, [1, 1]*fact);
v2slice = imresize(double(nii2.img(:,:,137))/255, [1, 1]*fact);
refslice = v2slice;
% v1slice(10:15, 10:15) = v1slice(15:20, 15:20);
% [patches, pDst, pIdx, pRefIdxs, srcgridsize, refgridsize] = patchlib.volknnsearch(v1slice, refslice, patchSize , 'K', 10, 'local', 3);

%% 2D bigger, slices next to eachother from one vol
v1slice = double(nii1.img(100:200,100:160,128))/255;
v2slice = double(nii1.img(100:200,100:160,127))/255;
refslice = v2slice;

%% 2D full slice, slices next to eachother from one vol
v1slice = double(nii1.img(:, :, 135))/255;
v2slice = double(nii1.img(:, :, 128))/255;
refslice = v2slice;

%% 2D full slices mostly matching from different volumes
v1slice = double(nii1.img(:, :, 125))/255;
v2slice = double(nii2.img(:, :, 125))/255;
[optimizer, metric] = imregconfig('monomodal');
v2slicemoved = imregister(v2slice,v1slice,'rigid',optimizer,metric);
refslice = v2slicemoved;
multiimagesc(1, 2, v1slice, refslice); colormap gray;

%% test pixel move with movepixels_2d_double
newsize = 10;
mv = zeros(size(v1sel));
mv(ceil(newsize/1.7), ceil(newsize/1.7)) = 1;
mvb = imBlurSep(mv, [51, 51], 1.5, [1, 1, 1]);  mvb = mvb ./ max(mvb(:));
multiimagesc(1, 2, mv, mvb); colormap gray;

ref = movepixels_2d_double(v1sel, mvb*3, mvb*3, 2);
multiimagesc(1, 2, v1sel, ref); colormap gray;
[patches, pDst, pIdx, pRefIdxs, srcgridsize, refgridsize] = patchlib.volknnsearch(v1sel, ref, patchSize , 'K', 100, 'local', 20);

%% 
TODO: note that pIdx is in refgridsize not size(refslice).
figuresc(); clf;
colormap gray;
nRows = 3;
patchSize = [5, 5];
edgefn = @(a1,a2,a3,a4) patchlib.correspdst(a1, a2, a3, a4, [], true);

% simply quilt original patches.
[patches, pDst, pIdx, pRefIdxs, srcgridsize, refgridsize] = ...
    patchlib.volknnsearch(v1slice, refslice, patchSize , 'K', 10, 'location', 0.01); %0.01);
resimg = patchlib.quilt(patches(:,:,1), srcgridsize, patchSize);  
disp = patchlib.corresp2disp(srcgridsize, refgridsize, pIdx(:, 1), 'reshape');
viewReconstruction(v1slice, resimg, pIdx(:, 1), disp, srcgridsize, nRows, 1);

% 2d with MRF
% use distance function based on similarity of location
[qp, ~, ~, pi] = ...
    patchlib.patchmrf(patches, srcgridsize, pDst, patchSize , 'edgeDst', edgefn, ...
    'lambda_node', 0.01, 'lambda_edge', 10, 'pIdx', pIdx, 'refgridsize', refgridsize);
disp = patchlib.corresp2disp(srcgridsize, refgridsize, pi, 'reshape');
resimg = patchlib.quilt(qp, srcgridsize); resimg(1, 1) = 0.7;
viewReconstruction(v1slice, resimg, pi, disp, srcgridsize, nRows, 2);
view3Dopt(v1slice, v2slice, disp{:})

% 2d with agreement mrf
[qpatches, bel, pot, pi] = patchlib.patchmrf(patches, srcgridsize, pDst, patchSize , ...
    'lambda_node', 0.01, 'pIdx', pIdx);
disp = patchlib.corresp2disp(srcgridsize, refgridsize, pi);
resimg = patchlib.quilt(qpatches(:,:,1), srcgridsize); resimg(1, 1) = 0.7;
viewReconstruction(v1slice, resimg, pi, disp, srcgridsize, nRows, 3);

error('location could be a function of entropy of src patch... the more entropy, the less location matters? n/s');
