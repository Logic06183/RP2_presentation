#!/usr/bin/env python3
"""
Advanced Köppen-Geiger conversion with climate classification labels
"""

import geopandas as gpd
import pandas as pd
from shapely.geometry import box
import json
import os

# Set the working directory
os.chdir('/Users/craig/Library/Mobile Documents/com~apple~CloudDocs/RP2_presentation/presentation_assets/images')

# Köppen climate classification mapping (common GRIDCODE values)
# This is a typical mapping - you may need to adjust based on your specific data
KOPPEN_MAPPING = {
    1: 'Af - Tropical rainforest',
    2: 'Am - Tropical monsoon',
    3: 'Aw - Tropical savanna',
    4: 'BWh - Hot desert',
    5: 'BWk - Cold desert',
    6: 'BSh - Hot semi-arid',
    7: 'BSk - Cold semi-arid',
    8: 'Csa - Mediterranean hot summer',
    9: 'Csb - Mediterranean warm summer',
    10: 'Csc - Mediterranean cool summer',
    11: 'Cwa - Humid subtropical',
    12: 'Cwb - Subtropical highland',
    13: 'Cwc - Cold subtropical highland',
    14: 'Cfa - Humid subtropical',
    15: 'Cfb - Oceanic',
    16: 'Cfc - Subpolar oceanic',
    17: 'Dsa - Hot summer continental',
    18: 'Dsb - Warm summer continental',
    19: 'Dsc - Cool summer continental',
    20: 'Dsd - Extremely cold continental',
    21: 'Dwa - Hot summer humid continental',
    22: 'Dwb - Warm summer humid continental',
    23: 'Dwc - Cool summer humid continental',
    24: 'Dwd - Extremely cold humid continental',
    25: 'Dfa - Hot summer humid continental',
    26: 'Dfb - Warm summer humid continental',
    27: 'Dfc - Subarctic',
    28: 'Dfd - Extremely cold subarctic',
    29: 'ET - Tundra',
    30: 'EF - Ice cap'
}

def main():
    print("Loading Köppen-Geiger shapefile with classification labels...")
    
    # Load the shapefile
    gdf = gpd.read_file('c2076_2100_A1FI.shp')
    
    print(f"Original dataset contains {len(gdf)} polygons")
    print(f"Columns in dataset: {list(gdf.columns)}")
    
    # Ensure the data is in WGS84
    if gdf.crs != 'EPSG:4326':
        print("Reprojecting to WGS84...")
        gdf = gdf.to_crs('EPSG:4326')
    
    # Add Köppen climate labels if GRIDCODE exists
    if 'GRIDCODE' in gdf.columns:
        print("Adding Köppen climate classification labels...")
        gdf['koppen_code'] = gdf['GRIDCODE'].map(KOPPEN_MAPPING)
        gdf['koppen_code'] = gdf['koppen_code'].fillna(f"Unknown (GRIDCODE: {gdf['GRIDCODE']})")
    
    # Create Africa bounding box
    africa_bbox = box(-20, -35, 55, 40)
    
    print("Clipping to Africa boundaries...")
    gdf_africa = gdf.clip(africa_bbox)
    
    print(f"After clipping to Africa: {len(gdf_africa)} polygons")
    
    # Show actual GRIDCODE values in the data
    if 'GRIDCODE' in gdf_africa.columns:
        actual_codes = sorted(gdf_africa['GRIDCODE'].unique())
        print(f"Actual GRIDCODE values in African data: {actual_codes}")
    
    # Save various formats
    print("Saving GeoJSON files...")
    
    # Full dataset
    gdf_africa.to_file('koppen_africa_full.geojson', driver='GeoJSON')
    print("✓ Saved: koppen_africa_full.geojson (all attributes)")
    
    # Simplified with essential fields
    if 'GRIDCODE' in gdf_africa.columns:
        fields_to_keep = ['GRIDCODE', 'geometry']
        if 'koppen_code' in gdf_africa.columns:
            fields_to_keep.append('koppen_code')
        
        gdf_simple = gdf_africa[fields_to_keep].copy()
        gdf_simple.to_file('koppen_africa_labeled.geojson', driver='GeoJSON')
        print("✓ Saved: koppen_africa_labeled.geojson (GRIDCODE + labels)")
    
    # Create a summary JSON with metadata
    metadata = {
        "title": "Köppen-Geiger Climate Classification - Africa",
        "description": "Climate zones for African continent (2076-2100 A1FI scenario)",
        "source_file": "c2076_2100_A1FI.shp",
        "total_polygons": len(gdf_africa),
        "bounding_box": {
            "west": -20,
            "south": -35,
            "east": 55,
            "north": 40
        },
        "projection": "EPSG:4326",
        "climate_zones": {}
    }
    
    if 'GRIDCODE' in gdf_africa.columns:
        climate_counts = gdf_africa['GRIDCODE'].value_counts().sort_index()
        for code, count in climate_counts.items():
            label = KOPPEN_MAPPING.get(code, f"Unknown (GRIDCODE: {code})")
            metadata["climate_zones"][str(code)] = {
                "label": label,
                "polygon_count": int(count)
            }
    
    with open('koppen_africa_metadata.json', 'w') as f:
        json.dump(metadata, f, indent=2)
    print("✓ Saved: koppen_africa_metadata.json")
    
    # Print summary
    print("\n=== Conversion Summary ===")
    print(f"Total polygons in Africa: {len(gdf_africa)}")
    if 'GRIDCODE' in gdf_africa.columns:
        print(f"Unique climate zones: {len(gdf_africa['GRIDCODE'].unique())}")
        print("\nTop 5 climate zones by area coverage:")
        top_zones = gdf_africa['GRIDCODE'].value_counts().head(5)
        for code, count in top_zones.items():
            label = KOPPEN_MAPPING.get(code, f"GRIDCODE {code}")
            print(f"  {label}: {count} polygons")
    
    print("\n=== Files Created ===")
    print("• koppen_africa_full.geojson - Complete dataset with all attributes")
    print("• koppen_africa_labeled.geojson - Simplified with GRIDCODE and labels")
    print("• koppen_africa_metadata.json - Dataset metadata and zone descriptions")

if __name__ == "__main__":
    main()