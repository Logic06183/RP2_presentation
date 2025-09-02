#!/usr/bin/env python3
import rasterio
import numpy as np
import matplotlib.pyplot as plt
import matplotlib.patches as patches
from matplotlib.collections import PatchCollection
import svgwrite
from rasterio.warp import calculate_default_transform, reproject, Resampling
from rasterio.windows import from_bounds
import os

# Köppen-Geiger legend mapping
koppen_legend = {
    1: ('Af', [0, 0, 255]),      # Tropical, rainforest
    2: ('Am', [0, 120, 255]),    # Tropical, monsoon
    3: ('Aw', [70, 170, 250]),   # Tropical, savannah
    4: ('BWh', [255, 0, 0]),     # Arid, desert, hot
    5: ('BWk', [255, 150, 150]), # Arid, desert, cold
    6: ('BSh', [245, 165, 0]),   # Arid, steppe, hot
    7: ('BSk', [255, 220, 100]), # Arid, steppe, cold
    8: ('Csa', [255, 255, 0]),   # Temperate, dry summer, hot summer
    9: ('Csb', [200, 200, 0]),   # Temperate, dry summer, warm summer
    10: ('Csc', [150, 150, 0]),  # Temperate, dry summer, cold summer
    11: ('Cwa', [150, 255, 150]), # Temperate, dry winter, hot summer
    12: ('Cwb', [100, 200, 100]), # Temperate, dry winter, warm summer
    13: ('Cwc', [50, 150, 50]),   # Temperate, dry winter, cold summer
    14: ('Cfa', [200, 255, 80]),  # Temperate, no dry season, hot summer
    15: ('Cfb', [100, 255, 80]),  # Temperate, no dry season, warm summer
    16: ('Cfc', [50, 200, 0]),    # Temperate, no dry season, cold summer
    17: ('Dsa', [255, 0, 255]),   # Cold, dry summer, hot summer
    18: ('Dsb', [200, 0, 200]),   # Cold, dry summer, warm summer
    19: ('Dsc', [150, 50, 150]),  # Cold, dry summer, cold summer
    20: ('Dsd', [150, 100, 150]), # Cold, dry summer, very cold winter
    21: ('Dwa', [170, 175, 255]), # Cold, dry winter, hot summer
    22: ('Dwb', [90, 120, 220]),  # Cold, dry winter, warm summer
    23: ('Dwc', [75, 80, 180]),   # Cold, dry winter, cold summer
    24: ('Dwd', [50, 0, 135]),    # Cold, dry winter, very cold winter
    25: ('Dfa', [0, 255, 255]),   # Cold, no dry season, hot summer
    26: ('Dfb', [55, 200, 255]),  # Cold, no dry season, warm summer
    27: ('Dfc', [0, 125, 125]),   # Cold, no dry season, cold summer
    28: ('Dfd', [0, 70, 95]),     # Cold, no dry season, very cold winter
    29: ('ET', [178, 178, 178]),  # Polar, tundra
    30: ('EF', [102, 102, 102])   # Polar, frost
}

# Study sites
study_sites = [
    {'name': 'Cape Town', 'lat': -33.9249, 'lon': 18.4241},
    {'name': 'Mount Darwin', 'lat': -16.7833, 'lon': 31.5833},
    {'name': 'Blantyre', 'lat': -15.7870, 'lon': 35.0055}
]

# Southern Africa bounds
south_africa_bounds = {
    'west': 10.0,   # Western longitude
    'east': 40.0,   # Eastern longitude  
    'south': -35.0, # Southern latitude
    'north': -5.0   # Northern latitude
}

