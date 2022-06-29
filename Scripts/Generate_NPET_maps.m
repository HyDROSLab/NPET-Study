% Apply NPET on Maximum Unit Streamflow Maps

% FLASH
% Baseline run
base_max_unitq = imread('../EF5/Outputs/baseline_isostorm/maxunitq.20180527.190000.tif');
% No Rain Run
no_rain_maxunitq = imread('../EF5/Outputs/baseline_norain/maxunitq.20180527.190000.tif');
no_rain_maxunitq(no_rain_maxunitq<0) = 0;

% Adjust max unit Q grid to exclude signal from precip prior to event
base_max_unitq = base_max_unitq - no_rain_maxunitq; base_max_unitq(base_max_unitq<0) = 0;

mapinfo = geotiffinfo('auxiliary/DrainArea_1km_mrms_grid.tif');

% Colormap for unit streamflow maps (as used in FLASH demo system)
load('auxiliary/flashweb_unitQ_colormap_linearScale_manually_calibrated.mat');

%% Identify FF objects
levels = 0.35;
nPix_levels = 40;

%% C2020 method
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

saveas(gcf, 'c2020_Ensemble_Maps.png'); 
close all;
