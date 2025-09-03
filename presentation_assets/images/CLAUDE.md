# Images and Visualization Directory

This directory contains climate visualizations, maps, and analysis outputs.

## Key Subdirectories

### Climate Maps
- **koppen_extracted/** - Köppen-Geiger climate classification rasters
- **high_res_koppen/** - High resolution (1km) Köppen data
- **SVG Maps** - Various Southern Africa climate zone visualizations

### Heat Health Analysis
- Johannesburg and Abidjan comparative studies
- Heat Vulnerability Index (HVI) maps
- Urban heat island analysis

### Key Files

#### Köppen Climate Maps (SVG)
- `koppen_condensed_labeled.svg` - Simplified climate zones with labels
- `koppen_final_labeled.svg` - Detailed climate classification
- `southern_africa_*.svg` - Regional climate maps and trajectories

#### Analysis Notebooks
- `Heat_Health_Analysis_*.ipynb` - Urban heat analysis
- `Johannesburg_Scientific_*.ipynb` - City-specific studies

#### Data Files
- `johannesburg_abidjan_CORRECTED_dataset.csv` - Comparative city data
- `study_locations_climate_zones.csv` - Study site classifications

## Python Scripts

### Map Creation
- `create_final_scientific_koppen.py` - Generate publication-ready Köppen maps
- `create_condensed_legend_koppen.py` - Create simplified legends
- `create_koppen_svg_maps.py` - Vector map generation

### Analysis
- `gee_heat_health_maps.py` - Google Earth Engine heat analysis
- `nighttime_lights_urbanization.py` - Urban growth analysis

## R Scripts
- `create_southern_africa_climate_map.R` - Regional climate visualizations
- `create_warming_progression_diagram.R` - Climate change trajectories

## Usage

Most Python scripts can be run directly:
```bash
python create_final_scientific_koppen.py
```

R scripts require appropriate packages:
```r
source("create_southern_africa_climate_map.R")
```