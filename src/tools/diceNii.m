function diceNii(vol1Nii, vol2Nii, savePath, labelsFile)
    vol1 = niftireg.prepNiiToVol(vol1Nii);
    vol2 = niftireg.prepNiiToVol(vol2Nii);
    nargin
    if nargin == 4
        labels = fscanf(fopen(labelsFile,'r'),'%f');
        dicelabels = labels;
    else 
        dicelabels = unique([vol1(:); vol2(:)]);
    end

    [dices, finalLabels] = dice(vol1, vol2, dicelabels);
    save(savePath, 'dices', 'finalLabels');
end