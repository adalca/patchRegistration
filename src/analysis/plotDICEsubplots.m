function plotDICEsubplots(IDs, n00, dices, dicelabels, figh, speclabels)
% show a runstep-vs-DICE subplot for each subject

    % open figure
    figure(figh); hold on;
    
    % go through IDs
    for n = 1:numel(IDs)
        
        % set up subplot and title
        ID = IDs{n};
        subplot(numel(IDs), 1, n); 
        title(sprintf('DICE %s', ID)); hold on;
        
        % set up boxplot structures
        bpdice = cell(1, n00{n}.params.nScales);
        bpgrp = cell(1, n00{n}.params.nScales);
        
        % gather dice at each scale
        for s = 1:n00{n}.params.nScales
            for i = 1:n00{n}.params.nInnerReps
                % get indexes of particular labels we care about
                if exist('speclabels', 'var')
                    [~, labelidx, ~] = intersect(dicelabels{n, s, i}, speclabels);
                else
                    labelidx = 1:numel(dicelabels{n, s, i});
                end
                
                % group index
                grpidx = (s-1)*n00{n}.params.nInnerReps + i;
                
                bpdice{grpidx} = dices{n, s, i}(labelidx);
                bpgrp{grpidx} = (grpidx) * ones(1, numel(bpdice{grpidx}));
            end
        end

        % do a separate box at beginning for original dice
        grpidx = 1;
        if exist('speclabels', 'var')
            [~, labelidx, ~] = intersect(dicelabels{n, n00{n}.params.nScales+1, 1}, speclabels);
        else
            labelidx = 1:numel(dicelabels{n, n00{n}.params.nScales+1, 1});
        end
        bpdice(2:(end+1)) = bpdice;
        bpgrp(2:(end+1)) = bpgrp;
        bpdice{grpidx} = dices{n, n00{n}.params.nScales+1, 1}(labelidx);
        bpgrp{grpidx} = (0) * ones(1, numel(bpdice{grpidx}));

        bpdice = cat(2, bpdice{:});
        bpgrp = cat(2, bpgrp{:});
        
        % show boxplot
        boxplot(bpdice, bpgrp); hold on;
        ylim([0.5, 0.9])

        % draw a line after first box to delineate original dice.
        plot(1.5 * [1, 1], [min(bpdice(:)), max(bpdice(:))]);
    end
    
end