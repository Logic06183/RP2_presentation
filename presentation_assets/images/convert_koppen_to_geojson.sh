#!/bin/bash

# Navigate to the directory containing the shapefile
cd "/Users/craig/Library/Mobile Documents/com~apple~CloudDocs/RP2_presentation/presentation_assets/images"

# Method 1: Convert entire shapefile to GeoJSON
echo "Converting entire shapefile to GeoJSON..."
ogr2ogr -f "GeoJSON" -t_srs EPSG:4326 koppen_global.geojson c2076_2100_A1FI.shp

# Method 2: Convert and clip to Africa boundaries in one step
echo "Converting and clipping to Africa boundaries..."
ogr2ogr -f "GeoJSON" -t_srs EPSG:4326 -spat -20 -35 55 40 koppen_africa.geojson c2076_2100_A1FI.shp

# Method 3: Convert with specific field selection (if you want to include GRIDCODE and other attributes)
echo "Converting with all attributes..."
ogr2ogr -f "GeoJSON" -t_srs EPSG:4326 -spat -20 -35 55 40 -select "GRIDCODE" koppen_africa_with_codes.geojson c2076_2100_A1FI.shp

echo "Conversion complete!"
echo "Files created:"
echo "- koppen_global.geojson (entire dataset)"
echo "- koppen_africa.geojson (clipped to Africa)"
echo "- koppen_africa_with_codes.geojson (clipped to Africa with GRIDCODE field)"