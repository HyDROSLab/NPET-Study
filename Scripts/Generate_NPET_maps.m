% Apply NPET on Maximum Unit Streamflow Maps
% Lines 98-101 allow for customization of NPET for the OSE experiments.
c2020_analysis = false; % OSE experiment
npet_analysis = false; % OSE experiment
hrrr_npet_analysis = true; npet_hybrid = true; % HRRR demo

% FLASH
% Baseline run
base_max_unitq = imread('../EF5/Outputs/baseline_isostorm/maxunitq.20180527.190000.tif');
% No Rain Run
no_rain_maxunitq = imread('../EF5/Outputs/baseline_norain/maxunitq.20180527.190000.tif');
no_rain_maxunitq(no_rain_maxunitq<0) = 0;

% Adjust max unit Q grid to exclude signal from precip prior to event
base_max_unitq = base_max_unitq - no_rain_maxunitq; base_max_unitq(base_max_unitq<0) = 0;

% FORECAST RUN
if (npet_analysis == true)
  max_unitq = imread('../EF5/Outputs/disp100km/angle_321.0/maxunitq.20180527.190000.tif');
  max_unitq = max_unitq - no_rain_maxunitq; max_unitq(max_unitq<0) = 0;
end

if (hrrr_npet_analysis == true)
  max_unitq = imread('../EF5/Outputs/HRRR/maxunitq.20180527.130000.tif');
  %max_unitq = max_unitq - no_rain_maxunitq; max_unitq(max_unitq<0) = 0;
end

mapinfo = geotiffinfo('auxiliary/DrainArea_1km_mrms_grid.tif');
drain_area = imread('auxiliary/DrainArea_1km_mrms_grid.tif');

% Colormap for unit streamflow maps (as used in FLASH demo system)
load('auxiliary/flashweb_unitQ_colormap_linearScale_manually_calibrated.mat');

% US States boundaries
load('auxiliary/US_States_boundaries.mat');

% Pre-defined domain (analysis domain)
domain.minX = 5114; domain.maxX = 5812;
domain.minY = 1398; domain.maxY = 1757;

%% Identify FF objects
levels = 0.35;
nPix_levels = 40;

combinedRaster = zeros(size(base_max_unitq));
exp_i = 0;
objID = 0;
for level_i = levels
  exp_i = exp_i + 1;

  thisRaster = double(base_max_unitq > level_i);

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

%% NPET
if (npet_analysis == true || hrrr_npet_analysis == true)
  res = 1;

  % Subset domain
  subset_unitq = max_unitq(domain.minY:domain.maxY,domain.minX:domain.maxX);
  subset_unitq(subset_unitq < 0) = NaN;
  subset_drain_area = drain_area(domain.minY:domain.maxY,domain.minX:domain.maxX);

  % ----Apply NPET ----
  npet_percentiles = [50, 75, 90, 95, 99];
  %Static weights
  if (npet_hybrid == true)
    % Anisotropic (HRRR Case) - Non-exhaustive calibration
    base_weights1 = simple_npet2dwdist(-40,70,100,150,1);
    npet_fcst1 = npet(subset_unitq,subset_drain_area,base_weights1,0.5,150,npet_percentiles);

    base_weights2 = simple_npet2dwdist(0,0,0,50,1);
    npet_fcst2 = npet(subset_unitq,subset_drain_area,base_weights2,0.5,50,npet_percentiles);
    % Combine into one field: Harcoded split row
    npet_fcst = [npet_fcst1(1:210,:,:); npet_fcst2(211:end,:,:)]; 
  else
    % NPET parameters
    % Change these parameters as needed: anisotropic experiments (see manuscript for details)
    qpf_x_err = 0; %Change to -62.9 for anisotropic NPET (OSE)
    qpf_y_err = 0; %Change to 77.7 for anisotropic NPET (OSE)
    weight_par = 0; %Change to 17 or 60 for anisotropic NPET (OSE)
    area_par = 0.5; %Change to: 0.125 or 0.25 (OSE)
    rad_par = 150;
    base_weights = simple_npet2dwdist(qpf_x_err,qpf_y_err,weight_par,rad_par,res);

    npet_fcst = npet(subset_unitq,subset_drain_area,base_weights,area_par,rad_par,npet_percentiles);   
  end
 
  box_width = 0.1237;
  box_height = 0.7977;
  initial_x_pos = 0.13;
    
  x_pos = initial_x_pos;
  % Hard coded for 5 percentiles
  for i = 1:5
    position_data = [x_pos, 0.11, box_width, box_height];
    fcst_unitq = zeros(size(max_unitq));
    fcst_unitq(domain.minY:domain.maxY,domain.minX:domain.maxX) = npet_fcst(:,:,i);
        
    subplot(1,5,i);
    imagesc(fcst_unitq);
    hold all;
    plot(us_cols,us_rows, 'Color', 'k');
        
    % Multi-threshold polygons
    for idx = M_THminSzObj_idx(1)
      plot(M_THrawObj(idx).ConvexHull(:,1),M_THrawObj(idx).ConvexHull(:,2), 'Color', 'r', 'LineWidth', 2);
    end
    colormap(unitq_cmap); caxis([0 20]);
    set(gca, 'Xlim', [domain.minX domain.maxX], 'Ylim', [domain.minY domain.maxY], 'XTick', [], 'YTick', [], 'Position', position_data);
    title([num2str(npet_percentiles(i)), 'th percentile'], 'FontSize', 12);
        
    % Change x position
    x_pos = x_pos+box_width+0.01;
  end
  set(gcf, 'Position', [89, 462, 1262, 195]); 

  saveas(gcf, '../Experiment_Results/NPET_Ensemble_Maps.fig');
  saveas(gcf, '../Experiment_Results/NPET_Ensemble_Maps.png');
  close all;
