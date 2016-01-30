function [dst, labels] = jaccard(vol1, vol2, labels)
% Jaccard metric between two volumes
%   
% [dst, labels] = jaccard(vol1, vol2) compute the jaccard metric for each label in the two label volumes
% vol1 and vol2. Volumes should be the same size. dst is a nUniqueLabels-by-1 vector where
% nUniqueLabels is the number of unique labels found in the two volumes, combined. labels is a
% nUniqueLabels-by-1 vector listing the labels used.
% 
% [dst, labels] = jaccard(vol1, vol2, labels) allows the specification of specific label(s) over which
% the dice metric should be computed. dst is then length(labels)-by-1.
%
% Contact: adalca@csail.mit.edu

    % parse inputs
    narginchk(2, 3);
    if nargin < 3 
        labels = unique([vol1(:); vol2(:)]);
    end

    % go through labels
    dst = zeros(numel(labels), 1);
    for i = 1:numel(labels)
        label = labels(i);
        
        % compute the label masks for this label
        vol1bw = vol1(:) == label;
        vol2bw = vol2(:) == label;

        % compute jaccard
        dst(i) = sum(vol1bw & vol2bw) ./ sum(vol1bw | vol2bw);
    end
end 