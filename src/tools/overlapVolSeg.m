function [rgbImage, colors] = overlapVolSeg(labelVol, segVol, labels, colors, thickness)
% OVERLAPVOLSEG overlap a 2d intensity slice with a 2d segmentation (or outline) slice
%
% rgbImage = overlapVolSeg(labelVol, segvolslice) overlap a 2D intensity
% slice with a 2D segmentation image and return a RGB image with different
% colors for different labels. Only non-zero segmentations are used.
% Default color map is based on jitter(), which uses hsv by default. % if
% given a 3D volume, function returns a 4D volume of size X-by-Y-by-3-by-Z
%
% [rgbImage, colors] = overlapVolSeg(labelVol, segvolslice) also get the
% colors used for non-zero labels.
%
% [rgbImage, ...] = overlapVolSeg(labelVol, segvolslice, colors) allows
% specification of colors to be used for each non-zero label
%
% [rgbImage, ...] = overlapVolSeg(labelVol, segvolslice, colors, labels,
% thickness) specify thickness, which if true executes slice-wise
% labelOutline() computation of each label. colors can be [] here, in which
% case the default colors behavior takes over

    % understand labels
    if ~exist('labels', 'var') || isempty(labels)
        labels = unique(segVol(:));
        labels(labels == 0) = [];
    end
    nLabels = numel(labels);
    
    % prepare colors
    if nargin <= 3 || isempty(colors)
        colors = jitter(nLabels, @parula);
    end
        
    % color the rgb image in areas of the labels
    rgbImages = cell(size(labelVol, 3), 1);
    for zi = 1:size(labelVol, 3)
        volslice = labelVol(:, :, zi);
        segslice = segVol(:, :, zi);
        
        % get (2D) outlines if required
        if exist('thickness', 'var') && thickness > 0
            segslice = labelOutlines(segslice, 'thickness', thickness);
        end
        segslice = repmat(segslice, [1, 1, 3]);
        
        % make an rgb image out of this slice
        rgbImages{zi} = repmat(volslice, [1, 1, 3]);
        for i = 1:nLabels
            mask = segslice == labels(i);
            c = repmat(reshape(colors(i, :), [1, 1, 3]), size(volslice));
            rgbImages{zi}(mask) = c(mask);
        end
    end
    rgbImage = cat(4, rgbImages{:});    
end
