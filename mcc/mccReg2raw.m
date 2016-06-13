function nii = mccReg2raw(subjRawDsXFile, subjDsXUsXMaskFile, atlSegInSubjRegNii, subj2AtlRegMat, ...
    saveSourceRawSegNii)
% affine propagation of segmentations from affine_registered_subject space (i.e. rough "atlas"
% space) to original subject DsXUsX space.
%
% subjRawDsXFile example: buckner01_brain_roc_downsampled5.nii.gz
% subjDsXUsXMaskFile example: buckner01_brain_downsampled5_reinterpolated5_dsmask.nii.gz
% atlSegInSubjRegNii example: sprintf('%s-seg-in-%s_via_%s.nii.gz', tgtName, srcName, displInvName);
% subj2AntlRegMat example: buckner01_brain_downsampled5_reinterpolated5_reg.mat
% saveSourceRawSegNii example in output: sprintf('%s-seg-in-%s-raw_via_%s.nii.gz', tgtName, srcName, displInvName);

    % get tform and invert
    load(subj2AtlRegMat);
    tform = tform.invert;
    
    % this only makes sense one way. Need to process separately
    % took out 'outputSave', saveSourceRawSegNii  
    swNii = warpNii(atlSegInSubjRegNii, tform, 'nearest', 'OutputView', subjDsXUsXMaskFile);
    
    % make new nii in DsX space.
    masknii = loadNii(subjDsXUsXMaskFile);
    nii = loadNii(subjRawDsXFile);
    sz = size(nii.img);
    nii.img = reshape(swNii.img(masknii.img(:)==1), sz);
    if nargin >= 5 && ~isempty(saveSourceRawSegNii)
        saveNii(nii, saveSourceRawSegNii);
    end
end
