function [rgbImage, colors] = overlapVolSeg(labelVol, segvolslice, colors, dooutline)
% OVERLAPVOLSEG overlap a 2d intensity slice with a 2d segmentation (or outline) slice
%
% rgbImage = overlapVolSeg(labelVol, segvolslice) overlap a 2D intensity
% slice with a 2D segmentation image and return a RGB image with different
% colors for different labels. Only non-zero segmentations are used. 
% Default color map is based on jitter(), which uses hsv by default.
%
% [rgbImage, colors] = overlapVolSeg(labelVol, segvolslice) also get the
% colors used for non-zero labels.
%
% [rgbImage, ...] = overlapVolSeg(labelVol, segvolslice, colors) allows
% specification of colors to be used for each non-zero label
%
% [rgbImage, ...] = overlapVolSeg(labelVol, segvolslice, colors,
% dooutline) specify boolean dooutline, which if true executes slice-wise
% labelOutline() computation of each label. colors can be [] here, in which
% case the default colors behavior takes over

    % initialize rgb image
    rgbImage = repmat(labelVol, [1,1,3]);
    
    % understand labels
    labels = unique(segvolslice(:));
    labels(labels == 0) = [];
    nLabels = numel(labels);
    
    % prepare colors
    if nargin <= 2 || isempty(colors)
        colors = jitter(nLabels);
    end
    
    % get (2D) outlines if required
    if exist('dooutline', 'var') && dooutline
        segvolslice = labelOutlines(segvolslice);
    end
    segvolslice = repmat(segvolslice, [1, 1, 3]);
    
    % color the rgb image in areas of the labels
    for i = 1:nLabels
        mask = segvolslice == labels(i);
        c = repmat(reshape(colors(i, :), [1, 1, 3]), size(labelVol));
        rgbImage(mask) = c(mask);
    end
    