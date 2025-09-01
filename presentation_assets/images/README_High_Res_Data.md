# High-Resolution Köppen-Geiger Data

## Data Source
The ultra high-resolution climate maps were created using Beck et al. (2023) 1km Köppen-Geiger dataset.

**Citation**: Beck, H.E., T.R. McVicar, N. Vergopolan, A. Berg, N.J. Lutsko, A. Dufour, Z. Zeng, X. Jiang, A.I.J.M. van Dijk, and D.G. Miralles. High-resolution (1 km) Köppen-Geiger maps for 1901–2099 based on constrained CMIP6 projections, Scientific Data 10, 724 (2023).

**Download Source**: https://figshare.com/articles/dataset/High-resolution_1_km_K_ppen-Geiger_maps_for_1901_2099_based_on_constrained_CMIP6_projections/21789074

## Local Data Files
- `koppen_geiger_tif (1).zip` - Original download (124MB, too large for GitHub)
- `high_res_koppen/` - Extracted GeoTIFF files (not committed due to size)
- `high_res_koppen/1991_2020/koppen_geiger_0p00833333.tif` - 1km resolution data used for maps

## Generated Maps
- `southern_africa_wellcome_final.svg` - **Main publication map**
- `southern_africa_1km_traditional_colors.png` - Traditional color scheme
- `southern_africa_final_1km_labeled.png` - With climate zone labels
- `study_locations_climate_zones.csv` - Extracted climate data

## Usage
To regenerate maps, download the dataset from the source above and extract to `high_res_koppen/` folder, then run the R scripts.