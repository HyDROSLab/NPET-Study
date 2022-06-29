% Get georeference information from sample file
mapinfo = geotiffinfo('auxiliary/DrainArea_1km_mrms_grid.tif');

%% Track configuration
% Spatial parameters
origin_lat = mapinfo.CornerCoords.Lat(1);
origin_lon = mapinfo.CornerCoords.Lon(1);

%% Determined by angle and distance
origin_displacement_km = 25;
rad = km2deg(origin_displacement_km);

fid = fopen(['../QPEperturbations/disp', num2str(origin_displacement_km), 'km/origin_round_form_distance_enforced_', num2str(origin_displacement_km), 'km.csv'], 'w');
fprintf(fid, 'latitude,longitude,distance(km),direction angle(degrees)\n');
for azimuth_angle = 0:3:357
    % Convert to MATLAB's convention
    dir_angle = -(azimuth_angle-90);

    % By mean fdir in degrees
    mean_Xcomponent = cos(deg2rad(dir_angle));
    mean_Ycomponent = sin(deg2rad(dir_angle));
   
    % Convert to degrees
    comp_y = km2deg(mean_Ycomponent.*origin_displacement_km);
    comp_x = km2deg(mean_Xcomponent.*origin_displacement_km);

    dist_from_origin = deg2km(distance(comp_y+origin_lat, comp_x+origin_lon,origin_lat,origin_lon));
    
    while (dist_from_origin < origin_displacement_km)
        comp_y = comp_y.*1.01;
        comp_x = comp_x.*1.01;
        dist_from_origin = deg2km(distance(comp_y+origin_lat, comp_x+origin_lon,origin_lat,origin_lon));
    end
    
    fprintf(fid, '%f,%f,%f,%f\n',comp_y+origin_lat, comp_x+origin_lon, dist_from_origin,azimuth_angle);
end
fclose(fid);

exit;
