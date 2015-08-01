function [sourceWarped, displ] = example_multiScaleWarp(exid)

    % parameters
    patchSize = [3, 3];
    patchOverlap = 'sliding';
    nScales = 5;
    nInnerReps = 2;
    warning off backtrace; % turn off backtrace for warnings.
    
    W = 128;
    H = 128;
    source = zeros(W, H);
    if exid == 1
        source(30, 30) = 1; % get an image with a bump
        ID = {source, source};
        target = volwarp(source, ID); % move the bump by DX, DY
    elseif exid == 2
        source = rand(W, H);
        [target, ID] = sim.ovoidShift(source, 50, false);
    elseif exid == 3
        %cat.jpg example
        imd = im2double(rgb2gray(imread('/afs/csail.mit.edu/u/a/abobu/toolbox/cat.jpg')));
        source = volresize(imd, [W, H]);
        [target, ID] = sim.randShift(source, 3, 20, 20, false);
    elseif exid == 4
        %Real example
%         nii = loadNii('/afs/csail.mit.edu/u/a/abobu/toolbox/robert/0002_orig.nii');
        matlabmridata = load('mri');
        matlabmri = permute(matlabmridata.D, [1, 2, 4, 3]);
        maxval = max(double(matlabmri(:)));
        midframe = round(size(matlabmri, 3)/2);
        midframe = 17;
        source = volresize(double(matlabmri(:, :, midframe))./maxval, [W, H]);
        [target, ID] = sim.randShift(source, 5, 20, 20, false);
        target = volresize(double(matlabmri(:, :, midframe+1))./maxval, [W, H]);
    elseif exid == 5
        % Checkboard example
        source = checkerboard(10, 3, 3);
        [target, ID] = sim.randShift(source, 3, 20, 20, false);
    else
        %manual image quadrants
        [xx, yy] = ndgrid(1:W, 1:H);
        source = 1*(xx >= W/2 & yy >= H/2) + 0.33*(xx < W/2 & yy >= H/2) + 0.66*(xx >= W/2 & yy < H/2);
        [target, ID] = sim.ovoidShift(source, 6, false);
    end   
    
    % do multi scale registration
    [sourceWarped, displ] = ...
        patchreg.multiscale(source, target, patchSize, patchOverlap, nScales, nInnerReps);
    
    % display results
    if ndims(source) == 2 %#ok<ISMAT>
        patchview.figure();
        drawWarpedImages(source, target, sourceWarped, displ); 
    elseif ndims(source) == 3
        view3Dopt(source, target, final, displ{:});
    end
    