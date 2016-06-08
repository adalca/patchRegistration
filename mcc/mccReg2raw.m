function mccReg2raw(sourceDsXFile, sourceDsXUsXMaskFile, atlSeg2SubjRegNii, atlSeg2SubjRegMat, ...
    saveSourceRawSegNii)
% affine propagation of segmentations from affine_registered_subject space (i.e. rough "atlas"
% space) to original subject DsXUsX space.
%
% sourceDsXFile example: buckner01_brain_roc_downsampled5.nii.gz
% sourceDsXUsXMaskFile example: buckner01_brain_downsampled5_reinterpolated5_dsmask.nii.gz
% atlSeg2SubjRegNii example: sprintf('%s-seg-in-%s_via_%s.nii.gz', tgtName, srcName, displInvName);
% atlSeg2SubjRegMat example: buckner01_brain_downsampled5_reinterpolated5_reg.mat
% saveSourceRawSegNii example in output: sprintf('%s-seg-in-%s-raw_via_%s.nii.gz', tgtName, srcName, displInvName);

    % get tform and invert
    load(atlSeg2SubjRegMat);
    tform = tform.invert;
    
    % this only makes sense one way. Need to process separately
    % took out 'outputSave', saveSourceRawSegNii  
    swNii = warpNii(atlSeg2SubjRegNii, tform, 'nearest', 'OutputView', sourceDsXUsXMaskFile);
    
    % make new nii in DsX space.
    masknii = loadNii(sourceDsXUsXMaskFile);
    nii = loadNii(sourceDsXFile);
    sz = size(nii.img);
    nii.img = reshape(swNii.img(masknii.img(:)==1), sz);
    saveNii(nii, saveSourceRawSegNii);
end
