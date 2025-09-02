#!/usr/bin/env python3
import rasterio
import numpy as np
import svgwrite
from rasterio.windows import from_bounds
import os

# Köppen-Geiger legend mapping (RGB values)
koppen_colors = {
    1: '#0000FF',   # Af - Tropical rainforest
    2: '#0078FF',   # Am - Tropical monsoon  
    3: '#46AAFA',   # Aw - Tropical savannah
    4: '#FF0000',   # BWh - Arid desert hot
    5: '#FF9696',   # BWk - Arid desert cold
    6: '#F5A500',   # BSh - Arid steppe hot
    7: '#FFDC64',   # BSk - Arid steppe cold
    8: '#FFFF00',   # Csa - Temperate dry summer hot
    9: '#C8C800',   # Csb - Temperate dry summer warm
    10: '#969600',  # Csc - Temperate dry summer cold
    11: '#96FF96',  # Cwa - Temperate dry winter hot
    12: '#64C864',  # Cwb - Temperate dry winter warm
    13: '#329632',  # Cwc - Temperate dry winter cold
    14: '#C8FF50',  # Cfa - Temperate no dry season hot
    15: '#64FF50',  # Cfb - Temperate no dry season warm
    16: '#32C800',  # Cfc - Temperate no dry season cold
    17: '#FF00FF',  # Dsa - Cold dry summer hot
    18: '#C800C8',  # Dsb - Cold dry summer warm
    19: '#963296',  # Dsc - Cold dry summer cold
    20: '#966496',  # Dsd - Cold dry summer very cold
    21: '#AABFFF',  # Dwa - Cold dry winter hot
    22: '#5A78DC',  # Dwb - Cold dry winter warm
    23: '#4B50B4',  # Dwc - Cold dry winter cold
    24: '#320087',  # Dwd - Cold dry winter very cold
    25: '#00FFFF',  # Dfa - Cold no dry season hot
    26: '#37C8FF',  # Dfb - Cold no dry season warm
    27: '#007D7D',  # Dfc - Cold no dry season cold
    28: '#00465F',  # Dfd - Cold no dry season very cold
    29: '#B2B2B2',  # ET - Polar tundra
    30: '#666666'   # EF - Polar frost
}

# Study sites
study_sites = [
    {'name': 'Cape Town', 'lat': -33.9249, 'lon': 18.4241},
    {'name': 'Mount Darwin', 'lat': -16.7833, 'lon': 31.5833}, 
    {'name': 'Blantyre', 'lat': -15.7870, 'lon': 35.0055}
]

def create_optimized_svg(tif_path, output_path, title, show_sites=True, show_labels=True):
    """Create optimized SVG using simplified polygons"""
    
    print(f"Processing {tif_path}...")
    
    with rasterio.open(tif_path) as src:
        # Focus on Southern Africa region
        window = from_bounds(10.0, -35.0, 40.0, -5.0, src.transform)
        data = src.read(1, window=window)
        transform = src.window_transform(window)
        
        # Reduce resolution for efficiency
        data = data[::4, ::4]  # Sample every 4th pixel
        height, width = data.shape
        
    # SVG dimensions
    svg_width, svg_height = 800, 600
    dwg = svgwrite.Drawing(output_path, size=(svg_width, svg_height))
    
    # Add background
    dwg.add(dwg.rect(insert=(0, 0), size=(svg_width, svg_height), fill='#e6f2ff'))
    
    # Group similar climate zones into larger polygons
    unique_values = np.unique(data[data > 0])
    
    for value in unique_values:
        if value in koppen_colors:
            # Find all pixels with this climate type
            mask = (data == value)
            y_coords, x_coords = np.where(mask)
            
            if len(y_coords) > 0:
                # Create simplified polygon using convex hull approach
                for i in range(0, len(y_coords), 50):  # Sample points
                    y, x = y_coords[i], x_coords[i]
                    
                    # Convert to SVG coordinates
                    svg_x = (x / width) * svg_width
                    svg_y = (y / height) * svg_height
                    
                    # Create small rectangles for climate zones
                    rect_size = max(2, svg_width / width * 4)
                    dwg.add(dwg.rect(
                        insert=(svg_x - rect_size/2, svg_y - rect_size/2),
                        size=(rect_size, rect_size),
                        fill=koppen_colors[value],
                        stroke='none',
                        opacity=0.8
                    ))
    
    # Add study sites
    if show_sites:
        for site in study_sites:
            # Convert lat/lon to SVG coordinates (approximate)
            svg_x = ((site['lon'] - 10.0) / 30.0) * svg_width
            svg_y = (((-5.0) - site['lat']) / 30.0) * svg_height
            
            # Site marker
            dwg.add(dwg.circle(
                center=(svg_x, svg_y),
                r=6,
                fill='black',
                stroke='white',
                stroke_width=2
            ))
            
            # Label if requested
            if show_labels:
                dwg.add(dwg.text(
                    site['name'],
                    insert=(svg_x, svg_y - 12),
                    text_anchor='middle',
                    font_family='Arial, sans-serif',
                    font_size='12px',
                    fill='black',
                    font_weight='bold'
                ))
    
    # Title
    dwg.add(dwg.text(
        title,
        insert=(svg_width // 2, 25),
        text_anchor='middle',
        font_family='Arial, sans-serif',
        font_size='16px',
        fill='#333',
        font_weight='bold'
    ))
    
    dwg.save()
    print(f"Created {output_path}")

def main():
    base_dir = "/Users/craig/Library/Mobile Documents/com~apple~CloudDocs/RP2_presentation/presentation_assets/images/koppen_extracted"
    output_dir = "/Users/craig/Library/Mobile Documents/com~apple~CloudDocs/RP2_presentation/presentation_assets/images"
    
    periods = [
        ('1991_2020', '1991-2020 (Baseline)'),
        ('2041_2070/ssp126', '2041-2070 (SSP1-2.6)'),
        ('2071_2099/ssp126', '2071-2099 (SSP1-2.6)')
    ]
    
    for period_dir, title in periods:
        tif_path = os.path.join(base_dir, period_dir, 'koppen_geiger_0p1.tif')
        
        if os.path.exists(tif_path):
            period_name = period_dir.replace('/', '_').replace('-', '_')
            
            # Version 1: Sites only
            create_optimized_svg(
                tif_path,
                os.path.join(output_dir, f'koppen_{period_name}_sites_only.svg'),
                title,
                show_sites=True,
                show_labels=False
            )
            
            # Version 2: Sites with labels  
            create_optimized_svg(
                tif_path,
                os.path.join(output_dir, f'koppen_{period_name}_labeled.svg'),
                title,
                show_sites=True,
                show_labels=True
            )
            
            # Version 3: Clean
            create_optimized_svg(
                tif_path,
                os.path.join(output_dir, f'koppen_{period_name}_clean.svg'),
                title,
                show_sites=False,
                show_labels=False
            )

if __name__ == "__main__":
    main()