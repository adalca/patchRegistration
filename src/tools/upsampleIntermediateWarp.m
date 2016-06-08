function upsampleIntermediateWarp(statsFile, subjectUpsampleNiiFile, saveDisplFile)
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
    
    % save final warp
    displNii = make_nii(cat(5, finalDispl{:}));
    saveNii(displNii, saveDisplFile);
end
