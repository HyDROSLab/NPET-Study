% Harcoded plot settings
rain_period = datenum('2018-05-27 19:20'):1/(24*3):datenum('2018-05-28 08:00');

ens_prctiles = [0.1, 1, 5, 10, 25, 50, 75, 90, 95, 99, 99.9];

linewidths = [2,1.5,2,2.5,3,5,3,2.5,2,1.5,2];
linestyles = [{':'},{'-.'},{'--'},{'-'},{'-'},{'-'},{'-'},{'-'},{'--'},{'-.'},{':'}];
linecolors = [0.8,0.75,0.7,0.65,0.6,0.4,0.6,0.65,0.7,0.75,0.8];

C2020_Data = false;
NPET_D_Analysis = false;
HRRR_Analysis = true; npet_anisotropic = true;

% --- Plot time series for C2020 ensembles
if (C2020_Data == true)
    isotropic_comp = load('../Experiment_Results/npet_vs_c2020_method_45deg_ensembleData_ose_100km_selected_locations_r150km_D_25pct.mat');

    cont = 0;
    maxY = [3, 2, 3, 7];

    for i = 1:4
      cont = cont + 1;
      subplot(2,4,cont);
      % C2020 Method
      % Plot ensemble prctiles
      for ens_i = 1:numel(ens_prctiles)
        plot(rain_period,prctile(isotropic_comp.c2020_ensemble_data(i).ts_series,ens_prctiles(ens_i)), 'Color', [0.7 0.7 0.7], 'LineWidth', linewidths(ens_i), 'LineStyle', linestyles{ens_i}, 'DisplayName', [num2str(ens_prctiles(ens_i)), 'th pctile']); hold all;
      end

      hold all;
      plot(rain_period,isotropic_comp.ensemble_data(i).ref_ts, 'Color', 'r', 'LineWidth', 2, 'DisplayName', 'Reference');
      plot(rain_period,isotropic_comp.ensemble_data(i).loc_ts, 'Color', 'r', 'LineWidth', 2, 'LineStyle', '--', 'DisplayName', 'Deterministic');
    
      set(gca, 'XLim', [rain_period(1) rain_period(end)], 'XTickLabelRotation', -45, 'FontSize', 12, 'Ylim', [0 maxY(i)]);
      datetick('x', 'dd/mm HH', 'keepticks', 'keeplimits');
      grid on;
      if (cont == 1)
        ylabel('C2020', 'FontSize', 14);
      end
    
      % NPET
      subplot(2,4,4+cont);
      for ens_i = 1:numel(ens_prctiles)
        plot(rain_period,isotropic_comp.ensemble_data(i).ts_series(ens_i,:), 'Color', [0.7 0.7 0.7], 'LineWidth', linewidths(ens_i), 'LineStyle', linestyles{ens_i}, 'DisplayName', [num2str(ens_prctiles(ens_i)), 'th pctile']); hold all;
      end
      hold all;
      plot(rain_period,isotropic_comp.ensemble_data(i).ref_ts, 'Color', 'r', 'LineWidth', 2, 'DisplayName', 'Reference');
      plot(rain_period,isotropic_comp.ensemble_data(i).loc_ts, 'Color', 'r', 'LineWidth', 2, 'LineStyle', '--', 'DisplayName', 'Deterministic');
    
      set(gca, 'XLim', [rain_period(1) rain_period(end)], 'XTickLabelRotation', -45, 'FontSize', 12, 'Ylim', [0 maxY(i)]);
      datetick('x', 'dd/mm HH', 'keepticks', 'keeplimits');
      grid on;
      if (cont == 1)
	ylabel('NPET', 'FontSize', 14);
      end
    end

    set(gcf, 'Position', [31, 94, 1220, 680]);
    saveas(gcf, '../Experiment_Results/C2020_vs_NPET_analysis.fig');
    saveas(gcf, '../Experiment_Results/C2020_vs_NPET_analysis.png');
    close all;
end
% --- Plot time series for C2020 ensembles

