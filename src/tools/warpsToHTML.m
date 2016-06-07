function warpsToHTML(strokeInPath, PBROutPath, ANTsOutPath, strokeAtlasPath, saveImagesPath, warpDir, verbose)
%% Create outline for every segmentation image

inoutDesiredLabels = [4, 43];
outlineLabels = [4, 43, 3, 42];
[paramsPBR, subjNamesPBR, foldersPBR] = gatherRunParams(PBROutPath);
[paramsANTs, subjNamesANTs, foldersANTs] = gatherRunParams(ANTsOutPath);
scalefn = @(sc) sc + 1;
color = [ 0.8500, 0.3250, 0.0980];

% Set up html file
mkdir(saveImagesPath);
mkdir([PBROutPath, 'html/']);
fid = fopen([PBROutPath, 'html/outlines.html'],'w');
fprintf(fid, '\n<H1>Outlines</H1>');
imgWidth = 300;

for subjectID = 1:numel(subjNamesPBR)
    % determine the number of parameter configurations ran for this subject
    subjectName = subjNamesPBR{subjectID};
    nParamsPBR = sum(paramsPBR(:,1)==subjectID);
    nParamsANTs = sum(paramsANTs(:,1)==subjectID);
    PBRID = find(strncmp(foldersPBR, subjectName, numel(subjectName)));
    PBRID = PBRID(1);
    
    % grab stats to extract nScales and nInnerReps. They should be equal for every run for this subject. 
    for i = PBRID:(nParamsPBR + PBRID - 1) 
        try
            stats = load(fullfile(PBROutPath, foldersPBR{i}, '/out/0_0.mat'));
            break;
        catch 
            if i == (nParamsPBR + PBRID - 1) 
                warning('Skipping %s', foldersPBR{subjectID});
                continue
            end
        end
    end
            
    nScales = stats.params.nScales;
    nInnerReps = stats.params.nInnerReps;
   
    % grab centroid slice for this subject based on ANTs segmentation
    ANTsID = find(strncmp(foldersANTs, subjectName, numel(subjectName)));
    ANTsID = ANTsID(1);
    segANTsnii = loadNii(fullfile(ANTsOutPath, foldersANTs{ANTsID}, '/final/', sprintf('/stroke61-seg-in-%s_via_stroke61-2-%s-warp.nii.gz', subjectName, subjectName)));
    segANTs = ismember(segANTsnii.img, inoutDesiredLabels);
    centroid = centroid3D(segANTs);
    
    % grab the volume ds7us7 and the segmentation
    volNii = loadNii(fullfile(strokeInPath, subjectName, sprintf('/%s_ds7_us7_reg.nii.gz', subjectName)));
    vol = volNii.img;
    segPBRnii = loadNii(fullfile(strokeAtlasPath, '/stroke61_seg_proc_ds7_us7.nii.gz'));
    segPBR = segPBRnii.img;
    
    % Start new row in the HTML file table
    fprintf(fid, ['\n<H2>Subject ', subjectName, ' slice ', num2str(centroid), '</H2>']);
    fprintf(fid, '\n<table style="width:100%%">');
    
    % Start looking at outlines for every scale
    for scale = 1:nScales   
        fprintf(fid, '\n<tr>');
        fprintf(fid, ['\n<td>', 'Scale ', num2str(scale), '</td>']);
        for param = PBRID:(nParamsPBR + PBRID - 1)        
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
            warpedSeg = volwarp(segPBR, scDispl, warpDir, 'interpMethod', 'nearest');
            warpedSegReduced = ismember(warpedSeg, outlineLabels);
            assert(isequal(size(vol),size(warpedSeg)));
            [rgbImages, ~] = showVolStructures2D(vol(:, :, centroid), warpedSegReduced(:, :, centroid), {'axial'}, 3, 3, 1, color); %title(strrep(['PBR ', foldersPBR{param}, ' scale ', num2str(scale)], '_', '\_'));     
            
            % save image locally in the images directory
            imgHeight = imgWidth * size(rgbImages, 1)/size(rgbImages,2);
            rgbImages = volresize(rgbImages, [imgHeight, imgWidth, 3], 'nearest');
            foldername = sprintf('%s/%s_%s', saveImagesPath, 'stroke-PBR', foldersPBR{param}); mkdir(foldername);
            imgPath = ['../../../images/stroke-PBR_', foldersPBR{param}, sprintf('/axial_scale%d_%d.png', scale, centroid)];
            imwrite(rgbImages, fullfile(foldername, sprintf('axial_scale%d_%d.png', scale, centroid)));
            
            % add image to the html file
            fprintf(fid, '\n<td><figure>');
            fprintf(fid, ['\n', '<img src="', imgPath, sprintf('" width="%spx" height="%spx" />', num2str(imgWidth), num2str(imgHeight))]);
            fprintf(fid, ['\n<figcaption align="bottom">', 'PBR ', foldersPBR{param}, ' scale ', num2str(scale), '</figcaption>']);
            fprintf(fid, '\n</figure></td>');
            
            % if verbose, save and post the small scale version too
            if verbose
                % use small volume and segmentation
                scVolnii = loadNii(fullfile(strokeInPath, subjectName, sprintf('/%s_ds7_us%s_reg.nii.gz', subjectName, num2str(scalefn(scale)))));
                scVol = scVolnii.img;
                scSegPBRnii = loadNii(fullfile(strokeAtlasPath, sprintf('/stroke61_seg_proc_ds7_us%s.nii.gz', num2str(scalefn(scale)))));
                scSegPBR = scSegPBRnii.img;
                %scSegPBR = volresize(segPBR, size(scVol), 'nearest');
                % approximate centroid for this new scale
                scSegANTs = volresize(segANTs, size(scSegPBR), 'nearest');
                scCentroid = centroid3D(scSegANTs);
                
                warpedSeg = volwarp(scSegPBR, displ, warpDir, 'interpMethod', 'nearest');
                warpedSegReduced = ismember(warpedSeg, outlineLabels);
                assert(isequal(size(scVol),size(warpedSeg)));
                [rgbImages, ~] = showVolStructures2D(scVol(:, :, scCentroid), warpedSegReduced(:, :, scCentroid), {'axial'}, 3, 1, 1, [], 'nearest'); %title(strrep(['PBR ', foldersPBR{param}, ' scale ', num2str(scale)], '_', '\_'));
                
                % save image locally in the images directory
                imgHeight = imgWidth * size(rgbImages, 1)/size(rgbImages,2);
                rgbImages = volresize(rgbImages, [imgHeight, imgWidth, 3], 'nearest');
                imgPath = ['../../../images/stroke-PBR_', foldersPBR{param}, sprintf('/axial_scale%d_%d-small.png', scale, scCentroid)];
                imwrite(rgbImages, fullfile(foldername, sprintf('axial_scale%d_%d-small.png', scale, scCentroid)));

                % add image to the html file
                fprintf(fid, '\n<td><figure>');
                fprintf(fid, ['\n', '<img src="', imgPath, sprintf('" width="%spx" height="%spx" />', num2str(imgWidth), num2str(imgHeight))]);
                fprintf(fid, ['\n<figcaption align="bottom">', 'PBR ', foldersPBR{param}, ' scale ', num2str(scale), ' small </figcaption>']);
                fprintf(fid, '\n</figure></td>');
            end 
        end
        
        if scale == nScales     
            for param = ANTsID : (nParamsANTs + ANTsID - 1)
                % add the ANTs segmentation result
                segANTsnii = loadNii(fullfile(ANTsOutPath, foldersANTs{param}, '/final/', sprintf('/stroke61-seg-in-%s_via_stroke61-2-%s-warp.nii.gz', subjectName, subjectName)));
                segANTs = ismember(segANTsnii.img, outlineLabels);
                [rgbImages, ~] = showVolStructures2D(vol(:, :, centroid), segANTs(:, :, centroid), {'axial'}, 3, 3, 1); %title(strrep(['ANTs ', foldersANTs{param}], '_', '\_'));
                
                % save the image locally in the images directory
                imgHeight = imgWidth * size(rgbImages, 1)/size(rgbImages,2);
                rgbImages = volresize(rgbImages, [imgHeight, imgWidth, 3], 'nearest');
                foldername = sprintf('%s/%s_%s', saveImagesPath, 'stroke-ANTs', foldersANTs{param}); mkdir(foldername);
                imgPath = ['../../../images/stroke-ANTs_', foldersANTs{param}, sprintf('/axial_scale%d_%d.png', scale, centroid)];
                imwrite(rgbImages, fullfile(foldername, sprintf('axial_scale%d_%d.png', scale, centroid)));
                
                % add image to the html file
                fprintf(fid, '\n<td><figure>');
                fprintf(fid, ['\n', '<img src="', imgPath, sprintf('" width="%spx" height="%spx" />', num2str(imgWidth), num2str(imgHeight))]);
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