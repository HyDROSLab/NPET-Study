# NPET-Study

This repository hosts analysis data and programming scripts supporting the study "An Efficient Ensemble Technique for Hydrologic Forecasting driven by Quantitative Precipitation Forecasts" submitted to AMS Journal of Hydrometeorology.

The study focuses on post-processing of hydrologic modeling outputs for simulations of the flash flood event occurred over Ellicott City, MD, USA between 05/27/2018 19:00 and 05/28/2018 03:00 UTC.

## List of datasets

Excessive storage requirements precluded making the complete set of raw files (FLASH outputs and MRMS v12 QPE files) available.

- Quantitative Precipitation Estimates (QPEs) from the Multi-Radar Multi-Sensor (MRMS) system (20 minutes): MRMS_20MinQPE.tar.gz
- Quantitative Precipitation Forecasts (QPFs) from the High Resolution Rapid Refresh (HRRR) system (hourly):
- CREST Maximum Unit Streamflow Maps

## Scripts

Some of the following scripts depend on additional libraries that need to be installed prior to their use, The following is a list of required libraries (not comprehensive):

- GDAL Libraries (https://gdal.org)
- EF5 (https://github.com/HyDROSLab/EF5)

### Pre-processing

- MoveQPEFiels.m - Used to generate displacement vectors (magnitudes and directions) to displace QPE fields systematically (i.e., steady-state assumption). The sensitivity analysis experiments used this script to generate the 360 scenarios (120 angles and 3 displacement distances).

- moveQPEorigin.py - Used to modify the georeference information of each individual GeoTIFF with QPEs (files in MRMS_20MinQPE.tar.gz) using the displacement vectors generated with "MoveQPEFiels.m". This script creates a folder for each angle within the corresponding folder associated with a displacement length in the master folder "QPEperturbations". In the study, this code is used with the isolated storm (hydrometeorological domain in the manuscript).

### EF5 set-up

- Ellicot_ef5_ctrl_template.txt - Template of EF5 configuration for simulations with different perturbed QPEs.

Setting up EF5 requires additional datasets available at https://github.com/HyDROSLab/EF5-US-Parameters.

- GenCtrl_n_RunEF5_Queue.py - Used to recursively generate and run EF5 configuration files for each perturbed QPE scenario generated. See comments and commented lines to edit file for different run options.
