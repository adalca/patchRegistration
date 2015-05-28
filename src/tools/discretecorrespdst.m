function dst = discretecorrespdst(pstr1, pstr2, ~, ~, dvFact, usemex)
% 
    error('do not use me');
    % I'm not sure what this is for and how it''s different from patchlib.correspdst. perhaps to
    % explicitly force "smoothness" (or harder) constraint? (displacements can't overpass one
    % another). Useful in long-range search.

    if nargin <= 4 || isempty(dvFact)
        dvFact = 100;
    end
    
    if nargin <= 5
        usemex = false;
    end

    % extract location 
    loc1 = pstr1.loc;
    loc2 = pstr2.loc;
    locdst = loc2 - loc1;
    assert(all(all(bsxfun(@eq, locdst(1, :), locdst)))); % loc dists should be the same for each dim
    
    % extract displacement.
    disp1 = pstr1.disp;
    disp2 = pstr2.disp;
    
    % method 1. Maybe not correct?
    % dst = pdist2(d1, d2, @(d1, d2) locdstfn(d1, d2, locdst));
    
    % method 2. % there's probably a faster way to implement this with pdist2
    N = size(disp1, 1); % number of patches
    z = zeros(N, N, 3); 
    for i = 1:size(loc1, 2)
        k = bsxfun(@minus, disp2(:, i), disp1(:, i)'); % + locdst(1, i);
        z(:,:,i) = sign(k) * sign(locdst(1, i));
    end
    dst = 1*any(z == -1, 3); % 1 if signs are opposite at any point
    % dst = dst * 3 + 0.001;
    dst(dst == 1) = 100;
    dst = dst'; % Since did 2 - 1
%     assert(all(dst(:) == dst2(:)));

    % add correspondance score
    dst = dst + patchlib.correspdst(pstr1, pstr2, [], [], [], usemex);
           
end


function dst = locdstfn(d1, d2, locdst)
    dispdst = bsxfun(@minus, d2, d1 + locdst);
    a = bsxfun(@times, sign(dispdst), sign(locdst));
    dst = any( a == -1, 2) * inf;
end
