function finalW = composeWarps(warp1, warp2)
% Calculates the composition of two forward warps: warp1 is the displacement
% from image A to B; warp 2 is the displacement from image B to C;
% finalWarp is the overall A->C displacement
%
% TODO: composition of backward warp, and combinations thereof
% TODO: inverseWarp. Think of all of these files.
% TODO: add interpmethod, etc. This can be important!

    narginchk(2, 2);

    % move warp2 in the frame of warp1. 
    deltaW = cellfunc(@(x) volwarp(x, warp1, 'backward'), warp2);
    
    % get the overall warp displacement in the reference frame of the first warp image
    finalW = cellfunc(@plus, deltaW, warp1);
    assert(isclean([finalW{:}]));
end
