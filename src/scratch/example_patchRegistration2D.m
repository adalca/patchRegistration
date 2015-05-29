function example_patchRegistration2D(exid)
    %Run patchlib.volknnsearch and lib2patches to get mrf unary potentials automatically. 
    %Then call patchmrf and use patchlib.correspdst for the pair potentials. 
    %Then repeat
    W = 81;
    H = 81;
    I_1 = zeros(W, H);
    if exid == 1
        I_1(3, 3) = 1; % get an image with a bump
        I_D = {I_1, I_1};
        I_2 = volwarp(I_1, I_D); % move the bump by DX, DY
    elseif exid == 2
        I_1 = rand(W, H);
        [I_2, I_D] = sim.ovoidShift(I_1, 6, false);
    elseif exid == 3
        %cat.jpg example
        imd = im2double(rgb2gray(imread('C:\Users\Andreea\Dropbox (MIT)\MIT\Sophomore\Spring\UROP\cat.jpg')));
        I_1 = volresize(imd, [81,81]);
        [I_2, I_D] = sim.randShift(I_1, 1, 4, 4, false);
    elseif exid == 4
        %Real example
        nii = loadNii('C:\Users\Andreea\Dropbox (MIT)\MIT\Sophomore\Spring\UROP\robert\0002_orig.nii');
        I_1 = volresize(double(nii.img(:, :, 100)), [81, 81]);
        [I_2, I_D] = sim.randShift(I_1, 3, 4, 4, false);
    else
        %manual image quadrants
        [xx, yy] = ndgrid(1:W, 1:H);
        I_1 = 1*(xx >= W/2 & yy >= H/2) + 0.33*(xx < W/2 & yy >= H/2) + 0.66*(xx >= W/2 & yy < H/2);
        [I_2, I_D] = sim.ovoidShift(I_1, 6, false);
    end   
    
    patchSize = [3, 3];
    pW = patchSize(1);
    pH = patchSize(2);

    warning('We should use 1, but we are using 2 as a band aid.')
    [~, pDst, pIdx,~,srcgridsize,refgridsize] = patchlib.volknnsearch(I_1, I_2, patchSize, 'local', 1, 'location', 0.01, 'excludePatches', true, 'K', 9, 'fillK', true);
    patches = patchlib.lib2patches(pDst, pIdx);
    
    usemex = exist('pdist2mex', 'file') == 3;
    edgefn = @(a1,a2,a3,a4) patchlib.correspdst(a1, a2, a3, a4, [], usemex); 
    
    [qp, ~, ~, ~, pi] = ...
            patchlib.patchmrf(patches, srcgridsize, pDst, patchSize , 'edgeDst', edgefn, ...
            'lambda_node', 0.1, 'lambda_edge', 0.1, 'pIdx', pIdx, 'refgridsize', refgridsize);
        
    disp = patchlib.corresp2disp(srcgridsize, refgridsize, pi, 'reshape', true);
    DX_final = padarray(disp{1}, [pH-1 pW-1], 0, 'post');
    DY_final = padarray(disp{2}, [pH-1 pW-1], 0, 'post');
    I_3 = volwarp(I_1, {DX_final, DY_final}, 'interpmethod', 'nearest');
        
    % display results
    patchview.figure();
    subplot(4, 3, 1); imagesc(I_1); colormap gray; title('moving image'); axis off;
    subplot(4, 3, 2); imagesc(I_2); colormap gray; title('target image'); axis off;
    subplot(4, 3, 3); imagesc(I_3); colormap gray; title('registered image'); axis off;
    
    subplot(4, 3, 4); imagesc(I_D{1}); colormap gray; title('correct disp x'); axis off;
    subplot(4, 3, 5); imagesc(I_D{2}); colormap gray; title('correct disp y'); axis off;
    
    subplot(4, 3, 7); imagesc(disp{1}); colormap gray; title('estimated disp x'); axis off;
    subplot(4, 3, 8); imagesc(disp{2}); colormap gray; title('estimated disp y'); axis off;
end