def create_svg_from_tif(tif_path, output_path, title, show_sites=True, show_labels=True):
    """Create SVG map from Köppen-Geiger TIF file"""
    
    with rasterio.open(tif_path) as src:
        # Read the window for Southern Africa
        window = from_bounds(
            south_africa_bounds['west'], 
            south_africa_bounds['south'],
            south_africa_bounds['east'], 
            south_africa_bounds['north'],
            src.transform
        )
        
        # Read data from the window
        data = src.read(1, window=window)
        transform = src.window_transform(window)
        
        # Get coordinates
        height, width = data.shape
        west, north = transform * (0, 0)
        east, south = transform * (width, height)
        
    # Create SVG
    svg_width, svg_height = 800, 600
    dwg = svgwrite.Drawing(output_path, size=(svg_width, svg_height))
    
    # Add background
    dwg.add(dwg.rect(insert=(0, 0), size=(svg_width, svg_height), fill='#e6f2ff'))
    
    # Calculate pixel size in SVG coordinates
    lon_range = east - west
    lat_range = north - south
    pixel_width = svg_width / width
    pixel_height = svg_height / height
    
    # Draw climate zones
    for i in range(height):
        for j in range(width):
            value = data[i, j]
            if value > 0 and value in koppen_legend:
                _, rgb = koppen_legend[value]
                color = f'rgb({rgb[0]},{rgb[1]},{rgb[2]})'
                
                x = j * pixel_width
                y = i * pixel_height
                
                dwg.add(dwg.rect(
                    insert=(x, y),
                    size=(pixel_width, pixel_height),
                    fill=color,
                    stroke='none'
                ))
    
    # Add study sites if requested
    if show_sites:
        for site in study_sites:
            # Convert lat/lon to SVG coordinates
            x = ((site['lon'] - west) / lon_range) * svg_width
            y = ((north - site['lat']) / lat_range) * svg_height
            
            # Add site marker
            dwg.add(dwg.circle(
                center=(x, y),
                r=8,
                fill='black',
                stroke='white',
                stroke_width=2
            ))
            
            # Add label if requested
            if show_labels:
                dwg.add(dwg.text(
                    site['name'],
                    insert=(x, y - 15),
                    text_anchor='middle',
                    font_family='Arial, sans-serif',
                    font_size='14px',
                    fill='black',
                    font_weight='bold'
                ))
    
    # Add title
    dwg.add(dwg.text(
        title,
        insert=(svg_width // 2, 30),
        text_anchor='middle',
        font_family='Arial, sans-serif',
        font_size='18px',
        fill='#333',
        font_weight='bold'
    ))
    
    dwg.save()

def main():
    base_dir = "/Users/craig/Library/Mobile Documents/com~apple~CloudDocs/RP2_presentation/presentation_assets/images/koppen_extracted"
    output_dir = "/Users/craig/Library/Mobile Documents/com~apple~CloudDocs/RP2_presentation/presentation_assets/images"
    
    # Time periods and their corresponding files
    periods = [
        ('1991_2020', '1991-2020 (Baseline)'),
        ('2041_2070/ssp126', '2041-2070 (SSP1-2.6)'),
        ('2071_2099/ssp126', '2071-2099 (SSP1-2.6)')
    ]
    
    for period_dir, title in periods:
        tif_path = os.path.join(base_dir, period_dir, 'koppen_geiger_0p1.tif')
        
        if os.path.exists(tif_path):
            period_name = period_dir.replace('/', '_').replace('-', '_')
            
            # Version 1: Sites only (no labels)
            create_svg_from_tif(
                tif_path, 
                os.path.join(output_dir, f'koppen_{period_name}_sites_only.svg'),
                title,
                show_sites=True,
                show_labels=False
            )
            
            # Version 2: Sites with labels
            create_svg_from_tif(
                tif_path,
                os.path.join(output_dir, f'koppen_{period_name}_labeled.svg'),
                title,
                show_sites=True,
                show_labels=True
            )
            
            # Version 3: Clean (no sites)
            create_svg_from_tif(
                tif_path,
                os.path.join(output_dir, f'koppen_{period_name}_clean.svg'),
                title,
                show_sites=False,
                show_labels=False
            )
            
            print(f"Created SVG maps for {title}")
        else:
            print(f"File not found: {tif_path}")

if __name__ == "__main__":
    main()