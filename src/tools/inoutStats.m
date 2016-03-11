function [meanin, meanout] = inoutStats(niifile, thr, segvolfile, segnr)
% given an isotropic intensity volume, 
%   and a binary mask volume (or segmentation volume + segmentation nr)
% compute the mean intensity just inside and outside the label
%
% [meanin, meanout] = inoutStats(niifile, thr, maskniifile)
%
% [meanin, meanout] = inoutStats(niifile, thr, segniifile, segnr)
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
        dims = niifile.hdr.dime.pixdim(2:4);
        assert(all(dims(1) == dims), 'volume is not isotropic');
    end
    vol = niifile.img;

    % get mask volume
    if ischar(segvolfile)
        segvolfile = loadNii(segvolfile);
    end
    segvol = segvolfile.img;
    if nargin == 4
        maskVol = segvol == segnr;
    else
        maskVol = segvol > 0;
        assert(numel(unique(maskVol(:))) <= 2, 'mask volume has more than one label');
    end

    % outside values
    obw = bwdist(maskVol);
    outMask = obw > 0 & obw < thr;
    meanin = mean(vol(outMask(:)));

    % inside values
    ibw = bwdist(~maskVol);
    inMask = ibw > 0 & ibw < thr;
    meanout = mean(vol(inMask(:)));
end
