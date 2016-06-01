function warpsToHTML(strokeInPath, PBROutPath, ANTsOutPath, strokeAtlasPath, saveImagesPath, warpDir)
%% Create outline for every segmentation image

inoutDesiredLabels = [4, 43];
outlineLabels = [4, 43, 3, 42];
[paramsPBR, subjNamesPBR, foldersPBR] = gatherRunParams(PBROutPath);
[paramsANTs, subjNamesANTs, foldersANTs] = gatherRunParams(ANTsOutPath);

% Set up html file
fid = fopen([saveImagesPath, 'outlines.html'],'a');
fprintf(fid, '\n<H1>Outlines</H1>');

for subjectID = 1:numel(subjNamesPBR)
    % determine the number of parameter configurations ran for this subject
    subjectName = subjNamesPBR{subjectID};
    nParamsPBR = sum(paramsPBR(:,1)==subjectID);
    nParamsANTs = sum(paramsANTs(:,1)==subjectID);
    PBRID = find(strncmp(foldersPBR, subjectName, numel(subjectName)));
    PBRID = PBRID(1);
    
    % grab stats to extract nScales and nInnerReps. They should be equal for every run for this subject. 
    stats = load(fullfile(PBROutPath, foldersPBR{PBRID}, '/out/0_0.mat'));
    nScales = stats.params.nScales;
    nInnerReps = stats.params.nInnerReps;
   
    % grab centroid slice for this subject based on ANTs segmentation
    ANTsID = find(strncmp(foldersANTs, subjectName, numel(subjectName)));
    ANTsID = ANTsID(1);
    segANTsnii = loadNii(fullfile(ANTsOutPath, foldersANTs{ANTsID}, '/final/', sprintf('/stroke61-seg-in-%s_via_stroke61-2-%s-warp.nii.gz', subjectName, subjectName)));
    segANTs = ismember(segANTsnii.img, inoutDesiredLabels);
    centroidVal = 0;
    for slice = 1:size(segANTs, 3)
        currentCentroidVal = sum(sum(segANTs(:,:,slice)));
        if currentCentroidVal > centroidVal
            centroid = slice;
            centroidVal = currentCentroidVal;
        end 
    end
    
    % grab the volume ds7us7 and the segmentation
    volNii = loadNii(fullfile(strokeInPath, subjectName, sprintf('/%s_ds7_us7_reg.nii.gz', subjectName)));
    vol = volNii.img;
    segRawPBRnii = loadNii(fullfile(strokeAtlasPath, '/stroke61_seg_proc_ds7_us7.nii.gz'));
    segRawPBR = segRawPBRnii.img;
    
    % Start new row in the HTML file table
    fprintf(fid, ['\n<H2>Subject ', subjectName, ' slice ', num2str(centroid), '</H2>']);
    fprintf(fid, '\n<table style="width:100%%">');
    
    % Start looking at outlines for every scale
    for scale = 1:nScales   
        fprintf(fid, '\n<tr>');
        fprintf(fid, ['\n<td>', 'Scale ', num2str(scale), '</td>']);
        for param = PBRID:nParamsPBR + PBRID - 1        
            % extract stats for this run
            try
                stats = load(fullfile(PBROutPath, foldersPBR{param}, sprintf('/out/%d_%d.mat', scale, nInnerReps)));        
            catch
                warning('Skipping %s', foldersPBR{param});
                continue
            end
            
            % check that nScales and nInnerReps are the same for every run
            if nScales ~= stats.params.nScales
                error('Inconsistent number of scales for subject %s', subjectName);
            end 
            if nInnerReps ~= stats.params.nInnerReps
                error('Inconsistent number of inner loops for subject %s', subjectName);
            end 
            
            % grab the displacement at that scale and upsample it to volume size
            % apply the warp to the atlas segmentation
            displ = stats.displVolumes.cdispl;
            scDispl = resizeWarp(displ, size(vol));
            warpedSeg = volwarp(segRawPBR, scDispl, warpDir);
            warpedSegReduced = ismember(warpedSeg, outlineLabels);
            assert(isequal(size(vol),size(warpedSeg)));
            [rgbImages, ~] = showVolStructures2D(vol(:, :, centroid), warpedSegReduced(:, :, centroid), {'axial'}, 3, 3, 1); %title(strrep(['PBR ', foldersPBR{param}, ' scale ', num2str(scale)], '_', '\_'));
            
            % save image locally in the images directory
            foldername = sprintf('%s/%s_%s', saveImagesPath, 'stroke-PBR', subjectName); mkdir(foldername);
            imgPath = ['stroke-PBR_', subjectName, sprintf('/axial_scale%d_%d.png', scale, centroid)];
            imwrite(rgbImages, fullfile(foldername, sprintf('axial_scale%d_%d.png', scale, centroid)));
            
            % add image to the html file
            fprintf(fid, '\n<td><figure>');
            fprintf(fid, ['\n', '<img src="', imgPath, '" width="300px" />']);
            fprintf(fid, ['\n<figcaption align="bottom">', 'PBR ', foldersPBR{param}, ' scale ', num2str(scale), '</figcaption>']);
            fprintf(fid, '\n</figure></td>');
        end
        if scale == nScales     
            for param = ANTsID : nParamsANTs + ANTsID - 1
                % add the ANTs segmentation result
                segANTsnii = loadNii(fullfile(ANTsOutPath, foldersANTs{param}, '/final/', sprintf('/stroke61-seg-in-%s_via_stroke61-2-%s-warp.nii.gz', subjectName, subjectName)));
                segANTs = ismember(segANTsnii.img, outlineLabels);
                [rgbImages, ~] = showVolStructures2D(vol(:, :, centroid), segANTs(:, :, centroid), {'axial'}, 3, 3, 1); %title(strrep(['ANTs ', foldersANTs{param}], '_', '\_'));
                
                % save the image locally in the images directory
                foldername = sprintf('%s/%s_%s', saveImagesPath, 'stroke-ANTs', subjectName); mkdir(foldername);
                imgPath = ['stroke-ANTs_', subjectName, sprintf('/axial_scale%d_%d.png', scale, centroid)];
                imwrite(rgbImages, fullfile(foldername, sprintf('axial_scale%d_%d.png', scale, centroid)));
                
                % add image to the html file
                fprintf(fid, '\n<td><figure>');
                fprintf(fid, ['\n', '<img src="', imgPath, '" width="300px" />']);
                fprintf(fid, ['\n<figcaption align="bottom">', 'ANTs ', foldersANTs{param}, ' scale ', num2str(scale), '</figcaption>']);
                fprintf(fid, '\n</figure></td>');
            end
        end
        fprintf(fid, '\n</tr>');
    end
    fprintf(fid, '\n</table>');
end
fclose(fid);
end