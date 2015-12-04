function  [patches, pDst, srcgridsize, refgridsize] = stateDistances(...)
% As an easy start, we can assume the reference/target grid is dense ('sliding'). It would be nicer
% to change this in the future, but it could be a good start.
%
% patches is nSrcGridPts x prod(patchSize) x parod(searchSize)
%
% Rought outline of algorithm:
%
% compute srcgridsize and refgridsize using patchlib.grid();
% compute the source library (size should be nSrcGridPts x prod(patchSize))
% compute the reference library (size should be nRefGridPts(==nRefSize) x prod(patchSize))
%
% for each point in the source grid
%    get the location in 2D/3D
%    compute all the locations in the reference library within the searchSize
%    transform these locations into a linear index (subvec2ind()) based on the reference grid
%    get the relevant patches from the computed libraries
%    compute all of the patch distances in pDst, and store them into pDst. Note, this storage has 
%       to be in a consistent order for all locations, even edge ones. At the edges, for unavailable
%       patches, e.g. for computation at the edges of the volume, set distance of infinity (I think)
%   also fill in patches array in a consistent matter.


 
 