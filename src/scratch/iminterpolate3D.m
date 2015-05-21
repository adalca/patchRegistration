%% Interpolate image
function I = iminterpolate3D(I,sx,sy,sz)
% from demons toolbox


    % Find update points on moving image
    [x,y,z] = ndgrid(0:(size(I,1)-1), 0:(size(I,2)-1), 0:(size(I,3)-1)); % coordinate image
    x_prime = x + sx; % updated x values (1st dim, rows)
    y_prime = y + sy; % updated y values (2nd dim, cols)
    z_prime = z + sz;
    
    % Interpolate updated image
    I = interpn(x,y,z,I,x_prime,y_prime,z_prime,'linear',0); % moving image intensities at updated points
    
end