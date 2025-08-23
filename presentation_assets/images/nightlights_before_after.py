#!/usr/bin/env python3
"""
Simple Before/After Nighttime Lights Visualization using geemap
Shows urbanization changes at Abidjan and Johannesburg study sites
"""

import geemap
import ee
import matplotlib.pyplot as plt

# Initialize GEE
GCP_PROJECT = 'joburg-hvi'

def initialize_gee():
    """Initialize Google Earth Engine"""
    try:
        ee.Initialize(project=GCP_PROJECT)
        print(f"✅ Google Earth Engine initialized")
        return True
    except:
        try:
            ee.Authenticate()
            ee.Initialize(project=GCP_PROJECT)
            print(f"✅ GEE authenticated and initialized")
            return True
        except Exception as e:
            print(f"❌ GEE failed: {e}")
            return False

def create_before_after_maps():
    """Create before/after nighttime lights maps"""
    
    # Study locations
    abidjan = ee.Geometry.Point([-4.024429, 5.345317])
    johannesburg = ee.Geometry.Point([28.034088, -26.195246])
    
    # Create study areas (50km radius)
    abidjan_area = abidjan.buffer(50000)
    johannesburg_area = johannesburg.buffer(50000)
    
    # Combine both areas for map extent
    combined_area = ee.Geometry.MultiPoint([
        [-4.024429, 5.345317],
        [28.034088, -26.195246]
    ]).buffer(300000)  # 300km buffer for context
    
    # Load VIIRS nighttime lights
    viirs = ee.ImageCollection("NOAA/VIIRS/DNB/MONTHLY_V1/VCMSLCFG").select('avg_rad')
    
    # Create before/after composites
    before_period = viirs.filterDate('2014-01-01', '2016-12-31').median()  # Early period
    after_period = viirs.filterDate('2021-01-01', '2023-12-31').median()   # Recent period
    
    # Visualization parameters
    vis_params = {
        'min': 0,
        'max': 30,
        'palette': [
            '000000',  # Black (no lights)
            '0D1B2A',  # Very dark blue
            '1B263B',  # Dark blue
            '415A77',  # Blue-gray
            '778DA9',  # Light blue-gray
            'E0E1DD',  # Light gray
            'FFF3B0',  # Light yellow
            'FFCF70',  # Yellow
            'FF8500',  # Orange
            'FF5722'   # Red-orange (brightest)
        ]
    }
    
    # Create split panel map
    Map = geemap.Map(center=[10, 15], zoom=3)
    
    # Add before/after layers
    Map.addLayer(before_period.clip(combined_area), vis_params, 'Nightlights 2014-2016 (Before)', True, 0.8)
    Map.addLayer(after_period.clip(combined_area), vis_params, 'Nightlights 2021-2023 (After)', False, 0.8)
    
    # Add study locations
    Map.addLayer(abidjan_area, {'color': '#E3120B'}, 'Abidjan Study Area', True, 0.3)
    Map.addLayer(johannesburg_area, {'color': '#2196F3'}, 'Johannesburg Study Area', True, 0.3)
    
    # Add center points
    Map.addLayer(abidjan, {'color': '#E3120B'}, 'Abidjan Center', True)
    Map.addLayer(johannesburg, {'color': '#2196F3'}, 'Johannesburg Center', True)
    
    # Add colorbar (simplified)
    try:
        Map.add_colorbar(vis_params=vis_params, caption='Light Radiance')
    except:
        print("   Note: Colorbar creation skipped (display issue)")
    
    # Add layer control
    Map.add_layer_control()
    
    return Map, before_period, after_period

def create_side_by_side_comparison():
    """Create side-by-side comparison maps"""
    
    # Study locations
    abidjan = [-4.024429, 5.345317]
    johannesburg = [28.034088, -26.195246]
    
    # Load VIIRS data
    viirs = ee.ImageCollection("NOAA/VIIRS/DNB/MONTHLY_V1/VCMSLCFG").select('avg_rad')
    
    # Before/after periods
    before = viirs.filterDate('2014-01-01', '2016-12-31').median()
    after = viirs.filterDate('2021-01-01', '2023-12-31').median()
    
    # Visualization parameters - more vibrant for presentation
    vis_params = {
        'min': 0,
        'max': 25,
        'palette': ['000000', '1a1a2e', '16213e', '0f3460', '533483', 
                   '7209b7', 'a663cc', 'ffffff', 'ffff00', 'ff6600']
    }
    
    # Create individual maps for each location
    maps = {}
    
    for city, coords in [('Abidjan', abidjan), ('Johannesburg', johannesburg)]:
        # Create region of interest
        point = ee.Geometry.Point(coords)
        region = point.buffer(60000)  # 60km radius
        
        # Create before map
        map_before = geemap.Map(center=coords, zoom=10)
        map_before.addLayer(before.clip(region), vis_params, f'{city} 2014-2016', True, 0.9)
        map_before.addLayer(point, {'color': '#FF0000'}, f'{city} Center', True)
        try:
            map_before.add_colorbar(vis_params=vis_params, caption='Light Radiance')
        except:
            pass
        
        # Create after map  
        map_after = geemap.Map(center=coords, zoom=10)
        map_after.addLayer(after.clip(region), vis_params, f'{city} 2021-2023', True, 0.9)
        map_after.addLayer(point, {'color': '#FF0000'}, f'{city} Center', True)
        try:
            map_after.add_colorbar(vis_params=vis_params, caption='Light Radiance')
        except:
            pass
        
        maps[f'{city}_before'] = map_before
        maps[f'{city}_after'] = map_after
    
    return maps