end

%% C2020 method
if (c2020_analysis == true)
  dispD = 100;
  dispA = 0;
  dA = 45;
  n_sample = numel(0:dA:360-dA);

  % Pre-allocate: hard coded size of domain
  c2020_ensemble_grids = nan(360,699,n_sample);
  mean_c2020_ensemble_grid = zeros(360,699);
  for ens_i = 1:n_sample
    dispFolder = ['../EF5/Outputs/c2020_method_disp100km/angle_', num2str(dispA, '%.1f'), '/'];
    max_unitq = imread([dispFolder, 'maxunitq.20180527.190000.tif']);
    max_unitq(max_unitq<0) = 0;
    
    c2020_ensemble_grids(:,:,ens_i) = max_unitq(domain.minY:domain.maxY,domain.minX:domain.maxX);
    mean_c2020_ensemble_grid = mean_c2020_ensemble_grid + c2020_ensemble_grids(:,:,ens_i)./n_sample;
    
    dispA = dispA + dA;
  end

  % Compute percentiles
  c2020_percentiles = [5, 25, 50, 75, 90, 95, 99];
  c2020_ensemble_pctiles = nan(360,699,numel(c2020_percentiles));
  for i = 1:360
    for j = 1:699
        c2020_ensemble_pctiles(i,j,:) = prctile(reshape(c2020_ensemble_grids(i,j,:),1,n_sample),c2020_percentiles);
    end
  end

  %% Graphics
  box_width = 0.1237;
  box_height = 0.7977;
  initial_x_pos = 0.13;

  x_pos = initial_x_pos;
  for i = 3:numel(c2020_percentiles)
    position_data = [x_pos, 0.11, box_width, box_height];
    fcst_unitq = zeros(size(max_unitq));
    fcst_unitq(domain.minY:domain.maxY,domain.minX:domain.maxX) = c2020_ensemble_pctiles(:,:,i);

    subplot(1,numel(c2020_percentiles),i);
    imagesc(fcst_unitq);
    hold all;
    plot(us_cols,us_rows, 'Color', 'k');

    % Multi-threshold polygons
    for idx = M_THminSzObj_idx(1)
        plot(M_THrawObj(idx).ConvexHull(:,1),M_THrawObj(idx).ConvexHull(:,2), 'Color', 'r', 'LineWidth', 2);
    end
    colormap(unitq_cmap);
    caxis([0 20]);
    set(gca, 'Xlim', [domain.minX domain.maxX], 'Ylim', [domain.minY domain.maxY], 'XTick', [], 'YTick', [], 'Position', position_data);
    title([num2str(c2020_percentiles(i)), 'th percentile'], 'FontSize', 12);

    % Change x position
    x_pos = x_pos+box_width+0.01;
  end
  set(gcf, 'Position', [89, 462, 1262, 195]);

  saveas(gcf, '../Experiment_Results/c2020_Ensemble_Maps.fig');
  saveas(gcf, '../Experiment_Results/c2020_Ensemble_Maps.png'); 
  close all;
end

exit;
