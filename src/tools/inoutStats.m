function [meanin, meanout] = inoutStats(niifile, thr, segniifile, segnr)
% INOUTSTATS compute the mean intensity just inside and just outside a
% label of interest.
%
% [meanin, meanout] = inoutStats(niifile, thr, maskVol) given an isotropic
% intensity volume,  and a binary mask volume, compute the mean intensity
% just inside and outside the label of interest. niifile should be an
% isotropic intensity nifti filename, or nifti struct. maskVol can
% similarly be a nii filename, or nifti strucct, or just the volume
% directly. 
%
% [meanin, meanout] = inoutStats(niifile, thr, segVol, segid) allows for
% the specification of a segmentation volume (multi-label volume) and a
% particular label of interest. We then compute the maskVolume via
% segVol==segid, and proceed from there.
%
% algo outline:
% load files as necessary until we have a volume and a mask volume
% outside mask: compute bwdist() on maskVolume, get all pixels whose bwdist is within thr
% inside mask: compute bwdist() on 1-maskVolume
% compute the two means and return

    narginchk(3, 4);

    % get image
    if ischar(niifile)
        niifile = loadNii(niifile);
    end
    dims = niifile.hdr.dime.pixdim(2:4);
    assert(all(dims(1) == dims), 'volume is not isotropic');
    vol = niifile.img;

    % get mask volume
    segvol = segniifile.img;
    if ischar(segniifile)
        segniifile = loadNii(segniifile);
        segvol = segniifile.img;
    elseif isstruct(segniifile)
        segvol = segniifile.img;
    end
    
    if nargin == 4
        maskVol = segvol == segnr;
    else
        maskVol = segvol > 0;
        msg = 'mask volume has more than one label';
        assert(numel(unique(maskVol(:))) <= 2, msg);
    end
    msg = 'volume and mask don''t match size';
    assert(all(size(maskVol) == size(vol)), msg);

    % outside values
    obw = bwdist(maskVol);
    outMask = obw > 0 & obw < thr;
    meanout = mean(vol(outMask(:)));

    % inside values
    ibw = bwdist(~maskVol);
    inMask = ibw > 0 & ibw < thr;
    meanin = mean(vol(inMask(:)));
end
