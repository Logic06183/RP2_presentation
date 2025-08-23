#!/usr/bin/env python3
"""
Convert Köppen-Geiger climate classification shapefile to GeoJSON
and clip to African continent boundaries
"""

import geopandas as gpd
import pandas as pd
from shapely.geometry import box
import os

# Set the working directory
os.chdir('/Users/craig/Library/Mobile Documents/com~apple~CloudDocs/RP2_presentation/presentation_assets/images')

def main():
    print("Loading Köppen-Geiger shapefile...")
    
    # Load the shapefile
    gdf = gpd.read_file('c2076_2100_A1FI.shp')
    
    print(f"Original dataset contains {len(gdf)} polygons")
    print(f"Columns in dataset: {list(gdf.columns)}")
    print(f"Current CRS: {gdf.crs}")
    
    # Ensure the data is in WGS84 (EPSG:4326) for web use
    if gdf.crs != 'EPSG:4326':
        print("Reprojecting to WGS84...")
        gdf = gdf.to_crs('EPSG:4326')
    
    # Create bounding box for Africa
    # Longitude: -20W to 55E, Latitude: -35S to 40N
    africa_bbox = box(-20, -35, 55, 40)
    
    print("Clipping to Africa boundaries...")
    
    # Clip to Africa boundaries
    gdf_africa = gdf.clip(africa_bbox)
    
    print(f"After clipping to Africa: {len(gdf_africa)} polygons")
    
    # Check what GRIDCODE values are present in the Africa subset
    if 'GRIDCODE' in gdf_africa.columns:
        unique_codes = sorted(gdf_africa['GRIDCODE'].unique())
        print(f"GRIDCODE values in African data: {unique_codes}")
    
    # Save different versions
    print("Saving GeoJSON files...")
    
    # Save full global dataset
    gdf.to_file('koppen_global.geojson', driver='GeoJSON')
    print("✓ Saved: koppen_global.geojson")
    
    # Save Africa-clipped version
    gdf_africa.to_file('koppen_africa.geojson', driver='GeoJSON')
    print("✓ Saved: koppen_africa.geojson")
    
    # Save a simplified version with only essential fields
    if 'GRIDCODE' in gdf_africa.columns:
        gdf_simple = gdf_africa[['GRIDCODE', 'geometry']].copy()
        gdf_simple.to_file('koppen_africa_simple.geojson', driver='GeoJSON')
        print("✓ Saved: koppen_africa_simple.geojson (GRIDCODE + geometry only)")
    
    # Print summary statistics
    print("\n=== Summary ===")
    print(f"Global polygons: {len(gdf)}")
    print(f"Africa polygons: {len(gdf_africa)}")
    
    if 'GRIDCODE' in gdf_africa.columns:
        print(f"Unique climate zones in Africa: {len(gdf_africa['GRIDCODE'].unique())}")
        
        # Show the distribution of climate zones
        climate_counts = gdf_africa['GRIDCODE'].value_counts().sort_index()
        print("\nClimate zone distribution in Africa:")
        for code, count in climate_counts.head(10).items():  # Show top 10
            print(f"  GRIDCODE {code}: {count} polygons")
        if len(climate_counts) > 10:
            print(f"  ... and {len(climate_counts) - 10} more zones")

if __name__ == "__main__":
    main()