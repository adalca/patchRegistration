function multiScaleWarp(exid)
    %Run patchlib.volknnsearch and lib2patches to get mrf unary potentials automatically. 
    %Then call patchmrf and use patchlib.correspdst for the pair potentials. 
    %Then repeat
    
    W = 60;
    H = 60;
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
        nii = loadNii('/afs/csail.mit.edu/u/a/abobu/toolbox/robert/0002_orig.nii');
        source = volresize(double(nii.img(:, :, 100)), [81, 81]);
        [target, ID] = sim.randShift(source, 3, 4, 4, false);
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
    
    patchSize = [3, 3];
    patchOverlap = 'sliding';
    disp = {zeros(size(source)), zeros(size(source))};
    
    for s = 10:2:size(source, 1)
        s
        % resizing the original source and target images to s
        targetS = volresize(target, [s, s]);
        sourceS = volresize(source, [s, s]);
        
        % resize de warp distances and then apply them to the resized
        % source
        dispS = warpresize(disp, [s, s]);
        sourceSWarped = volwarp(sourceS, dispS);
        
        % find the new distances
        dispSWarped = singleScaleWarp(sourceSWarped, targetS, patchSize, patchOverlap, false);
        disp = composeWarps(dispS, dispSWarped);
    end
    
    % compose the final image using the resulting displacements
    final = volwarp(source, disp, 'interpmethod', 'nearest');
    
    % display results
    patchview.figure();
    drawWarpedImages(source, target, final, disp); 
    view3Dopt(source, target, final, disp{:});
end



