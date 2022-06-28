hour = '13';
sim_folder = ['/hydros/humberva/PROFLASH/NPET/HRRRv3_Cases/EllicotCity/20180527', hour, '00/'];

filelist = dir(fullfile(sim_folder, '*.tif'));

rain_period = datenum(2018,5,27,str2double(hour)+1,0,0):1/24:datenum('2018-05-28 12:00');

%runMode = ['isotropic_valid_at_', hour];
runMode = ['calibrated_anisotropic_valid_at_', hour];

weight_par = 100; %15;
qpf_x_err = -40; %-68.8292; %-103.2438; %0;
qpf_y_err = 70; %98.2982; %147.4474; %0;
radiusL = 150; %220;
area_par = 0.5;

% base_weights1 = npet2dwdist(-68.8292,98.2982,40,150,1,false,false);

[DrainArea,~] = geotiffread('/hydros/humberva/CONUS_Datasets/Geophysical_Variables/Hydrologic_Spatial_Variability_Algorithms/Geomorphology/DrainArea_1km_mrms_grid.tif');

mapinfo = geotiffinfo('/hydros/humberva/CONUS_Datasets/Geophysical_Variables/Hydrologic_Spatial_Variability_Algorithms/Geomorphology/DrainArea_1km_mrms_grid.tif');

%Arbitrary locations for time series
locations_info = readtable('Locations_for_TimeSeries.csv');

loc_lats = locations_info.Latitude; 
loc_lons = locations_info.Longitude; 

ens_prctiles = [0.1, 1, 5, 10, 25, 50, 75, 90, 95, 99, 99.9];

for loc_i = 1:4
	[loc(loc_i).row,loc(loc_i).col] = latlon2pix(mapinfo.RefMatrix, loc_lats(loc_i), loc_lons(loc_i));
	loc(loc_i).row = round(loc(loc_i).row);
	loc(loc_i).col = round(loc(loc_i).col);
	loc(loc_i).darea = DrainArea(loc(loc_i).row,loc(loc_i).col);
	radiusDA = DrainArea(loc(loc_i).row-radiusL:loc(loc_i).row+radiusL,loc(loc_i).col-radiusL:loc(loc_i).col+radiusL);
	loc(loc_i).pixs = find(radiusDA > loc(loc_i).darea*(1-area_par) & radiusDA < loc(loc_i).darea*(1+area_par));
	loc(loc_i).darea_pixs = radiusDA(loc(loc_i).pixs);
	loc(loc_i).ts_series = nan(numel(loc(loc_i).pixs), numel(rain_period));
	loc(loc_i).loc_ts = nan(1, numel(rain_period));
	loc(loc_i).ts_weights = nan(numel(loc(loc_i).pixs), numel(rain_period));

	ensemble_data(loc_i).ts_series = nan(numel(ens_prctiles), numel(rain_period));
	ensemble_data(loc_i).loc_ts = nan(1, numel(rain_period));
end
%Static weights
base_weights = simple_npet2dwdist(qpf_x_err,qpf_y_err,weight_par,radiusL,1,false);

for loc_i = 1:4
    loc_weights = base_weights(loc(loc_i).pixs);
    for ens_pct = 1:numel(ens_prctiles)
	ensemble_sizes(loc_i,ens_pct) = numel(loc_weights(loc_weights > prctile(loc_weights(:),ens_prctiles(ens_pct))));
    end
end

for fi = 1:numel(rain_period) %filelist)
	[c_file,~] = imread([sim_folder, 'q.', datestr(rain_period(fi), 'yyyymmdd_HHMM'), '.crest.tif']); %filelist(fi).name]);
	
	%Static weights
	%base_weights = simple_npet2dwdist(qpf_x_err,qpf_y_err,weight_par,radiusL,1,false);

	for loc_i = 1:4
		loc(loc_i).loc_ts(fi) = c_file(loc(loc_i).row,loc(loc_i).col)/locations_info.Barea_km2(loc_i);
		subset_cfile = c_file(loc(loc_i).row-radiusL:loc(loc_i).row+radiusL,loc(loc_i).col-radiusL:loc(loc_i).col+radiusL);	
		weights = nan(size(subset_cfile));
		weights(loc(loc_i).pixs) = base_weights(loc(loc_i).pixs);
    		%weights = weights./nansum(weights(:));
		loc(loc_i).ts_weights(:,fi) = weights(loc(loc_i).pixs);
		loc(loc_i).ts_series(:,fi) = subset_cfile(loc(loc_i).pixs)./loc(loc_i).darea_pixs;

		ensemble_data(loc_i).ts_series(:,fi) = weigh_prctile(loc(loc_i).ts_series(:,fi), ens_prctiles, 3, 'weighted', loc(loc_i).ts_weights(:,fi));
		ensemble_data(loc_i).loc_ts(fi) = loc(loc_i).loc_ts(fi);

	end

	%weight_par = weight_par - 0.75; %0.25;
end

%save(['hrrr_npet2_ensembles_', runMode, '_selected_locations_ts_only_within_', num2str(radiusL),'km_with_areas_within_', num2str(area_par*100),'pct.mat'], 'loc', 'loc_lats', 'loc_lons');

save(['hrrr_npet2_ensembleData_', runMode, '_selected_locations_ts_only_within_', num2str(radiusL),'km_with_areas_within_', num2str(area_par*100),'pct.mat'], 'ensemble_data', 'rain_period', 'ens_prctiles', 'ensemble_sizes');

exit;