def create_difference_map():
    """Create a map showing the difference between before and after"""
    
    # Load VIIRS data
    viirs = ee.ImageCollection("NOAA/VIIRS/DNB/MONTHLY_V1/VCMSLCFG").select('avg_rad')
    
    # Before/after periods
    before = viirs.filterDate('2014-01-01', '2016-12-31').median()
    after = viirs.filterDate('2021-01-01', '2023-12-31').median()
    
    # Calculate difference (after - before)
    difference = after.subtract(before)
    
    # Study locations
    abidjan = ee.Geometry.Point([-4.024429, 5.345317])
    johannesburg = ee.Geometry.Point([28.034088, -26.195246])
    
    # Create combined region
    combined_region = ee.Geometry.MultiPoint([
        [-4.024429, 5.345317],
        [28.034088, -26.195246]
    ]).buffer(200000)
    
    # Difference visualization (red = increase, blue = decrease)
    diff_vis = {
        'min': -5,
        'max': 5,
        'palette': ['0000FF', '4444FF', '8888FF', 'FFFFFF', 'FF8888', 'FF4444', 'FF0000']
    }
    
    # Create map
    Map = geemap.Map(center=[10, 15], zoom=3)
    Map.addLayer(difference.clip(combined_region), diff_vis, 'Nightlight Change (2023 - 2014)', True, 0.8)
    
    # Add study areas
    Map.addLayer(abidjan.buffer(50000), {'color': '#E3120B'}, 'Abidjan Study Area', True, 0.3)
    Map.addLayer(johannesburg.buffer(50000), {'color': '#2196F3'}, 'Johannesburg Study Area', True, 0.3)
    
    # Add center points
    Map.addLayer(abidjan, {'color': '#E3120B'}, 'Abidjan', True)
    Map.addLayer(johannesburg, {'color': '#2196F3'}, 'Johannesburg', True)
    
    # Add colorbar
    try:
        Map.add_colorbar(vis_params=diff_vis, caption='Change in Light Radiance')
    except:
        print("   Note: Colorbar creation skipped")
    Map.add_layer_control()
    
    return Map

def main():
    """Create all nighttime lights visualizations"""
    
    print("🌃 Creating Nighttime Lights Before/After Visualizations")
    print("=" * 60)
    
    # Initialize GEE
    if not initialize_gee():
        return
    
    print("1. Creating overview before/after map...")
    overview_map, before_img, after_img = create_before_after_maps()
    overview_map.to_html('nightlights_overview_map.html')
    print("   ✅ Saved: nightlights_overview_map.html")
    
    print("\n2. Creating side-by-side city comparisons...")
    city_maps = create_side_by_side_comparison()
    
    # Save individual city maps
    city_maps['Abidjan_before'].to_html('abidjan_before_2014-2016.html')
    city_maps['Abidjan_after'].to_html('abidjan_after_2021-2023.html')
    city_maps['Johannesburg_before'].to_html('johannesburg_before_2014-2016.html')
    city_maps['Johannesburg_after'].to_html('johannesburg_after_2021-2023.html')
    
    print("   ✅ Saved: abidjan_before_2014-2016.html")
    print("   ✅ Saved: abidjan_after_2021-2023.html") 
    print("   ✅ Saved: johannesburg_before_2014-2016.html")
    print("   ✅ Saved: johannesburg_after_2021-2023.html")
    
    print("\n3. Creating change detection map...")
    change_map = create_difference_map()
    change_map.to_html('nightlights_change_map.html')
    print("   ✅ Saved: nightlights_change_map.html")
    
    print(f"\n🎉 ALL MAPS CREATED SUCCESSFULLY!")
    print("\nGenerated Files:")
    print("📄 nightlights_overview_map.html - Toggle before/after layers")
    print("📄 abidjan_before_2014-2016.html - Abidjan early period")
    print("📄 abidjan_after_2021-2023.html - Abidjan recent period") 
    print("📄 johannesburg_before_2014-2016.html - Johannesburg early period")
    print("📄 johannesburg_after_2021-2023.html - Johannesburg recent period")
    print("📄 nightlights_change_map.html - Change detection (red=growth, blue=decline)")
    
    print(f"\n💡 USAGE:")
    print("• Open HTML files in browser for interactive maps")
    print("• Toggle layers in overview map to see before/after")
    print("• Change map shows urbanization patterns clearly")
    print("• Red areas = increasing lights (urbanization)")
    print("• Blue areas = decreasing lights")
    print("• Perfect for presentations!")

if __name__ == "__main__":
    main()