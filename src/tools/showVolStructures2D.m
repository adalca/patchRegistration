function hs = showVolStructures2D(vol, seg, directions)

    % load data
    if ischar(vol) || isstruct(vol), vol = nii2vol(vol); end
    if ischar(seg) || isstruct(seg), seg = nii2vol(seg); end

    hs = cell(numel(directions), 1);
    for diri = 1:numel(directions)
        dirn = directions{diri};
        
        switch dirn
            case 'axial'
                % get and show axial images
                rgbImages = flip(permute(overlapVolSeg(vol, seg, [], [], 1), [2, 1, 3, 4]), 1);
                view2D(dimsplit(4, rgbImages)); 
                hs{diri} = gcf;
                
            case 'saggital'
                % get and show saggital images
                mid = round(size(vol, 1)/2);
                svol = vol(mid-10:3:mid+10, :, :); 
                sseg = seg(mid-10:3:mid+10, :, :);
                rgbImages = overlapVolSeg(permute(svol, [3, 2, 1]), permute(sseg, [3, 2, 1]), [], [], 1);
                rgbImages = flip(rgbImages, 1);
                view2D(dimsplit(4, rgbImages)); 
                hs{diri} = gcf;
                
            otherwise 
                error('unknown direction: %s', dirn);
        end
        
    end