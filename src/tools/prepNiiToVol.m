function vol = prepNiiToVol(niifile, volPad, maxVolSize)
% preprocess the Nii file into volume 
% niifile is the nii file to be converted to volume
% volpad is the image padding volume
% maxVolSize is the maximum size of the volume

    %% Prepare volume
    niiVol = loadNii(niifile);
    szRatio = max(size(niiVol.img)) ./ maxVolSize;
    newVolSize = round(size(niiVol.img) ./ szRatio);
    vol = padarray(volresize(double(niiVol.img), newVolSize), volPad, 'both');
    
end