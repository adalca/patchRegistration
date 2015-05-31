function drawWarpedImages(movingI, targetI, finalI, estimatedDisp, realDisp) 
    n = ndims(movingI);
    if exist('realDisp', 'var')
        nRows = 3;
    else
        nRows = 2;
    end
    
    if n == 2
        subplot(nRows, 3, 1); imagesc(movingI); colormap gray; title('moving image'); axis off;
        subplot(nRows, 3, 2); imagesc(targetI); colormap gray; title('target image'); axis off;
        subplot(nRows, 3, 3); imagesc(finalI); colormap gray; title('registered image'); axis off;
        if exist('realDisp', 'var')
            subplot(nRows, 3, 4); imagesc(realDisp{1}); colormap gray; title('estimated disp 1'); axis off;
            subplot(nRows, 3, 5); imagesc(realDisp{2}); colormap gray; title('estimated disp 2'); axis off;
        end
        subplot(nRows, 3, (nRows-1)*3+1); imagesc(estimatedDisp{1}); colormap gray; title('estimated disp 1'); axis off;
        subplot(nRows, 3, (nRows-1)*3+2); imagesc(estimatedDisp{2}); colormap gray; title('estimated disp 2'); axis off;
    elseif n == 3
        subplot(nRows, 3, 1); imagesc(movingI(:,:,11)); colormap gray; title('moving image'); axis off;
        subplot(nRows, 3, 2); imagesc(targetI(:,:,11)); colormap gray; title('target image'); axis off;
        subplot(nRows, 3, 3); imagesc(finalI(:,:,11)); colormap gray; title('registered image'); axis off;

        if exist('realDisp', 'var')
            subplot(nRows, 3, 4); imagesc(realDisp{1}(:,:,11)); colormap gray; title('correct disp 1'); axis off;
            subplot(nRows, 3, 5); imagesc(realDisp{2}(:,:,11)); colormap gray; title('correct disp 2'); axis off;
            subplot(nRows, 3, 6); imagesc(realDisp{3}(:,:,11)); colormap gray; title('correct disp 3'); axis off;
        end
        subplot(nRows, 3, (nRows-1)*3+1); imagesc(estimatedDisp{1}(:,:,11)); colormap gray; title('estimated disp 1'); axis off;
        subplot(nRows, 3, (nRows-1)*3+2); imagesc(estimatedDisp{2}(:,:,11)); colormap gray; title('estimated disp 2'); axis off;
        subplot(nRows, 3, (nRows-1)*3+3); imagesc(estimatedDisp{3}(:,:,11)); colormap gray; title('estimated disp 3'); axis off;
    end
end