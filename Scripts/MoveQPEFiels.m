% Get georeference information from sample file
mapinfo = geotiffinfo('b_usa_20160815c.tif');

%% Track configuration
% Spatial parameters
origin_lat = mapinfo.CornerCoords.Lat(1);
origin_lon = mapinfo.CornerCoords.Lon(1);

%% Determined by angle and distance
origin_displacement_km = 100;
rad = km2deg(origin_displacement_km);

fid = fopen(['origin_round_form_distance_enforced_', num2str(origin_displacement_km), 'km.csv'], 'w');
fprintf(fid, 'latitude,longitude,distance(km),direction angle(degrees)\n');
for dir_angle = 0:3:360
    % By mean fdir in degrees
    mean_Xcomponent = cos(deg2rad(dir_angle));
    mean_Ycomponent = sin(deg2rad(dir_angle));
   
    % Convert to degrees
    comp_y = -km2deg(mean_Ycomponent.*origin_displacement_km);
    comp_x = km2deg(mean_Xcomponent.*origin_displacement_km);

    % Mean angle
    main_angle = (atan2(mean_Ycomponent,mean_Xcomponent)*180/pi);
    main_angle(main_angle < 0) = 360 + main_angle;
    
    % Convert to QGIS angle convention (0/360 is North, 90 is East)
    main_angle = main_angle + 90;
    main_angle(main_angle >=360) = main_angle(main_angle >=360) - 360;
    
    dist_from_origin = deg2km(distance(comp_y+origin_lat, comp_x+origin_lon,origin_lat,origin_lon));
    
    while (dist_from_origin < origin_displacement_km)
        comp_y = comp_y.*1.01;
        comp_x = comp_x.*1.01;
        dist_from_origin = deg2km(distance(comp_y+origin_lat, comp_x+origin_lon,origin_lat,origin_lon));
    end
    
    fprintf(fid, '%f,%f,%f,%f\n',comp_y+origin_lat, comp_x+origin_lon, dist_from_origin,main_angle);
end
fclose(fid);
