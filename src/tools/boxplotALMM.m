function h = boxplotALMM(diffs, names, order, colors)

    if nargin == 2
        order = 1:numel(diffs);
    end

    if nargin < 4
        colors = {'r', 'g', 'b', 'w'};
        colors = {[0 0.447 0.741], [0.85 0.325 0.098], [0.466 0.674 0.188], [1 1 1]};
        % colors = {[0.85 0.325 0.098], [0.466 0.774 0.188], [0 0.447 0.741], [1 1 1]};
        % colors = {[0.466 0.774 0.188], [0 0.447 0.741], [0, 0, 0], [1 1 1]};
    end
    
    nSkip = size(diffs{1}, 2);
    nSkip

    set(0,'DefaultTextFontname', 'CMU Serif')
    set(0,'DefaultAxesFontName', 'CMU Serif')
    set(0,'DefaultTextFontname', 'Garamond')
    set(0,'DefaultAxesFontName', 'Garamond')

    h = figuresc(); hold on;
    emptylabels = {};
    for i = 1:numel(order);
        idx = order(i);
        s = size(diffs{idx}, 1);

        for j = 1:(nSkip)
            emptydata = zeros(s, numel(order) * (nSkip+1));
            emptydata(:, (i-1)*(nSkip+1) + j) = diffs{idx}(:, j);

            b = boxplot((emptydata), 'Labels', emptylabels, 'colors', colors{j}, 'symbol', 'k.');
            set(b, 'LineWidth', 3);
            set(findobj(gca, 'Type', 'text'), 'FontSize', 18);
        end
    end
    % TODO; instead of this, do labels directly on the figure/axis afterword at the right spacing.
    plot(-1, -1, 'LineWidth', 3, 'Color', colors{1});
    plot(-1, -1, 'LineWidth', 3, 'Color', colors{2});
    plot(-1, -1, 'LineWidth', 3, 'Color', colors{3});

    ylim([0, 1]);

    mid = floor((nSkip+1)/2) + 1;

    set(gca, 'XTickLabel', []);
    set(gca, 'XTick', []);
    set(gca, 'XTick', mid:(nSkip+1):(numel(order)*(nSkip+1)));
    set(gca, 'XTickLabel', names(order), 'FontSize', 22);
    % legend({'Registration through Atlas', 'Linear model', 'Full Model'}, 'FontSize', 28);
    % legend({'Baseline', 'Linear model', 'Full Model'}, 'FontSize', 28);
