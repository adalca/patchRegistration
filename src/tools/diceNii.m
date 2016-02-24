function [dst, finalLabels] = diceNii(vol1Nii, vol2Nii, labelsFile)
    vol1 = niftireg.prepNiiToVol(vol1Nii);
    vol2 = niftireg.prepNiiToVol(vol2Nii);

    if nargin == 3
        labels = fscanf(fopen(labelsFile,'r'),'%f');
        dicelabels = labels;
    else 
        dicelabels = unique([vol1(:); vol2(:)]);
    end

    [dst, finalLabels] = dice(vol1, vol2, dicelabels);
end