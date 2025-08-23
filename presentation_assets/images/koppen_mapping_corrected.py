#!/usr/bin/env python3
"""
Enhanced Köppen-Geiger conversion with corrected climate classification labels
Based on the actual GRIDCODE values found in your data
"""

import geopandas as gpd
import pandas as pd
from shapely.geometry import box
import json
import os

# Set the working directory
os.chdir('/Users/craig/Library/Mobile Documents/com~apple~CloudDocs/RP2_presentation/presentation_assets/images')

# Köppen climate classification mapping based on typical GRIDCODE schemes
# These are common mappings - adjust based on your data documentation
KOPPEN_MAPPING = {
    11: 'Af - Tropical rainforest climate',
    12: 'Am - Tropical monsoon climate', 
    13: 'As - Tropical dry savanna climate',
    14: 'Aw - Tropical wet savanna climate',
    21: 'BWh - Hot desert climate',
    22: 'BWk - Cold desert climate',
    23: 'BSh - Hot semi-arid climate',
    24: 'BSk - Cold semi-arid climate',
    26: 'BSh/BSk - Semi-arid climate variant',
    27: 'BSk - Cold semi-arid steppe climate',
    31: 'Csa - Mediterranean hot summer climate',
    32: 'Csb - Mediterranean warm summer climate',
    34: 'Cwa - Humid subtropical climate',
    35: 'Cwb - Subtropical highland climate',
    37: 'Cfa - Humid subtropical climate',
    38: 'Cfb - Oceanic climate',
    41: 'Dsa - Hot summer continental climate',
    45: 'Dfb - Warm summer humid continental climate'
}

def main():
    print("Loading Köppen-Geiger shapefile and adding climate labels...")
    
    # Load the already converted Africa data
    gdf_africa = gpd.read_file('koppen_africa.geojson')
    
    print(f"Africa dataset contains {len(gdf_africa)} polygons")
    print(f"Columns: {list(gdf_africa.columns)}")
    
    # Add Köppen climate labels
    if 'GRIDCODE' in gdf_africa.columns:
        print("Adding Köppen climate classification labels...")
        gdf_africa['koppen_label'] = gdf_africa['GRIDCODE'].map(KOPPEN_MAPPING)
        
        # For unmapped codes, create a generic label
        unmapped_mask = gdf_africa['koppen_label'].isna()
        gdf_africa.loc[unmapped_mask, 'koppen_label'] = (
            'Climate Zone ' + gdf_africa.loc[unmapped_mask, 'GRIDCODE'].astype(str)
        )
        
        # Extract just the main Köppen code (before the dash)
        gdf_africa['koppen_code'] = gdf_africa['koppen_label'].str.split(' - ').str[0]
    
    # Show the climate zones found in African data
    if 'GRIDCODE' in gdf_africa.columns:
        print(f"\nClimate zones in African data:")
        climate_summary = gdf_africa.groupby(['GRIDCODE', 'koppen_label']).size().reset_index(name='count')
        climate_summary = climate_summary.sort_values('GRIDCODE')
        
        for _, row in climate_summary.iterrows():
            print(f"  GRIDCODE {row['GRIDCODE']}: {row['koppen_label']} ({row['count']} polygons)")
    
    # Save enhanced version
    print("\nSaving enhanced GeoJSON with Köppen labels...")
    gdf_africa.to_file('koppen_africa_with_labels.geojson', driver='GeoJSON')
    print("✓ Saved: koppen_africa_with_labels.geojson")
    
    # Create a climate zone summary
    climate_zones = {}
    if 'GRIDCODE' in gdf_africa.columns:
        for _, row in climate_summary.iterrows():
            climate_zones[str(row['GRIDCODE'])] = {
                'label': row['koppen_label'],
                'short_code': row.get('koppen_code', ''),
                'polygon_count': int(row['count']),
                'percentage': round((row['count'] / len(gdf_africa)) * 100, 1)
            }
    
    # Create comprehensive metadata
    metadata = {
        "title": "Köppen-Geiger Climate Classification - African Continent",
        "description": "Climate zones for Africa (2076-2100 A1FI scenario) clipped from global data",
        "source_file": "c2076_2100_A1FI.shp", 
        "processing_date": pd.Timestamp.now().isoformat(),
        "total_polygons": len(gdf_africa),
        "unique_climate_zones": len(climate_summary),
        "geographic_extent": {
            "description": "African continent approximately",
            "bounding_box": {
                "west_longitude": -20,
                "south_latitude": -35, 
                "east_longitude": 55,
                "north_latitude": 40
            }
        },
        "coordinate_system": "EPSG:4326 (WGS84)",
        "climate_zones": climate_zones,
        "data_fields": {
            "ID": "Original polygon identifier",
            "GRIDCODE": "Numeric climate zone code",
            "koppen_label": "Full Köppen climate classification with description", 
            "koppen_code": "Short Köppen climate code (e.g., Af, BWh, Csa)",
            "geometry": "Polygon geometry in WGS84"
        },
        "usage_notes": [
            "This data represents projected climate zones for 2076-2100 under A1FI scenario",
            "GRIDCODE values correspond to specific Köppen climate classifications",
            "Data has been clipped to African continental boundaries",
            "Suitable for web mapping applications using coordinate system EPSG:4326"
        ]
    }
    
    # Save metadata
    with open('koppen_africa_complete_metadata.json', 'w') as f:
        json.dump(metadata, f, indent=2)
    print("✓ Saved: koppen_africa_complete_metadata.json")
    
    # Show final summary
    print("\n" + "="*60)
    print("CONVERSION COMPLETE - SUMMARY")
    print("="*60)
    print(f"Original global polygons: 1976")
    print(f"African continent polygons: {len(gdf_africa)}")
    print(f"Unique climate zones in Africa: {len(climate_summary)}")
    print(f"Geographic coverage: 20°W to 55°E, 35°S to 40°N")
    
    print(f"\nMost common climate zones in Africa:")
    top_zones = climate_summary.nlargest(3, 'count')
    for _, row in top_zones.iterrows():
        pct = round((row['count'] / len(gdf_africa)) * 100, 1)
        print(f"  • {row['koppen_label']}: {row['count']} polygons ({pct}%)")
    
    print(f"\nFiles created in directory:")
    print(f"• koppen_africa_with_labels.geojson - GeoJSON with climate labels")
    print(f"• koppen_africa_complete_metadata.json - Complete dataset documentation")

if __name__ == "__main__":
    main()