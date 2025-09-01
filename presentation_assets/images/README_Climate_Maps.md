# Southern Africa Climate Mapping for Wellcome Trust Grant

## Overview
This folder contains climate mapping analysis for southern Africa, focusing on Malawi, South Africa, and Zimbabwe. Built using Köppen-Geiger climate classification system integrated with socioeconomic and health indicators.

## Key Output Files

### Climate Maps
- `southern_africa_smooth_climate_map.svg` - **Main map**: Smoothed climate zones (recommended for presentation)
- `southern_africa_enhanced_climate_map.svg` - Enhanced version with integrated data  
- `southern_africa_integrated_climate_development_map.png` - Map + data table combined

### Data Files
- `southern_africa_climate_summary.json` - Detailed climate zone analysis
- `southern_africa_climate_summary.csv` - Summary statistics table
- `southern_africa_climate_summary.txt` - Comprehensive climate characteristics

### Source Scripts
- `create_southern_africa_climate_map.R` - Basic southern Africa climate map
- `create_integrated_southern_africa_map.R` - Enhanced map with table data integration
- `create_smooth_map_builtin.R` - **Smoothed version** (reduces pixelation)
- `extract_climate_data_southern_africa.R` - Climate data extraction and analysis

## Climate Findings Summary

### Malawi
- **Dominant Climate**: Tropical Wet Savanna (Aw) - 74.1%
- **Characteristics**: Seasonal rainfall, hot wet summers
- **Vulnerability**: #26 most vulnerable globally
- **GDP**: $520 per capita

### South Africa  
- **Dominant Climate**: Cold Desert (BWk) - 47.4%
- **Characteristics**: Most climate-diverse (11 zones), arid conditions
- **Vulnerability**: #117 most vulnerable globally  
- **GDP**: $6,023 per capita

### Zimbabwe
- **Dominant Climate**: Tropical Wet Savanna (Aw) - 57.4%
- **Characteristics**: Seasonal patterns, moderate elevation
- **Vulnerability**: #51 most vulnerable globally
- **GDP**: $2,156 per capita

## Usage
Run any of the R scripts to regenerate maps. The smoothed version (`create_smooth_map_builtin.R`) produces the highest quality output for presentations.

## Data Source
Based on Köppen-Geiger climate classification from `koppen_africa_with_labels.geojson`