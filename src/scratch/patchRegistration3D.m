function patchRegistration3D(exid, varargin)
    %Run patchlib.volknnsearch and lib2patches to get mrf unary potentials automatically. 
    %Then call patchmrf and use patchlib.correspdst for the pair potentials. 
    %Then repeat
    
    if exid == 1
        %Real example
        file = 'C:\Users\Andreea\Dropbox (MIT)\MIT\Sophomore\Spring\UROP\robert\0002_orig.nii';
        nii = loadNii(file);
        I_1 = volresize(double(nii.img), [21, 21, 21]);
    elseif exid == 2
        %coloredSquare.jpg example
        imd = im2double(imread('C:\Users\Andreea\Dropbox (MIT)\MIT\Sophomore\Spring\UROP\coloredSquare.jpg'));
        imd = padarray(imd, [0 0 18], 0, 'post');
        I_1 = volresize(imd(310:330, 310:330, 1:21), [21, 21, 21]);
    else
        %manual image
        W = 21;
        H = 21;
        D = 21;
        I_1 = zeros(W, H, D);
        [xx, yy, zz] = ndgrid(1:W, 1:H, 1:D);
        I_1 = I_1 + 1*(xx >= W/2 & yy >= H/2 & zz) + 0.33*(xx < W/2 & yy >= H/2 & zz) + 0.66*(xx >= W/2 & yy < H/2 & zz);
    end
    
    [I_2, I_D] = sim.randShift(I_1, 1, 4, 4, false);
    patchSize = [3,3,3];
    patchOverlap = 'half';

    [patches, pDst, pIdx,~,srcgridsize,refgridsize] = patchlib.volknnsearch(I_1, I_2, patchSize, patchOverlap, 'local', 1, 'location', 0.4, 'K', 27, 'fillK', true);
    
    usemex = exist('pdist2mex', 'file') == 3;
    edgefn = @(a1,a2,a3,a4) patchlib.correspdst(a1, a2, a3, a4, [], usemex); 
    
    [qp, ~, ~, ~, pi] = ...
            patchlib.patchmrf(patches, srcgridsize, pDst, patchSize, patchOverlap, 'edgeDst', edgefn, ...
            'lambda_node', 0.1, 'lambda_edge', 0.1, 'pIdx', pIdx, 'refgridsize', refgridsize);
        
    idx = patchlib.grid(size(I_1), patchSize, patchOverlap);
    disp = patchlib.corresp2disp(size(I_1), refgridsize, pi, 'srcGridIdx', idx, 'reshape', true);
    disp = patchlib.interpDisp(disp, patchSize, patchOverlap, size(I_1)); % interpolate displacement
    for i = 1:numel(disp), disp{i}(isnan(disp{i})) = 0; end

    I_3 = volwarp(I_1, disp, 'interpmethod', 'nearest');
        
    % display results
    patchview.figure();
    subplot(4, 3, 1); imagesc(I_1(:,:,11)); colormap gray; title('moving image'); axis off;
    subplot(4, 3, 2); imagesc(I_2(:,:,11)); colormap gray; title('target image'); axis off;
    subplot(4, 3, 3); imagesc(I_3(:,:,11)); colormap gray; title('registered image'); axis off;
    
    subplot(4, 3, 4); imagesc(I_D{1}(:,:,11)); colormap gray; title('correct disp x'); axis off;
    subplot(4, 3, 5); imagesc(I_D{2}(:,:,11)); colormap gray; title('correct disp y'); axis off;
    subplot(4, 3, 6); imagesc(I_D{3}(:,:,11)); colormap gray; title('correct disp z'); axis off;
    
    subplot(4, 3, 7); imagesc(disp{1}(:,:,11)); colormap gray; title('estimated disp x'); axis off;
    subplot(4, 3, 8); imagesc(disp{2}(:,:,11)); colormap gray; title('estimated disp y'); axis off;
    subplot(4, 3, 9); imagesc(disp{3}(:,:,11)); colormap gray; title('estimated disp z'); axis off;
    
    view3Dopt(I_1, I_2, I_3, I_D{:});
    
end



