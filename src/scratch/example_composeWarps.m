function finalWarp = example_composeWarps()
% test for composeWarps
    % setup two warp images
    warp1x = zeros(5, 5);
    warp1y = zeros(5, 5);
    warp2x = zeros(5, 5);
    warp2y = zeros(5, 5);
    
    warp1x(2,2) = 1.5;
    warp1y(2,2) = -0.5;
    
    warp2x(1,3) = 0;
    warp2x(1,4) = 2;
    warp2x(2,3) = 0;
    warp2x(2,4) = 1;
    
    warp2y(1,3) = -0.2;
    warp2y(1,4) = -0.2;
    warp2y(2,3) =-0.1;
    warp2y(2,4) = 0;
    
    finalWarp = composeWarps({warp1y, warp1x}, {warp2y, warp2x});
end
    