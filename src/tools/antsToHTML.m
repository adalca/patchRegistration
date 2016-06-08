function antsToHTML(ANTsOutPath, strokeInPath, saveImagesPath)
%% Create outline for every segmentation image

inoutDesiredLabels = [4, 43];
outlineLabels = [4, 43, 3, 42];
[paramsANTs, subjNamesANTs, foldersANTs] = gatherRunParams(ANTsOutPath);
color = [ 0.8500, 0.3250, 0.0980];

% Set up html file
mkdir(saveImagesPath);
mkdir([ANTsOutPath, 'html/']);
fid = fopen([ANTsOutPath, 'html/allANTS.html'],'w');
fprintf(fid, '\n<H1>Outlines</H1>');
imgWidth = 300;

for subjectID = 1:numel(subjNamesANTs)
    % determine the number of parameter configurations ran for this subject
    subjectName = subjNamesANTs{subjectID};
    nParamsANTs = sum(paramsANTs(:,1)==subjectID);
  
    % grab centroid slice for this subject based on ANTs segmentation
    ANTsID = find(strncmp(foldersANTs, subjectName, numel(subjectName)));
    ANTsID = ANTsID(1);
    
    for i = ANTsID : (nParamsANTs + ANTsID - 1)
        try
            segANTsnii = loadNii(fullfile(ANTsOutPath, foldersANTs{i}, '/final/', sprintf('/stroke61-seg-in-%s_via_stroke61-2-%s-warp.nii.gz', subjectName, subjectName)));
            break;
        catch 
        end
    end
    if i == (nParamsANTs + ANTsID - 1)
        warning('Skipping %s', subjectName);
        continue
    end
    segANTs = ismember(segANTsnii.img, inoutDesiredLabels);
    centroid = centroid3D(segANTs);
    
    % grab the volume ds7us7 and the segmentation
    volNii = loadNii(fullfile(strokeInPath, subjectName, sprintf('/%s_ds7_us7_reg.nii.gz', subjectName)));
    vol = volNii.img;
    
    % Start new row in the HTML file table
    fprintf(fid, ['\n<H2>Subject ', subjectName, ' slice ', num2str(centroid), '</H2>']);
    fprintf(fid, '\n<table style="width:100%%">');
    
    for param = ANTsID : (nParamsANTs + ANTsID - 1)
        % add the ANTs segmentation result
        segANTsnii = loadNii(fullfile(ANTsOutPath, foldersANTs{param}, '/final/', sprintf('/stroke61-seg-in-%s_via_stroke61-2-%s-warp.nii.gz', subjectName, subjectName)));
        segANTs = ismember(segANTsnii.img, outlineLabels);
        [rgbImages, ~] = showVolStructures2D(vol(:, :, centroid), segANTs(:, :, centroid), {'axial'}, 3, 3, 1, color);

        % save the image locally in the images directory
        imgHeight = imgWidth * size(rgbImages, 1)/size(rgbImages,2);
        rgbImages = volresize(rgbImages, [imgHeight, imgWidth, 3], 'nearest');
        foldername = sprintf('%s/%s_%s', saveImagesPath, 'stroke-ANTs', foldersANTs{param}); mkdir(foldername);
        imgPath = ['../../../images/stroke-ANTs_', foldersANTs{param}, sprintf('/axial_%d.png', centroid)];
        imwrite(rgbImages, fullfile(foldername, sprintf('axial_%d.png', centroid)));

        % add image to the html file
        fprintf(fid, '\n<td><figure>');
        fprintf(fid, ['\n', '<img src="', imgPath, sprintf('" width="%spx" height="%spx" />', num2str(imgWidth), num2str(imgHeight))]);
        fprintf(fid, ['\n<figcaption align="bottom">', 'ANTs ', foldersANTs{param}, '</figcaption>']);
        fprintf(fid, '\n</figure></td>');
    end
    fprintf(fid, '\n</table>');
end
fclose(fid);
end