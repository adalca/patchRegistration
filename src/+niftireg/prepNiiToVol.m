function vol = prepNiiToVol(niifile, volPad, maxVolSize)
% preprocess the nifti file into volume, allowing for optional volume resizing
%
%   niifile is the nii file to be converted to volume
%   volpad is the image padding volume
%   maxVolSize is the maximum size of the volume

    % Prepare volume
    niiVol = loadNii(niifile);
    vol = double(niiVol.img);
    
    % resize volume if a maxVolSize is given
    if nargin == 3
        szRatio = max(size(niiVol.img)) ./ maxVolSize;
        newVolSize = round(size(niiVol.img) ./ szRatio);
        vol = volresize(double(vol), newVolSize);
    end
    
    % pad if required
    if nargin > 1
        vol = padarray(vol, volPad, 'both');
    end 
end
