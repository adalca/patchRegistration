function vol = loadNii(niifile, varargin) 
% SIM.LOADNII - load a nifti and process it for patch registration.
%
%   vol = loadNii(niifile) - load the nifti file and return the volume. niifile can be a filename or
%   a nifti struct
%
%   vol = loadNii(niifile, Param, Value, ...) allows for parameter/value pair options:
%       mask - a volume or file of the same size of the nii volume.
%       crop - cell of size nDims x 1. each entry indicates the crop range in that dimension
%       resize - size to resize the final (after cropping).
%       uint82double - double(nii.img)/255
%
% Contact: adalca at csail.mit.edu

    % input parsing
    p = inputParser();
    p.addRequired('niifile', @(x) ischar(x) || isstruct(x));
    p.addParameter('mask', [], @(x) ischar(x) || isnumeric(x) || isstruct(x));
    p.addParameter('crop', {}, @iscell);
    p.addParameter('resize', [], @isvector);
    p.addParameter('uint82double', false, @islogical);
    p.parse(niifile, varargin{:});
    
    % get volume
    nii = loadNii(niifile);
    vol = nii.img;
    
    % uint8 --> double
    if p.Results.uint82double
        vol = double(nii.img)/255;
    end
    
    % masking 
    if ~isempty(p.Results.mask)
        if ischar(p.Results.mask)
            mnii = loadNii(p.Results.mask);
            mask = mnii.img;
        elseif isstruct(p.Results.mask)
            mask = p.Results.mask.img;
        else
            mask = p.Results.mask;
        end
        assert(all(size(nii.img) == size(mask)));
    else
        mask = true(size(vol));
    end
    vol(~mask) = 0;
    
    % croping
    if ~isempty(p.Results.crop)
        vol = vol(p.Results.crop{:});
    end
    
    % resizing
    if ~isempty(p.Results.resize)
        vol = volresize(vol, p.Results.resize);
    end
    