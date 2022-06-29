% Simulation folder
sim_folder = ['../EF5/Outputs/HRRR/'];
% Reference folder
ref_folder = '../EF5/Outputs/baseline_isostorm/';

filelist = dir(fullfile(sim_folder, '*.tif'));

rain_period = datenum(2018,5,27,14,0,0):1/24:datenum('2018-05-28 12:00');

npet_anisotropic = false;

if (npet_anisotropic == true)
	runMode = 'calibrated_anisotropic_valid_at_13';

	weight_par = 100; 
	qpf_x_err = -40; 
	qpf_y_err = 70;
else
	runMode = 'isotropic_valid_at_13'; 

	weight_par = 0; 
	qpf_x_err = 0; 
	qpf_y_err = 0; 
end

radiusL = 150; 
area_par = 0.5;

[DrainArea,~] = geotiffread('auxiliary/DrainArea_1km_mrms_grid.tif');

mapinfo = geotiffinfo('auxiliary/DrainArea_1km_mrms_grid.tif');

% Arbitrary locations for time series
locations_info = readtable('auxiliary/Locations_for_TimeSeries.csv');

loc_lats = locations_info.Latitude; 
loc_lons = locations_info.Longitude; 

ens_prctiles = [0.1, 1, 5, 10, 25, 50, 75, 90, 95, 99, 99.9];

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
	loc(loc_i).loc_ts = nan(1, numel(rain_period));
	loc(loc_i).ref_ts = nan(1, numel(rain_period));
	loc(loc_i).ts_weights = nan(numel(loc(loc_i).pixs), numel(rain_period));

	ensemble_data(loc_i).ts_series = nan(numel(ens_prctiles), numel(rain_period));
	ensemble_data(loc_i).loc_ts = nan(1, numel(rain_period));
	ensemble_data(loc_i).ref_ts = nan(1, numel(rain_period));

	fprintf('Ensemble size for location %f is %f\n', loc_i, numel(loc(loc_i).pixs));
end

% Static weights
base_weights = simple_npet2dwdist(qpf_x_err,qpf_y_err,weight_par,radiusL,1);
for loc_i = 1:4
    loc_weights = base_weights(loc(loc_i).pixs);
    for ens_pct = 1:numel(ens_prctiles)
	ensemble_sizes(loc_i,ens_pct) = numel(loc_weights(loc_weights > prctile(loc_weights(:),ens_prctiles(ens_pct))));
    end
end

% Time loop
for fi = 1:numel(rain_period) 
	[c_file,~] = imread([sim_folder, 'q.', datestr(rain_period(fi), 'yyyymmdd_HHMM'), '.crest.tif']); 
        try
	    [ref_file,~] = imread([ref_folder, 'q.', datestr(rain_period(fi), 'yyyymmdd_HHMM'), '.crest.tif']);
	    fprintf('File found\n');
	    foundFile = true;
        catch ME
            fprintf('No file\n');
	    foundFile = false;
        end

	for loc_i = 1:4
		loc(loc_i).loc_ts(fi) = c_file(loc(loc_i).row,loc(loc_i).col)/locations_info.Barea_km2(loc_i);
		if (foundFile == true)
		  loc(loc_i).ref_ts(fi) = ref_file(loc(loc_i).row,loc(loc_i).col)/locations_info.Barea_km2(loc_i);
		end
		subset_cfile = c_file(loc(loc_i).row-radiusL:loc(loc_i).row+radiusL,loc(loc_i).col-radiusL:loc(loc_i).col+radiusL);	
		weights = nan(size(subset_cfile));
		weights(loc(loc_i).pixs) = base_weights(loc(loc_i).pixs);
    		
		loc(loc_i).ts_weights(:,fi) = weights(loc(loc_i).pixs);
		loc(loc_i).ts_series(:,fi) = subset_cfile(loc(loc_i).pixs)./loc(loc_i).darea_pixs;

		ensemble_data(loc_i).ts_series(:,fi) = weigh_prctile(loc(loc_i).ts_series(:,fi), ens_prctiles, 3, 'weighted', loc(loc_i).ts_weights(:,fi));
		ensemble_data(loc_i).loc_ts(fi) = loc(loc_i).loc_ts(fi);
		ensemble_data(loc_i).ref_ts(fi) = loc(loc_i).ref_ts(fi);
	end
end

% Save MATLAB's binary file with output variables (to be processed further with MATLAB)
save(['../Experiment_Results/npet_hrrr_ensembleData_', runMode, '_selected_locations_r', num2str(radiusL),'km_D_', num2str(area_par*100),'pct.mat'], 'ensemble_data', 'rain_period', 'ens_prctiles', 'ensemble_sizes');

exit;