% --- Plot time series for different D parameter values
if (NPET_D_Analysis == true)
    maxY = [3, 3, 3, 5];
    cont = 0;
    for pct = [12.5, 25, 50]
        load(['../Experiment_Results/npet_ensembleData_isotropic_321deg_selected_locations_r150km_D_', num2str(pct), 'pct.mat']);

      for i = 1:4
        cont = cont + 1;
        subplot(3,4,cont);
        for ens_i = 1:numel(ens_prctiles)
            plot(rain_period,ensemble_data(i).ts_series(ens_i,:), 'Color', repmat(linecolors(ens_i),1,3), 'LineWidth', linewidths(ens_i), 'LineStyle', linestyles{ens_i}, 'DisplayName', [num2str(ens_prctiles(ens_i)), 'th pctile']); hold all;
        end
        hold all
        plot(rain_period,ensemble_data(i).ref_ts, 'Color', 'r', 'LineWidth', 2, 'DisplayName', 'Reference');
        plot(rain_period,ensemble_data(i).loc_ts, 'Color', 'r', 'LineWidth', 2, 'LineStyle', '--', 'DisplayName', 'Deterministic');
        set(gca, 'XLim', [rain_period(1) rain_period(end)], 'XTickLabelRotation', -45, 'FontSize', 12, 'Ylim', [0 maxY(i)]); 
        datetick('x', 'dd/mm HH', 'keepticks', 'keeplimits');
        grid on;
        %ylabel('Unit Streamflow (m^3s^-^1km^-^2)', 'FontSize', 14);
        %xlabel('Date/Time (UTC)', 'FontSize', 14);
      end
    end
    set(gcf, 'Position', [31, 94, 1220, 680]);

    saveas(gcf, '../Experiment_Results/NPET_D_parameter_analysis.fig');
    saveas(gcf, '../Experiment_Results/NPET_D_parameter_analysis.png');
    close all;
end
% --- Plot time series for different D parameter values

% --- Plot time series for HRRR simulation
if (HRRR_Analysis == true)
    pct = '50';
    rad_par = '150';

    if (npet_anisotropic == true)
        % Calibrated
        runMode = 'calibrated_anisotropic_valid_at_13';
    else
        % Uncalibrated
        runMode = 'isotropic_valid_at_13';
    end

    hrrr_data = load(['../Experiment_Results/npet_hrrr_ensembleData_', runMode,'_selected_locations_r', rad_par, 'km_D_', pct, 'pct.mat']);

    hrrr_period = hrrr_data.rain_period;

    maxY = [2, 1.4, 1.4, 5];

    cont = 0;
    figure;
    for i = 1:4
      cont = cont + 1;
      subplot(1,4,cont);
      for ens_i = 1:numel(ens_prctiles)
        plot(hrrr_period,hrrr_data.ensemble_data(i).ts_series(ens_i,:), 'Color', repmat(linecolors(ens_i),1,3), 'LineWidth', linewidths(ens_i), 'LineStyle', linestyles{ens_i}, 'DisplayName', [num2str(ens_prctiles(ens_i)), 'th pctile']); hold all;
      end
      plot(hrrr_period,hrrr_data.ensemble_data(i).ref_ts, 'Color', 'r', 'LineWidth', 2, 'DisplayName', 'Reference');
      plot(hrrr_period,hrrr_data.ensemble_data(i).loc_ts, 'Color', 'r', 'LineWidth', 2, 'LineStyle', '--', 'DisplayName', 'Deterministic');
      set(gca, 'FontSize', 12, 'XTick', datenum('27-May-2018 18:00:00'):3/24:hrrr_period(end), 'XLim', [datenum('27-May-2018 18:00:00') hrrr_period(end)], 'XTickLabelRotation', -45, 'Ylim', [0 maxY(i)]);
      datetick('x', 'dd/mm HH', 'keepticks', 'keeplimits');
      grid on;
%         ylabel('Unit Streamflow (m^3s^-^1km^-^2)', 'FontSize', 14);
%         xlabel('Date/Time (UTC)', 'FontSize', 14);
    end
    set(gcf, 'Position', [1, 507, 1440, 291]);
  
    saveas(gcf, ['../Experiment_Results/HRRR_NPET_', runMode, '_analysis.fig']); 
    saveas(gcf, ['../Experiment_Results/HRRR_NPET_', runMode, '_analysis.png']);
    close all;
end
% --- Plot time series for HRRR simulation
exit;
