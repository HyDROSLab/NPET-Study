% Object-oriented FF identification

% FLASH
% Baseline run
base_max_unitq = imread('../EF5/Outputs/baseline_isostorm/maxunitq.20180527.190000.tif');
% No Rain Run
no_rain_maxunitq = imread('../EF5/Outputs/baseline_norain/maxunitq.20180527.190000.tif');
no_rain_maxunitq(no_rain_maxunitq<0) = 0;

% Adjust max unit Q grid to exclude signal from precip prior to event
base_max_unitq = base_max_unitq - no_rain_maxunitq; base_max_unitq(base_max_unitq<0) = 0;

mapinfo = geotiffinfo('DrainArea_1km_mrms_grid.tif');

%% Identify FF objects
% Multi-threshold analysis
% Nuance, Minor, Moderate, Major and Catasthropic
levels = 0.35; 
nPix_levels = 40; 

dispL = 25;

% Initiate output file
fid = fopen(['../Experiment_Results/object_oriented_evaluation_', num2str(dispL), 'km.csv'], 'w');
fprintf(fid, 'Angle (degrees), Length (km),Mean Size,N uQ > 1, N uQ > 2, N uQ > 5, mean Error+,max Error+\n');
% Loop through all "forecasts"
for Dlength = dispL
    % Forecast runs folder
    forecast_runs = ['../EF5/Outputs/disp', num2str(Dlength), 'km/'];
    % Perturbation angles
    pertFile = ['../QPEperturbations/disp', num2str(Dlength), 'km/origin_round_form_distance_enforced_', num2str(Dlength), 'km.csv'];
    all_angles = dlmread(pertFile, ',', 1,0);
    for Dangle = all_angles(:,4)'
	max_unitq = imread([forecast_runs, 'angle_', num2str(Dangle, '%.1f'), '/maxunitq.20180527.190000.tif']);
	% Adjust max unit Q grid to exclude signal from precip prior to event
	max_unitq = max_unitq - no_rain_maxunitq; max_unitq(max_unitq<0) = 0;

	% Difference field
	error_field = max_unitq-base_max_unitq;
	mean_positive_error = mean(error_field(error_field > 0));
	max_positive_error = max(error_field(error_field > 0));

	n_moderate = numel(max_unitq(max_unitq > 1));

	n_major = numel(max_unitq(max_unitq > 2));

	n_catastrophic = numel(max_unitq(max_unitq > 5));

	combinedRaster = zeros(size(max_unitq));
	exp_i = 0; 
	objID = 0;
	for level_i = levels
    	    exp_i = exp_i + 1;
   
    	    thisRaster = double(max_unitq > level_i); 
    
    	    this_objects = regionprops(thisRaster > 0, 'Area', 'PixelIdxList');
    	    this_obj_areas = [this_objects.Area];
    	    sel_obj_idxs = find(this_obj_areas >= nPix_levels(exp_i));
    	    for obj_i = 1:numel(sel_obj_idxs)
        	objID = objID + 1;
        	existing_ID = unique(combinedRaster(this_objects(sel_obj_idxs(obj_i)).PixelIdxList));
        	if (existing_ID > 0)
            	    combinedRaster(this_objects(sel_obj_idxs(obj_i)).PixelIdxList) = existing_ID;
        	else
            	    combinedRaster(this_objects(sel_obj_idxs(obj_i)).PixelIdxList) = objID;
        	end
    	    end
	end

	% Extract all objects given multi-threshold analysis
	TH_Lvl = 0;
	N_TH = 0;
	M_THrawObj = regionprops(combinedRaster > TH_Lvl, 'All');
	M_THminSzObj_idx = find([M_THrawObj.Area] > N_TH);
	Obj_sizes = [M_THrawObj.Area];

	mean_obj_sz = mean(Obj_sizes(M_THminSzObj_idx));

	% Output results
	fprintf(fid, '%f,%f,%f,%f,%f,%f,%f,%f\n',Dangle,Dlength,mean_obj_sz,n_moderate,n_major,n_catastrophic,mean_positive_error,max_positive_error);
    end
end
fclose(fid);

exit;
