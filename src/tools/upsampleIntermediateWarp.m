function upsampleIntermediateWarp(statsFile, subjectUpsampleNiiFile, atlSegFile, saveSegFile)
% upsample intermediate scale warp to final warp size.
%
% statsFile - mat file with stats of the scale we want to upsample from
% subjectUpsampleNiiFile used to get the size of the highest scale. e.g. *ds7_us7.nii.gz
% saveDisplFile - nii filename to save the displacement to


    % load stats file
    stats = load(statsFile);
    
    % take out (low-scale) dispalcement
    displ = stats.displVolumes.cdispl;
    
    % load subject nifti file for size
    nii = loadNii(subjectUpsampleNiiFile);
    imsz = size(nii.img);

    % upsample 
    finalDispl = resizeWarp(displ, imsz);
    
    % warp segmentation
    seg = nii2vol(atlSegFile);
    warpedSeg = volwarp(seg, finalDispl, 'backward');
    
    % save final warp
    outnii = make_nii(warpedSeg);
    saveNii(outnii, saveSegFile);
end
