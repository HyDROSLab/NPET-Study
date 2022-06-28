% March 25, 2020
% Create ensembles using Carlberg et al. (2020) method: systematically shifting precipitation objects 55.5 and 111 km in range separated by 45 deg in azimuth

dispDist = 100;

root_pert_folder = ['../EF5/c2020_method_disp', num2str(dispDist), 'km/'];
sim_folder = ['../EF5/disp', num2str(dispDist), 'km/angle_321.0/'];
ref_folder = '../EF5/baseline_isostorm/'; 

filelist = dir(fullfile(sim_folder, '*.tif'));

rain_period = datenum('2018-05-27 19:20'):1/(24*3):datenum('2018-05-28 08:00');

runMode = ['ose_', num2str(dispDist), 'km'];

% Isotropic NPET parameters
weight_par = 0; 
qpf_x_err = 0; 
qpf_y_err = 0; 
radiusL = 150; 
area_par = 0.25;

ens_prctiles = [0.1, 1, 5, 10, 25, 50, 75, 90, 95, 99, 99.9];

[DrainArea,~] = geotiffread('DrainArea_1km_mrms_grid.tif');

mapinfo = geotiffinfo('DrainArea_1km_mrms_grid.tif');

%Arbitrary locations for time series
locations_info = readtable('Locations_for_TimeSeries.csv');

loc_lats = locations_info.Latitude; 
loc_lons = locations_info.Longitude; 

% Pre-allocate variables
for loc_i = 1:4
	[loc(loc_i).row,loc(loc_i).col] = latlon2pix(mapinfo.RefMatrix, loc_lats(loc_i), loc_lons(loc_i));
	loc(loc_i).row = round(loc(loc_i).row);
	loc(loc_i).col = round(loc(loc_i).col);
	loc(loc_i).darea = DrainArea(loc(loc_i).row,loc(loc_i).col);
	radiusDA = DrainArea(loc(loc_i).row-radiusL:loc(loc_i).row+radiusL,loc(loc_i).col-radiusL:loc(loc_i).col+radiusL);
	loc(loc_i).pixs = find(radiusDA > loc(loc_i).darea*(1-area_par) & radiusDA < loc(loc_i).darea*(1+area_par));
	loc(loc_i).darea_pixs = radiusDA(loc(loc_i).pixs);
	loc(loc_i).ts_series = nan(numel(loc(loc_i).pixs), numel(rain_period));
	loc(loc_i).ref_ts = nan(1, numel(rain_period));
	loc(loc_i).loc_ts = nan(1, numel(rain_period));
	loc(loc_i).ts_weights = nan(numel(loc(loc_i).pixs), numel(rain_period));

	ensemble_data(loc_i).ts_series = nan(numel(ens_prctiles), numel(rain_period));
        ensemble_data(loc_i).loc_ts = nan(1, numel(rain_period));
	ensemble_data(loc_i).ref_ts = nan(1, numel(rain_period));

	c2020_ensemble_data(loc_i).ts_series = nan(8, numel(rain_period));

	fprintf('Ensemble size for location %f is %f\n', loc_i, numel(loc(loc_i).pixs));
end

% Pre-compute NPET neighborhood
base_weights = simple_npet2dwdist(qpf_x_err,qpf_y_err,weight_par,radiusL,1,false);

for fi = 1:numel(rain_period) %filelist)
	fprintf('%f files of %f total\n', fi, numel(rain_period));
	[c_file,~] = imread([sim_folder, 'q.', datestr(rain_period(fi), 'yyyymmdd_HHMM'), '.crest.tif']); 
	[ref_file,~] = imread([ref_folder, 'q.', datestr(rain_period(fi), 'yyyymmdd_HHMM'), '.crest.tif']); 

	% ----- NPET -----
	for loc_i = 1:4
		loc(loc_i).ref_ts(fi) = ref_file(loc(loc_i).row,loc(loc_i).col)/locations_info.Barea_km2(loc_i);
		loc(loc_i).loc_ts(fi) = c_file(loc(loc_i).row,loc(loc_i).col)/locations_info.Barea_km2(loc_i);
		subset_cfile = c_file(loc(loc_i).row-radiusL:loc(loc_i).row+radiusL,loc(loc_i).col-radiusL:loc(loc_i).col+radiusL);	
		weights = nan(size(subset_cfile));
		weights(loc(loc_i).pixs) = base_weights(loc(loc_i).pixs);
		loc(loc_i).ts_weights(:,fi) = weights(loc(loc_i).pixs);
		loc(loc_i).ts_series(:,fi) = subset_cfile(loc(loc_i).pixs)./loc(loc_i).darea_pixs;

		ensemble_data(loc_i).ts_series(:,fi) = weigh_prctile(loc(loc_i).ts_series(:,fi), ens_prctiles, 3, 'weighted', loc(loc_i).ts_weights(:,fi));
                ensemble_data(loc_i).loc_ts(fi) = loc(loc_i).loc_ts(fi);
		ensemble_data(loc_i).ref_ts(fi) = loc(loc_i).ref_ts(fi);
	end
	% ----- NPET ------

	% -------C2020 method-----
	cont_mem = 0;
	for Pangle = 0:45:360-45
	    cont_mem = cont_mem + 1;

	    % Read perturbation angle
	    [p_file,~] = imread([root_pert_folder, 'angle_', num2str(Pangle),'.0/q.', datestr(rain_period(fi), 'yyyymmdd_HHMM'), '.crest.tif']);

	    for loc_i = 1:4
	        c2020_ensemble_data(loc_i).ts_series(cont_mem,fi) = p_file(loc(loc_i).row,loc(loc_i).col)/locations_info.Barea_km2(loc_i);
	    end    
	end
	 % -------C2020 method-----
end

save(['extended_45deg_npet_vs_c2020_method_ensembleData_', runMode, '_selected_locations_ts_only_within_', num2str(radiusL),'km_with_areas_within_', num2str(area_par*100),'pct.mat'], 'ensemble_data', 'c2020_ensemble_data', 'rain_period', 'ens_prctiles');

exit;
