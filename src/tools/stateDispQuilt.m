function vol = stateDispQuilt(pDst, patchSize, patchOverlap, gridSize)
% Create new patches from the existent patch distances
% Run quilt on these new patches to get a volume

    % Setup parameters
    pDstSize = size(pDst);
    N = pDstSize(1);
    patchElem = pDstSize(2);
    patchSize = [patchSize, prod(patchSize)];
    
    % Recreate the patch matrix. Copy pDist along another dimension then
    % reshape it one dimension bellow to get a conglomerate volume. 
    newPdst = repmat(pDst, 1, 1, patchElem);
    newPdst = permute(newPdst, [1, 3, 2]);
    newPdst = reshape(newPdst, N, patchElem^2);
    
    % the vote function for quilt
    votefn = @(x) nth_output_max(2, x);
    
    vol = patchlib.quilt(newPdst, [gridSize, 1], patchSize, patchOverlap, 'voteAggregator', votefn);
end
  
% function for obtaining the Nth output from the max function
function value = nth_output_max(N, X)
    [value{1:N}] = max(prod(X, 1), [], ndims(X));
    value = value{N};
end