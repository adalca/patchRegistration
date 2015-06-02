function multiScaleWarp(exid)
    %Run patchlib.volknnsearch and lib2patches to get mrf unary potentials automatically. 
    %Then call patchmrf and use patchlib.correspdst for the pair potentials. 
    %Then repeat
    
    warning off backtrace
    
    W = 64;
    H = 64;
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
        source = volresize(double(nii.img(:, :, 152))/255, [W, H]);
        [target, ID] = sim.randShift(source, 3, 4, 4, false);
        target = volresize(double(nii.img(:, :, 152))/255, [W, H]);
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
    
    scales = 32:4:size(source, 1);
    nInnerReps = 5;
    
    for s = scales
        fprintf('Scale %d\n', s);
        
        % resizing the original source and target images to s
        targetS = volresize(target, [s, s]);
        sourceS = volresize(source, [s, s]);
        
        % resize de warp distances and then apply them to the resized
        % source
        dispS = warpresize(disp, [s, s]);
        
        % warp t times 
        for t = 1:nInnerReps           
            sourceSWarped = volwarp(sourceS, dispS);

            % find the new distances
            localDisp = singleScaleWarp(sourceSWarped, targetS, patchSize, patchOverlap, false);
            disp = composeWarps(dispS, localDisp);
            for i = 1:numel(disp), disp{i}(isnan(disp{i})) = 0; end
            dispS = disp;
            assert(isclean([disp{:}]))
            
            % do some debug displaying
            % figure(1);
            % subplot(nInnerReps, 1, t); imshow([sourceSWarped, targetS, localDisp{:}, disp{:}]);
        end
    end
    
    % compose the final image using the resulting displacements
    final = volwarp(source, disp, 'interpmethod', 'nearest');
    
    % display results
    patchview.figure();
    drawWarpedImages(source, target, final, disp); 
    %view3Dopt(source, target, final, disp{:});
end



