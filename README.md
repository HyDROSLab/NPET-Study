# NPET-Study

This repository hosts analysis data and programming scripts supporting the study "An Efficient Ensemble Technique for Hydrologic Forecasting driven by Quantitative Precipitation Forecasts" submitted to AMS Journal of Hydrometeorology.

NPET stands for Neighboring Pixel Ensemble Technique, a post-processing algorithm that accounts for Precipitation Forecasts location uncertainty. The study focuses on post-processing of hydrologic modeling outputs for simulations of the flash flood event occurred over Ellicott City, MD, USA between 05/27/2018 19:00 and 05/28/2018 03:00 UTC.

## Contact information

- Humberto Vergara (Lead author/developer) - humber@ou.edu
- Jonathan Gourley (Co-author/Co-developer and FLASH Lead PI) - jj.gourley@noaa.gov
- Michael Erickson (Co-author/QPF Displacement Work) - michael.j.erickson@noaa.gov

## Datasets

Excessive storage requirements precluded making the complete set of raw files and pre-computed outputs (FLASH outputs and MRMS v12 QPE files) available. A subset of the files used in the analysis of this study are included:

- Quantitative Precipitation Estimates (QPEs) from the Multi-Radar Multi-Sensor (MRMS) system (20 minutes): **MRMS_20MinQPE.tar.gz**

- Quantitative Precipitation Forecasts (QPFs) from the High Resolution Rapid Refresh (HRRR) system (hourly): **HRRRv3_20180527_13UTC.tar.gz**

- Pre-computed CREST Maximum Unit Streamflow Maps using the original QPEs (baseline/reference)and perturbed QPEs from the MRMS system for the sensitivity analysis experiment, and using QPFs from the hourly HRRR dataset. These are available in the "EF5/Outputs/" folder, each within a subfolder with self-explanatory name.

Additional files used by some of the scripts are located within the "Scripts/auxiliary/" folder:

- **Locations_for_TimeSeries.csv** - Table of selected locations where time series were evaluated.

- **DrainArea_1km_mrms_grid.tif** - Drainage area at every pixel within MRMS/FLASH domain. Georeference information of the same domain is available in this GeoTIFF.

- **flashweb_unitQ_colormap_linearScale_manually_calibrated.mat** - Colormap for unit streamflow maps as conventionally used in FLASH.

- **US_States_boundaries.mat** - US States boundaries as row/col point coordinates.

## Scripts

The scripts in this repository can be used to recreate some of the inputs and outputs used in the study. Some of the following scripts depend on additional libraries that need to be installed prior to their use, The following is a list of required libraries (not comprehensive):

- GDAL Libraries (https://gdal.org)
- EF5 (https://github.com/HyDROSLab/EF5)

### Pre-processing

- **MoveQPEFields.m** - Used to generate displacement vectors (magnitudes and directions) to displace QPE fields systematically (i.e., steady-state assumption). The sensitivity analysis experiments used this script to generate the 360 scenarios (120 angles and 3 displacement distances).

- **moveQPEorigin.py** - Used to modify the georeference information of each individual GeoTIFF with QPEs (files in MRMS_20MinQPE.tar.gz) using the displacement vectors generated with "MoveQPEFiels.m". This script creates a folder for each angle within the corresponding folder associated with a displacement length in the master folder "QPEperturbations". In the study, this code is used with the isolated storm (hydrometeorological domain in the manuscript).

- **MoveQPEFields_C2020.m** - Similar to "MoveQPEFields.m" but specifically for implementing the C2020 method used in the study.

- **moveQPEorigin_c2020_method.py** - Similar to "moveQPEorigin.py" but specifically for implementing the C2020 method used in the study. This requires having available the perturbed QPE scenario for a 100-km displacement length and 321 degrees azimuth displacemente angle.

### EF5 set-up

Pre-processing scripts need to be used prior to running EF5 to generate the complete set of hydrologic outputs (i.e., time series of 20-min hydrologic outputs). Setting up EF5 requires additional datasets available at https://github.com/HyDROSLab/EF5-US-Parameters.

- **Ellicot_ef5_ctrl.txt** - Control file to generate reference/baseline hydrologic simulations with EF5. The file can also be used to run the forecast experiment with HRRR inputs. This control file allows for four different configurations:

a) Full domain QPE - Uses 20-min MRMS QPEs withouth any modification.

b) Isolated QPE - Uses 20-min MRMS QPE fields with values only within the "hydrometeorological domain".

c) No rain - This run is used to subtract the hydrologic response that is the product of antecedent conditions stored in state files with initial conditions (Files in the "EF5/States/" folder). The maximum unit streamflow map generated in this run is used with the "Isolated QPE" output to compute error statistics (see "sensitivity_analysis_error_quantification.m" script).

d) HRRR - Run hydrologic simulation using hourly HRRR forecasts.

NOTE: Paths to input, output, parameters and state files in this control file are defined relative to its location.

- **Ellicot_ef5_ctrl_template.txt** - Template of EF5 configuration for simulations with different perturbed QPEs. This template is used by "GenCtrl_n_RunEF5_Queue.py".

- **GenCtrl_n_RunEF5_Queue.py** - Used to recursively generate and run EF5 configuration files for each perturbed QPE scenario generated. See comments and commented lines to edit file for different run options.

### Post-processing

The following scripts are used with outputs generated with EF5. Maximum unit streamflow maps were pre-computed and are readily available, but 20-min unit streamflow maps need to be computed prior to using all scripts that generate time series.

- **sensitivity_analysis_error_quantification.m** - Computes error fields from the sensitivity analysis experiment. Requires EF5 maximum streamflow maps for the 360 perturbation scenarios.

- **NPET_vs_C2020_Ensembles_at_Locations.m** - Generates ensemble data with NPET and the C2020 method for the four specific locations selected in this study.

- **npet_ensembles_for_perturbed_scenarios.m** - Generates ensemble data with NPET with the specifc perturbed scenario of the OSE (100-km, 321 degrees) for the four specific locations selected in this study.

- **npet_ensembles_for_hrrr_forecasts.m** - Generates ensemble data with NPET for the simulation using HRRR data as input for the four specific locations selected in this study. 

- **plot_ensemble_time_series.m** - Generates plots of ensemble time series for different experiments. 

- **Generate_NPET_maps.m** - Applies NPET on maps of unit streamflow for the varius scenarios covered in the study. Generates plots of NPET ensembles (percentiles) as presented in the study. See commented lines at the top of the script for some instructions. 

- **npet.m** - Computes NPET field for a particular unit streamflow map and NPET neighborhood generated with "simple_npet2dwdist.m". 

- **simple_npet2dwdist.m** - Generates the bivariate weight field (NPET Neighborhood) for NPET computations. 

- **weigh_prctile.m** - Auxiliary function to compute weighted percentiles. 
