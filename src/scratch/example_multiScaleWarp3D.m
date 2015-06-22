function [sourceWarped, displ] = example_multiScaleWarp3D(exid)

    % parameters
    patchSize = [5, 5, 5];
    patchOverlap = [0, 0, 0] + 1;
    nScales = 2;
    nInnerReps = 3;
    warning off backtrace; % turn off backtrace for warnings.
    
    W = 64;
    H = 64;
    D = 64;
    source = zeros(W, H, D);
    if exid == 1
        %Real example
         niiS = loadNii('/afs/csail.mit.edu/u/a/abobu/toolbox/buckner/buckner02_brain_affinereg_to_b61.nii.gz');
         source = volresize(double(niiS.img)/255, [W, H, D]);
         niiT = loadNii('/afs/csail.mit.edu/u/a/abobu/toolbox/buckner/buckner03_brain_affinereg_to_b61.nii.gz');
         target = volresize(double(niiT.img)/255, [W, H, D]);
    end   
    
    % do multi scale registration
    [sourceWarped, displ] = ...
        patchreg.multiscale(source, target, patchSize, patchOverlap, nScales, nInnerReps);
    
    % display results
    if ndims(source) == 2 %#ok<ISMAT>
        patchview.figure();
        drawWarpedImages(source, target, sourceWarped, displ); 
    elseif ndims(source) == 3
        view3Dopt(source, target, sourceWarped, displ{:});
    end
    