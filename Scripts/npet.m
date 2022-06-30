function npet_grid = npet(input_grid,area_grid,weights_field,area_parameter,radius_parameter,percentiles)
% NPET - Neigboring Pixel Ensemble Technique
% Initialize output NPET grid
[nrows, ncols] = size(input_grid);
npet_grid = zeros(nrows,ncols);
% Weighting grid predetermined rows and columns
pred_rows = 1:size(weights_field,1);
pred_cols = 1:size(weights_field,2);

[valid_rows,valid_cols] = find(input_grid >= 0 & area_grid > 0);
valid_pixels = find(input_grid >= 0 & area_grid > 0);
cont_i = 0;

% Perform NPET depending on mode:        
npet_grid = zeros(nrows,ncols,numel(percentiles));
        
for val_pix_i = valid_pixels'
  cont_i = cont_i + 1;            
  row_i = valid_rows(cont_i);            
  col_i = valid_cols(cont_i);
            
  pixel_area = area_grid(row_i,col_i);
            
  %These are the column/rows indexes of the main q grid            
  columns = col_i-radius_parameter:col_i+radius_parameter;             
  this_wcols = pred_cols(columns>0 & columns <= ncols);            
  columns = columns(columns>0 & columns <= ncols);          
  rows = row_i-radius_parameter:row_i+radius_parameter; 
  this_wrows = pred_rows(rows>0 & rows <= nrows);
  rows = rows(rows>0 & rows <= nrows);

  pro_box = input_grid(rows,columns);
  pro_box_area = area_grid(rows,columns);
  subset_weights = weights_field(this_wrows,this_wcols); %(good_idxs);

  %Furter subset with area parameter
  area_filtered_idxs = find(subset_weights > 0 & pro_box_area >= pixel_area.*(1-area_parameter) & pro_box_area <= pixel_area.*(1+area_parameter));

  if (isempty(area_filtered_idxs) == 1 || max(pro_box(area_filtered_idxs)) == 0)                
    continue;
  end
            
  %Compute percentiles
  npet_grid(row_i,col_i,:) = weigh_prctile(pro_box(area_filtered_idxs), percentiles, 3, 'weighted', subset_weights(area_filtered_idxs));
end

