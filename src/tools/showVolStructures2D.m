function [rgbImages, hs] = showVolStructures2D(vol, seg, directions, multfact, thickness, docrop, varargin)
%
%
% TODO: combine with mmit's nii2images
    warning('TODO: combine showVolStructures2D with nii2images');

    % load data
    if ischar(vol) || isstruct(vol), vol = nii2vol(vol); end
    if ischar(seg) || isstruct(seg), seg = nii2vol(seg); end
    
    if nargin <= 3 || isempty(multfact), multfact = 1; end
    if nargin <= 5 || isempty(docrop), docrop = false; end
    
    % crop if asked to
    if docrop
        [vol, ~, c] = boundingBox(vol);
        seg = seg(c{:});
    end
    
    % check if color specified
    color = [];
    if numel(varargin)==1
        color=varargin{:};
    end
    
    % resize if necessary
    if multfact > 0
        vol = volresize(vol, size(vol) .* multfact);
        seg = volresize(seg, size(seg) .* multfact, 'nearest');
    end

    % create 2D images.
    hs = cell(numel(directions), 1);
    for diri = 1:numel(directions)
        dirn = directions{diri};
        
        switch dirn
            case 'axial'
                % get and show axial images
                rgbImages = flip(permute(overlapVolSeg(vol, seg, [], color, thickness), [2, 1, 3, 4]), 1);
                %view2D(dimsplit(4, rgbImages)); 
                %hs{diri} = gcf;
                
            case 'saggital'
                % get and show saggital images
                mid = round(size(vol, 1)/2);
                svol = vol(mid-10:3:mid+10, :, :); 
                sseg = seg(mid-10:3:mid+10, :, :);
                rgbImages = overlapVolSeg(permute(svol, [3, 2, 1]), permute(sseg, [3, 2, 1]), [], color, thickness);
                rgbImages = flip(rgbImages, 1);
                view2D(dimsplit(4, rgbImages)); 
                hs{diri} = gcf;
                
            otherwise 
                error('unknown direction: %s', dirn);
        end
        
    end
    