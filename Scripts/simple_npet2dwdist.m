function npet_weights = simple_npet2dwdist(bias_x,bias_y,w_par,rad,res) 
% Models the probabilities within the NPET box to be used as weights
% A Beta distribution is used to model PDF along both x-axis and y-axis
%
% Input Arguments:
% bias_x - Displacement bias along x-axis in kilometers
% bias_y - Displacement bias along y-axis in kilometers
% w_par - Weight parameter around the mean bias
% rad - Radius of search box in kilometers
% res - Resolution of grid in kilometers

%First re-scale everything to a 0 - 1 scale
gen_axis = linspace(0,2*rad,numel(-rad:res:rad));
unit_axis = gen_axis./max(gen_axis);

if (abs(bias_x) > rad)
    bias_x = rad*(bias_x/abs(bias_x));
end

%re-scale and add 0.5 so bias is from center
u_bias_x = 0.5 + abs(bias_x)./(2*rad);

if (abs(bias_y) > rad)
    bias_y = rad*(bias_y/abs(bias_y));
end
%re-scale and add 0.5 so bias is from center
u_bias_y = 0.5 + abs(bias_y)./(2*rad);

%Create mesh with the 0 - 1 scale (unit_axis)
[u1,u2] = meshgrid(unit_axis,unit_axis);

%Determine the shape parameters of the distribution using the displacement
%biases and weight parameter

%X - axis
if (bias_x > 0)
    %a > b
    par_a_x = w_par*u_bias_x+1;
    %Use formula of the median
    par_b_x = (par_a_x - 1/3)/u_bias_x - par_a_x + 2/3;
else
   %b > a
   par_b_x = w_par*u_bias_x+1;
   %Use formula of the median
   par_a_x = (par_b_x - 1/3)/u_bias_x - par_b_x + 2/3;
end

% fprintf('X-axis - a = %f, b = %f\n', par_a_x, par_b_x);

%Make sure parameter values are >= 1
par_a_x = max(par_a_x,1);
par_b_x = max(par_b_x,1);
   
%Y - axis
if (bias_y > 0)
    %a > b
    par_a_y = w_par*u_bias_y+1;
    %Use formula of the median
    par_b_y = (par_a_y-1/3)/u_bias_y - par_a_y + 2/3; 
else
    %b > a   
    par_b_y = w_par*u_bias_y+1;
    %Use formula of the median
    par_a_y = (par_b_y-1/3)/u_bias_y - par_b_y + 2/3;
end

% fprintf('Y-axis - a = %f, b = %f\n', par_a_y, par_b_y);

%Make sure parameter values are >= 1
par_a_y = max(par_a_y,1);
par_b_y = max(par_b_y,1);

%Create Beta distribution models
pd_x = makedist('Beta','a',par_a_x, 'b', par_b_x);
pd_y = makedist('Beta','a',par_a_y, 'b', par_b_y);

prob_y = pdf(pd_y,u2);
% Flip the matrix vertically because minimum row index -> maximum North
% location
prob_y = flipdim(prob_y,1);
prob_x = pdf(pd_x,u1);

%Compute the conditional probabilities
npet_weights = prob_y.*prob_x;

% Apply Circle mask
[imageSizeY, imageSizeX] = size(npet_weights);
[columnsInImage, rowsInImage] = meshgrid(1:imageSizeX, 1:imageSizeY);
% Next create the circle in the image.
centerX = imageSizeX/2;
centerY = imageSizeY/2;
circlePixels = (rowsInImage - centerY).^2 + (columnsInImage - centerX).^2 <= rad.^2;

new_npet_weights = zeros(imageSizeY, imageSizeX);
new_npet_weights(circlePixels == 1) = npet_weights(circlePixels == 1);
npet_weights = new_npet_weights;

%Normalize
npet_weights = npet_weights./nansum(npet_weights(:));

% Estimate circle's sector percentage
if (bias_x ~= 0 || bias_y ~= 0)
    [bias_rows, bias_cols] = find(npet_weights > 0);
    bias_pixels = find(npet_weights > 0);
    
    main_angle = 270+atan2(bias_x,bias_y)*180/pi;

    sect_i = 0;
    all_sectors = 5:2.5:90;
    for sect = all_sectors
        sect_i = sect_i + 1;
	Parc = plot_arc(deg2rad(main_angle-sect),deg2rad(main_angle+sect),rad,rad,rad,0);
        inSectorPixels = inpolygon(bias_cols,bias_rows,Parc.Vertices(:,1),Parc.Vertices(:,2));
        pctInSector(sect_i) = sum(npet_weights(bias_pixels(inSectorPixels)))*100;
        
        if (pctInSector(sect_i) >= 95)
            fprintf('Chosen sector angle is %0.2f\n', sect*2);
            break;
        end
    end
end

function P = plot_arc(a,b,h,k,r,plotkey)
% Plot a circular arc as a pie wedge.
% a is start of arc in radians, 
% b is end of arc in radians, 
% (h,k) is the center of the circle.
% r is the radius.
% Try this:   plot_arc(pi/4,3*pi/4,9,-4,3)
% Author:  Matt Fig
t = linspace(a,b);
x = r*cos(t) + h;
y = r*sin(t) + k;
x = [x h x(1)];
y = [y k y(1)];

if (plotkey == 1)
    P = fill(x,y,'r');
    axis([h-r-1 h+r+1 k-r-1 k+r+1])
    axis square;
else
    P.Vertices = [x',y'];
end

if ~nargout
    clear P
end
