function patchRegistration3D(exid)
    %Run patchlib.volknnsearch and lib2patches to get mrf unary potentials automatically. 
    %Then call patchmrf and use patchlib.correspdst for the pair potentials. 
    %Then repeat
    
    if exid == 1
        %Real example
        file = 'C:\Users\Andreea\Dropbox (MIT)\MIT\Sophomore\Spring\UROP\robert\0002_orig.nii';
        nii = loadNii(file);
        sourceI = volresize(double(nii.img), [21, 21, 21]);
    elseif exid == 2
        %coloredSquare.jpg example
        imd = im2double(imread('C:\Users\Andreea\Dropbox (MIT)\MIT\Sophomore\Spring\UROP\coloredSquare.jpg'));
        imd = padarray(imd, [0 0 18], 0, 'post');
        sourceI = volresize(imd(310:330, 310:330, 1:21), [21, 21, 21]);
    else
        %manual image
        W = 21;
        H = 21;
        D = 21;
        sourceI = zeros(W, H, D);
        [xx, yy, zz] = ndgrid(1:W, 1:H, 1:D);
        sourceI = sourceI + 1*(xx >= W/2 & yy >= H/2 & zz) + 0.33*(xx < W/2 & yy >= H/2 & zz) + 0.66*(xx >= W/2 & yy < H/2 & zz);
    end
    
    [targetI, realDisp] = sim.randShift(sourceI, 1, 4, 4, false);
    patchSize = [3,3,3];
    patchOverlap = 'half';

    [patches, pDst, pIdx,~,srcgridsize,refgridsize] = patchlib.volknnsearch(sourceI, targetI, patchSize, patchOverlap, 'local', 1, 'location', 0.4, 'K', 27, 'fillK', true);
    
    usemex = exist('pdist2mex', 'file') == 3;
    edgefn = @(a1,a2,a3,a4) patchlib.correspdst(a1, a2, a3, a4, [], usemex); 
    
    [qp, ~, ~, ~, pi] = ...
            patchlib.patchmrf(patches, srcgridsize, pDst, patchSize, patchOverlap, 'edgeDst', edgefn, ...
            'lambda_node', 0.1, 'lambda_edge', 0.1, 'pIdx', pIdx, 'refgridsize', refgridsize);
        
    idx = patchlib.grid(size(sourceI), patchSize, patchOverlap);
    disp = patchlib.corresp2disp(size(sourceI), refgridsize, pi, 'srcGridIdx', idx, 'reshape', true);
    disp = patchlib.interpDisp(disp, patchSize, patchOverlap, size(sourceI)); % interpolate displacement
    for i = 1:numel(disp), disp{i}(isnan(disp{i})) = 0; end

    finalI = volwarp(sourceI, disp, 'interpmethod', 'nearest');
        
    % display results
    patchview.figure();
    drawWarpedImages(sourceI, targetI, finalI, disp, realDisp); 
    view3Dopt(sourceI, targetI, finalI, realDisp{:}, disp{:});
    
end



