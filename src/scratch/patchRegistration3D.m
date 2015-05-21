function patchRegistration3D(exid, varargin)
    %Run patchlib.volknnsearch and lib2patches to get mrf unary potentials automatically. 
    %Then call patchmrf and use patchlib.correspdst for the pair potentials. 
    %Then repeat
    
    I_1 = zeros(21,21,21);
    
    if edid == 1
    %Real example
        nii = loadNii('C:\Users\Andreea\Dropbox (MIT)\MIT\Sophomore\Spring\UROP\robert\0002_orig.nii');
        I_1 = volresize(double(nii.img(115:135, 115:135, 115:135)), [21, 21, 21]);
    else if exid == 2
    %coloredSquare.jpg example
        imd = im2double(imread('C:\Users\Andreea\Dropbox (MIT)\MIT\Sophomore\Spring\UROP\coloredSquare.jpg'));
        imd = padarray(imd, [0 0 18], 0, 'post');
        I_1 = volresize(imd(310:330, 310:330, 1:21), [21, 21, 21]);
        else
            %manual image
            for i = 1:21
                for j = 1:21
                    for k = 1:21
                        if i<11 && j<11
                            I_1(i,j,k) = 0;
                        elseif i<11 && j>=11
                            I_1(i,j,k) = 0.33;
                        elseif i>=11 && j<11
                            I_1(i,j,k) = 0.66;
                        else
                            I_1(i,j,k) = 1;
                        end
                    end
                end
            end
        end
    end
    
    [I_2, I_DX, I_DY, I_DZ] = sim.ball3D(I_1);
    
    patchSize = [3,3,3];
    pW = patchSize(1);
    pH = patchSize(2);
    pD = patchSize(3);
    warning('We should use 1, but we are using 2 as a band aid.')
    [~, pDst, pIdx,~,srcgridsize,refgridsize] = patchlib.volknnsearch(I_2, I_1, patchSize, 'local', 2, 'excludePatches', true, 'K', 27);
    patches = patchlib.lib2patches(pDst, pIdx);
    
    usemex = exist('pdist2mex', 'file') == 3;
    edgefn = @(a1,a2,a3,a4) patchlib.correspdst(a1, a2, a3, a4, [], usemex); 
    
    [qp, ~, ~, ~, pi] = ...
            patchlib.patchmrf(patches, srcgridsize, pDst, patchSize , 'edgeDst', edgefn, ...
            'lambda_node', 2, 'lambda_edge', 1, 'pIdx', pIdx, 'refgridsize', refgridsize);
        
    disp = patchlib.corresp2disp(srcgridsize, refgridsize, pi, 'reshape', true);
    DX_final = padarray(disp{1}, [pH-1 pW-1 pD-1], 0, 'post');
    DY_final = padarray(disp{2}, [pH-1 pW-1 pD-1], 0, 'post');
    DZ_final = padarray(disp{3}, [pH-1 pW-1 pD-1], 0, 'post');
    I_3 = iminterpolate3D(I_1, DX_final, DY_final, DZ_final);
        
    % display results
        
    subplot(4, 3, 1); imagesc(I_1(:,:,2)); colormap gray; title('moving image'); axis off;
    subplot(4, 3, 2); imagesc(I_2(:,:,2)); colormap gray; title('target image'); axis off;
    subplot(4, 3, 3); imagesc(I_3(:,:,2)); colormap gray; title('registrated image'); axis off;
    
    subplot(4, 3, 4); imagesc(I_DX(:,:,2)); colormap gray; title('correct disp x'); axis off;
    subplot(4, 3, 5); imagesc(I_DY(:,:,2)); colormap gray; title('correct disp y'); axis off;
    subplot(4, 3, 6); imagesc(I_DZ(:,:,2)); colormap gray; title('correct disp z'); axis off;
    
    subplot(4, 3, 7); imagesc(disp{1}(:,:,2)); colormap gray; title('estimated disp x'); axis off;
    subplot(4, 3, 8); imagesc(disp{2}(:,:,2)); colormap gray; title('estimated disp y'); axis off;
    subplot(4, 3, 9); imagesc(disp{3}(:,:,2)); colormap gray; title('estimated disp z'); axis off;
end



