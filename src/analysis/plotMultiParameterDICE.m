function plotMultiParameterDICE(params, dices, dicelabels, diceLabelNames, paramNames)
% for each parameter, 
% plot DICEs of parameters, 
% similar to how plotAllDICE works now, but without the gathering part.

% include clear labels of axes, etc.

for param = 1:size(params,2)
    f = figure();
    [nRows, nCols] = subgrid(numel(dicelabels));
    for labelIdx = 1:numel(dicelabels)
        subplot(nRows, nCols, labelIdx);
        boxplot(dices(:, labelIdx), params(:, param)); hold on; grid on;
        ylim([0.3, 1]);
    end
    
    ax = findobj(f,'Type','Axes');
    for i=1:length(ax)
        if nargin==5
            title(ax(i), diceLabelNames{ax-i+1})
        else 
            title(ax(i), dicelabels(length(ax)-i+1))
        end
    end
end

params = repmat(params, [size(dices, 2) ,1]);
dices = reshape(dices, [numel(dices),1]);  

for param = 1:size(params,2)
    figure();
    boxplot(dices, params(:, param)); hold on; grid on;
    ylim([0.3, 1]);
end