function warpNew = resizeWarp(warp, newsize, varargin)
% resize the given warp  to the newsize, and adjust the warp values appropriately.
%   warpNew = warpresize(warp, newsize) warp is a ndims x 1 cell, newsize is a ndims-long vector
%
%   warpNew = warpresize(warp, newsize, interpMethod).
% 
% contact: adalca@csail.mit.edu

    warpNew = cellfunc(@(x) volresize(x, newsize, varargin{:}), warp);
    
    sz = newsize ./ size(warp{1});
    warpNew = cellfunc(@(x, y) x * y, warpNew, mat2cellsplit(sz));
    