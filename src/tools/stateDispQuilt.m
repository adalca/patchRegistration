function vol = stateDispQuilt(pDst, patchSize, patchOverlap, gridSize)
% Create new patches from the existent patch distances
% Run quilt on these new patches to get a volume
%
% pDst = rand(36, 9);
% patchSize = [3, 3];
% patchOverlap = 'sliding';
% gridSize = [6, 6];
% vol = stateDispQuilt(pDst, patchSize, patchOverlap, gridSize)

    % Setup parameters
    pDstSize = size(pDst);
    N = pDstSize(1);
    patchElem = pDstSize(2);
    newPatchSize = [patchSize, prod(patchSize)];
        
    % Recreate the patch matrix. Copy pDist along another dimension then
    % reshape it one dimension bellow to get a conglomerate volume. 
    newPdst = repmat(pDst, 1, 1, patchElem);
    newPdst = permute(newPdst, [1, 3, 2]);

    % blur kernel along the new dimension
    filter = gaussianblob(patchSize, 1);
    newPdst = bsxfun(@times, newPdst, filter(:)');

    % reshape to N x newPatchSize
    newPdst = reshape(newPdst, N, patchElem^2);

    % the vote function for quilt
    votefn = @(x) nth_output_max(2, x, patchSize);
    
    vol = patchlib.quilt(newPdst, [gridSize, 1], newPatchSize, [patchOverlap, 1], 'voteAggregator', votefn);
end
  
function product = nanprod(varargin)
    varargin{1}(isnan(varargin{1})) = 1;
    product = prod(varargin{:});
end

% function for obtaining the Nth output from the max function
function value = nth_output_max(N, X, patchSize)
    
    multvotes = nanprod(X, 1);
%     [value{1:N}] = max(multvotes, [], ndims(X));
%     valuea = value{N};

    % blur displacement patch multvotes and then take max
    sz = size(multvotes);
    m = reshape(multvotes, [nanprod(sz(1:end-1)), patchSize]);
    q = cellfunc(@(x) volblur(x, 1, patchSize), cellfunc(@(x) squeeze(x), dimsplit(1, m)));
    q = cellfunc(@(x) reshape(x, [1 size(x)]), q);
    q = reshape(cat(1, q{:}), sz);
    
    % take max
    [value{1:N}] = max(q, [], ndims(X));
    value = value{N};
end

function h = gaussianblob(patchSize, sigma) 
% gaussian blob of size patchSize

    range = arrayfunc(@(x) -x:x, (patchSize-1)/2);
    grid = cellfunc(@(x) x(:), ndgrid2cell(range{:}));
    grid = cat(2, grid{:});
    h = exp(-sum(grid.*grid, 2)/(2*sigma.^2));
end
