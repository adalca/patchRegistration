function libidx = disp2corresp(displ, patchSize, refsize) % TODO: add refsizes, rIdx, etc
% TODO: move to patchlib.
%   not yet part of patchlib since unclear what to do with subs that are not integers, etc.


    % 1. go from correspsub to location.
    nd = size2ndgrid(size(displ{1}));
    sub = cellfunc(@plus, nd, displ);

    % 2. get reference grid (full)
    [~, ~, gridsize] = patchlib.grid(refsize, patchSize); % WARNING: ASSUMES SLIDING, OTHERWISE THE SUB2IND below won't work!

    % 3. get index into grid.
    roundcatchsub = cellfunc(@processdispl, sub, mat2cellsplit(gridsize));
    libidx = sub2ind(gridsize, roundcatchsub{:});
end
    
function displx = processdispl(displx, maxsize)
    displx = round(displx);
    displx(displx < 1 | displx > maxsize) = nan;
end
    
