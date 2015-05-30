function c = mat2cellsplit(mat)
% create a cell the same size as the original mat, and distribute all of the matrix 
% entreies as cell entries.

    sz = size(mat);
    oz = arrayfunc(@(x) ones(x, 1), sz);
    c = mat2cell(mat, oz{:});
    
    
