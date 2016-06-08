function centroid = centroid3D(vol)
    centroidVal = 0;
    for slice = 1:size(vol, 3)
        currentCentroidVal = sum(sum(vol(:,:,slice)));
        if currentCentroidVal > centroidVal
            centroid = slice;
            centroidVal = currentCentroidVal;
        end 
    end
end