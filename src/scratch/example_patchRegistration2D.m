function example_patchRegistration2D(exid)
    %Run patchlib.volknnsearch and lib2patches to get mrf unary potentials automatically. 
    %Then call patchmrf and use patchlib.correspdst for the pair potentials. 
    %Then repeat
    
    I_1 = zeros(21, 21);
    if exid == 1
        I_1(3, 3) = 1; % get an image with a bump
        I_DX = I_1;
        I_DY = I_1;
        I_2 = volwarp(I_1, {I_DX, I_DY}); % move the bump by DX, DY
    else
    %manual image
        for i = 1:21
            for j = 1:21
                if i<11 && j<11
                    I_1(i,j) = 0;
                elseif i<11 && j>=11
                    I_1(i,j) = 0.33;
                elseif i>=11 && j<11
                    I_1(i,j) = 0.66;
                else
                    I_1(i,j) = 1;
                end
            end
        end
        [I_2, I_DX, I_DY] = sim.ball2D(I_1);
    end   
    
    patchSize = [5, 5];
    pW = patchSize(1);
    pH = patchSize(2);

    warning('We should use 1, but we are using 2 as a band aid.')
    [~, pDst, pIdx,~,srcgridsize,refgridsize] = patchlib.volknnsearch(I_1, I_2, patchSize, 'local', 2, 'location', 0.1, 'excludePatches', true, 'K', 9);
    patches = patchlib.lib2patches(pDst, pIdx);
    
    usemex = exist('pdist2mex', 'file') == 3;
    edgefn = @(a1,a2,a3,a4) patchlib.correspdst(a1, a2, a3, a4, [], usemex); 
    
    [qp, ~, ~, ~, pi] = ...
            patchlib.patchmrf(patches, srcgridsize, pDst, patchSize , 'edgeDst', edgefn, ...
            'lambda_node', 0.2, 'lambda_edge', 0, 'pIdx', pIdx, 'refgridsize', refgridsize);
        
    disp = patchlib.corresp2disp(srcgridsize, refgridsize, pi, 'reshape', true);
    DX_final = padarray(disp{1}, [pH-1 pW-1], 0, 'post');
    DY_final = padarray(disp{2}, [pH-1 pW-1], 0, 'post');
    I_3 = volwarp(I_1, {DX_final, DY_final});
        
    % display results
        
    subplot(4, 3, 1); imagesc(I_1); colormap gray; title('moving image'); axis off;
    subplot(4, 3, 2); imagesc(I_2); colormap gray; title('target image'); axis off;
    subplot(4, 3, 3); imagesc(I_3); colormap gray; title('registrated image'); axis off;
    
    subplot(4, 3, 4); imagesc(I_DX); colormap gray; title('correct disp x'); axis off;
    subplot(4, 3, 5); imagesc(I_DY); colormap gray; title('correct disp y'); axis off;
    
    subplot(4, 3, 7); imagesc(disp{1}); colormap gray; title('estimated disp x'); axis off;
    subplot(4, 3, 8); imagesc(disp{2}); colormap gray; title('estimated disp y'); axis off;
end



