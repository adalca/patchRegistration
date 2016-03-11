function outlinesVol = labelOutlines(segVolume, varargin)
% draw outlines of the given labels via the given colors
% defaults for optional arguments:
%   desiredLabels: all > 0
%   colors: seg color
%   
% 
% algo outline:
% init zero volume
% for each desired segmentation
%   get 0/1 mask for that label
%   get bwmask of -mask
%   set all pixels >0 but <= thickness to that color/seg

    % parse inputs
    if ischar(segVolume)
        segVolume = nii2vol(segVolume);
    elseif isstruct(segVolume)
        segVolume = segVolume.img;
    end
    availableLabels = unique(segVolume(:));

    % parse extra inputs
    p = inputParser();
    p.addParameter('desiredLabels', availableLabels, @isvector);
    p.addParameter('thickness', 1, @isscalar);
    p.addParameter('colors', jitter(numel(availableLabels)), @isvector);
    p.parse(varargin{:});
    params = p.Results;

    % initialize edge volume
    outlinesVol = zeros(size(segVolume));

    % go through each desired label
    for i = 1:numel(params.desiredLabels)
        % extract label mask
        label = params.desiredLabels(i);
        mask = segVolume == label;

        % extract inner bw distance
        bw = bwmask(-mask);

        % get edges
        edgeMask = bw > 0 & bw < params.thickness;
        outlinesVol(edgeMask) = label;
    end
