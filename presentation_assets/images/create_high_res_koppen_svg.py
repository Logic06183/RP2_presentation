#!/usr/bin/env python3
import rasterio
import numpy as np
import svgwrite
from rasterio.windows import from_bounds
import os
from scipy import ndimage

# Study sites
study_sites = [
    {'name': 'Cape Town', 'lat': -33.9249, 'lon': 18.4241},
    {'name': 'Mount Darwin', 'lat': -16.7833, 'lon': 31.5833}, 
    {'name': 'Blantyre', 'lat': -15.7870, 'lon': 35.0055}
]

# Köppen color mapping from gdalinfo
koppen_colors = {
    1: '#0000FF',   # Af
    2: '#0078FF',   # Am
    3: '#46AAFA',   # Aw
    4: '#FF0000',   # BWh
    5: '#FF9696',   # BWk
    6: '#F5A500',   # BSh
    7: '#FFDC64',   # BSk
    8: '#FFFF00',   # Csa
    9: '#C8C800',   # Csb
    10: '#969600',  # Csc
    11: '#96FF96',  # Cwa
    12: '#64C864',  # Cwb
    13: '#329632',  # Cwc
    14: '#C8FF50',  # Cfa
    15: '#64FF50',  # Cfb
    16: '#32C800',  # Cfc
    17: '#FF00FF',  # Dsa
    18: '#C800C8',  # Dsb
    19: '#963296',  # Dsc
    20: '#966496',  # Dsd
    21: '#AABFFF',  # Dwa
    22: '#5A78DC',  # Dwb
    23: '#4B50B4',  # Dwc
    24: '#320087',  # Dwd
    25: '#00FFFF',  # Dfa
    26: '#37C8FF',  # Dfb
    27: '#007D7D',  # Dfc
    28: '#00465F',  # Dfd
    29: '#B2B2B2',  # ET
    30: '#666666'   # EF
}

def create_high_quality_svg(tif_path, output_path, title, show_sites=True, show_labels=True):
    """Create high-quality SVG from Köppen-Geiger data"""
    
    print(f"Processing {tif_path}...")
    
    with rasterio.open(tif_path) as src:
        # Southern Africa bounds (10°E to 40°E, 35°S to 5°S)
        window = from_bounds(10.0, -35.0, 40.0, -5.0, src.transform)
        data = src.read(1, window=window)
        transform = src.window_transform(window)
        
        height, width = data.shape
        print(f"Data shape: {height}x{width}")
        
        # Get geographic bounds
        west, north = transform * (0, 0)
        east, south = transform * (width, height)
        
    # SVG setup
    svg_width, svg_height = 1200, 900  # Higher resolution
    dwg = svgwrite.Drawing(output_path, size=(svg_width, svg_height), 
                          viewBox=f"0 0 {svg_width} {svg_height}")
    
    # Background
    dwg.add(dwg.rect(insert=(0, 0), size=(svg_width, svg_height), fill='#e6f3ff'))
    
    # Process data in chunks to create smooth boundaries
    pixel_width = svg_width / width
    pixel_height = svg_height / height
    
    # Create climate zone paths by grouping adjacent pixels
    for climate_value in np.unique(data[data > 0]):
        if climate_value in koppen_colors:
            # Find all pixels with this climate type
            mask = (data == climate_value)
            
            # Create path data for this climate zone
            path_data = []
            
            # Find contiguous regions
            for i in range(0, height, 2):  # Skip every other row for efficiency
                for j in range(0, width, 2):  # Skip every other column
                    if mask[i, j]:
                        x = j * pixel_width
                        y = i * pixel_height
                        
                        # Create small rectangle for each pixel
                        rect_size = max(pixel_width, pixel_height) * 2
                        dwg.add(dwg.rect(
                            insert=(x, y),
                            size=(rect_size, rect_size),
                            fill=koppen_colors[climate_value],
                            stroke='none',
                            opacity=0.9
                        ))
    
    # Add study sites
    if show_sites:
        for site in study_sites:
            # Convert lat/lon to SVG coordinates
            x = ((site['lon'] - west) / (east - west)) * svg_width
            y = ((north - site['lat']) / (north - south)) * svg_height
            
            # Site marker with better styling
            dwg.add(dwg.circle(
                center=(x, y),
                r=8,
                fill='#000',
                stroke='#fff',
                stroke_width=3
            ))
            
            # Label if requested
            if show_labels:
                # Add background for better readability
                text_bg = dwg.rect(
                    insert=(x - len(site['name']) * 4, y - 25),
                    size=(len(site['name']) * 8, 18),
                    fill='white',
                    fill_opacity=0.8,
                    stroke='none',
                    rx=3
                )
                dwg.add(text_bg)
                
                dwg.add(dwg.text(
                    site['name'],
                    insert=(x, y - 12),
                    text_anchor='middle',
                    font_family='Arial, sans-serif',
                    font_size='14px',
                    fill='#000',
                    font_weight='bold'
                ))
    
    # Title
    title_bg = dwg.rect(
        insert=(svg_width//2 - len(title) * 6, 10),
        size=(len(title) * 12, 30),
        fill='white',
        fill_opacity=0.9,
        stroke='#ccc',
        rx=5
    )
    dwg.add(title_bg)
    
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
        # Use higher resolution data
        tif_path = os.path.join(base_dir, period_dir, 'koppen_geiger_0p1.tif')
        
        if os.path.exists(tif_path):
            period_name = period_dir.replace('/', '_').replace('-', '_')
            
            # Version 1: Sites only (no labels)
            create_high_quality_svg(
                tif_path,
                os.path.join(output_dir, f'koppen_highres_{period_name}_sites_only.svg'),
                title,
                show_sites=True,
                show_labels=False
            )
            
            # Version 2: Sites with labels
            create_high_quality_svg(
                tif_path,
                os.path.join(output_dir, f'koppen_highres_{period_name}_labeled.svg'),
                title,
                show_sites=True,
                show_labels=True
            )
            
            # Version 3: Clean (no sites)
            create_high_quality_svg(
                tif_path,
                os.path.join(output_dir, f'koppen_highres_{period_name}_clean.svg'),
                title,
                show_sites=False,
                show_labels=False
            )

if __name__ == "__main__":
    main()