# NPET-Study

This repository hosts analysis data and programming scripts supporting the study "An Efficient Ensemble Technique for Hydrologic Forecasting driven by Quantitative Precipitation Forecasts" submitted to AMS Journal of Hydrometeorology.

The study focuses on post-processing of hydrologic modeling outputs for simulations of the flash flood event occurred over Ellicott City, MD, USA between 05/27/2018 19:00 and 05/28/2018 03:00 UTC.

## List of datasets

Excessive storage requirements precluded making the complete set of raw files (FLASH outputs and MRMS v12 QPE files) available.

- Quantitative Precipitation Estimates (QPEs) from the Multi-Radar Multi-Sensor (MRMS) system
- Quantitative Precipitation Forecasts (QPFs) from the High Resolution Rapid Refresh (HRRR) system
- CREST Maximum Unit Streamflow Maps

## Scripts

### Pre-processing

- MoveQPEFiels.m - Used to generate displacement vectors (magnitudes and directions) to displace QPE fields systematically (i.e., steady-state assumption). The sensitivity analysis experiments used this script to generate the 360 scenarios (120 angles and 3 displacement distances).

- moveQPEorigin.py - Used to modify the georeference information of each individual GeoTIFF with QPEs using the displacement vectors generated with "MoveQPEFiels.m". This script creates a folder for each angle within the corresponding folder associated with a displacement length in the master folder "QPEperturbations".

### EF5 set-up

- Ellicot_ef5_ctrl_template.txt - Template of EF5 configuration

Setting up EF5 requires additional datasets available at https://github.com/HyDROSLab/EF5-US-Parameters.


