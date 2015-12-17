function plotDICEfinals(IDs, n00, dices, dicelabels, figh, speclabelgroups)
% show a runstep-vs-DICE subplot for each subject

    assert(iscell(speclabelgroups));

    % open figure
    figure(figh); hold on;
    

    % set up boxplot structures
    bpdice = cell(1, numel(speclabelgroups));
    bpgrp = cell(1, numel(speclabelgroups));
    
    title(sprintf('DICE')); hold on;
    for grpidx = 1:numel(speclabelgroups)
        speclabels = speclabelgroups{grpidx};
        
        bpdice{grpidx} = [];
        bpgrp{grpidx} = [];
        
        % go through IDs
        for n = 1:numel(IDs)
        
            % gather dice at each scale
            s = n00{n}.params.nScales;
            i = n00{n}.params.nInnerReps;
            
            % get indexes of particular labels we care about
            [~, labelidx, ~] = intersect(dicelabels{n, s, i}, speclabels);

            % assign dices
            lbp = dices{n, s, i}(labelidx(:))';
            bpdice{grpidx} = [bpdice{grpidx}, lbp];
            bpgrp{grpidx} = [bpgrp{grpidx}, (grpidx) * ones(1, numel(lbp))];
        end
    end
    
    bpdice = cat(2, bpdice{:});
    bpgrp = cat(2, bpgrp{:});

    % show boxplot
    boxplot(bpdice, bpgrp); hold on;
    ylim([0.5, 0.95])
    
end