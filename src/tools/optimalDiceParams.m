function [bestParams, bestDices] = optimalDiceParams(params, dices, verbose)
% TODO: might be able to do thismuch faster, see version 2 below.

    nParams = size(params, 2);
    statsfn = @(x) nanmedian(x(:)); % x is a matrix. Perhaps should do smarter stuff here.
    
    % it is probably possible to do this much faster, see version 2 below?
    bestDices = nan(1, nParams);
    bestParams = nan(1, nParams);
    for i = 1:nParams
        uParams = unique(params(:, i));
        mdice = numel(1, uParams);
        for j = 1:numel(uParams) % different parameter options
            pidx = params(:, i) == uParams(j);
            mdice(j) = statsfn(dices(pidx, :));
        end
        [bestDices(i), mi] = max(mdice);
        bestParams(i) = uParams(mi);
    end
    
    uParams = cell(1, nParams);
    for i = 1:nParams
        uParams{i} = unique(params(:, i));
    end
    paramcombos = ndgrid2vec(uParams{:});
    dicet = zeros(1, size(paramcombos, 1));
    for i = 1:size(paramcombos, 1)
        idx = all(bsxfun(@eq, paramcombos(i, :), params), 2);
        dicet(i) = statsfn(dices(idx, :));
    end
    
    [bestDices, bestParamsi] = nanmax(dicet);
    bestParams = paramcombos(bestParamsi, :);
    

    % get optimal parameters - version 2 (this could be much faster?)
    % could even try on one line? where second arg is a cell.
%     for pri = 1:size(params,2)
%         stats = grpstats(dices, params(:, pri), 'mean');
%     end
    
    if verbose
        fprintf('best parameter options are:\n');
        for i = 1:nParams
            fprintf('%f (%f)\n', bestParams(i), bestDices);
        end
        fprintf('\n');
    end