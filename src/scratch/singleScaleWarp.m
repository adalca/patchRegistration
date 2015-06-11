function [disp] = singleScaleWarp(source, target, patchSize, patchOverlap, verbose)
%Run patchlib.volknnsearch and lib2patches to get mrf unary potentials automatically. 
%Then call patchmrf and use patchlib.correspdst for the pair potentials. 
%Then repeat
%
% 'source' is the source(moving) image 
% 'target' is the target image
% 'patchSize' is the size of the patch
% 'patchOverlap' can be 'sliding' or 'half'
% 'verbose' if true, will draw the images (source, target,
% displacement, final) for 2D and 3D
%
% Important Notes:
% - note that patchlib sets up patches in the top left of the patches, whereas we want to "move" the
% center of the patches. Thus, we can either use trimarray and padarray after we get the full
% displacement, or use interpDisp with a shift.   


    disp = patchRegistrationLocal(source, target, patchSize, patchOverlap, (patchSize-1)/2);

    % display / view warp.
    n = ndims(source);
    if(verbose)
        warpedSource = volwarp(source, disp, 'interpmethod', 'nearest');
        
        assert(n == 2 || n == 3, 'Dimension incorrect for verbose. Can only use verbose with 2D or 3D');
        
        patchview.figure();
        drawWarpedImages(source, target, warpedSource, disp); 
        view3Dopt(source, target, warpedSource, disp{:});
    end   
end
