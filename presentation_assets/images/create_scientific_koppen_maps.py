#!/usr/bin/env python3
import rasterio
import numpy as np
import svgwrite
from rasterio.windows import from_bounds
from rasterio.features import shapes
from shapely.geometry import shape
from shapely.ops import unary_union
import os

# Study sites
study_sites = [
    {'name': 'Cape Town', 'lat': -33.9249, 'lon': 18.4241},
    {'name': 'Mount Darwin', 'lat': -16.7833, 'lon': 31.5833}, 
    {'name': 'Blantyre', 'lat': -15.7870, 'lon': 35.0055}
]

# Köppen-Geiger colors matching the scientific reference
koppen_colors = {
    # Tropical (A) - Blues/Greens
    1: '#0f4c75',   # Af - Tropical rainforest (dark blue)
    2: '#3282b8',   # Am - Tropical monsoon (medium blue)  
    3: '#bbe1fa',   # Aw - Tropical savannah (light blue)
    
    # Arid (B) - Reds/Oranges/Yellows
    4: '#dc143c',   # BWh - Hot desert (dark red)
    5: '#ff6b6b',   # BWk - Cold desert (light red)
    6: '#ff8c00',   # BSh - Hot semi-arid (orange)
    7: '#ffdd44',   # BSk - Cold semi-arid (yellow)
    
    # Temperate (C) - Greens
    8: '#90ee90',   # Csa - Mediterranean hot summer (light green)
    9: '#32cd32',   # Csb - Mediterranean warm summer (lime green)
    10: '#228b22',  # Csc - Mediterranean cold summer (forest green)
    11: '#98fb98',  # Cwa - Humid subtropical (pale green)
    12: '#66cdaa',  # Cwb - Subtropical highland (medium sea green)
    13: '#2e8b57',  # Cwc - Temperate dry winter cold (sea green)
    14: '#7fff00',  # Cfa - Humid subtropical no dry season (chartreuse)
    15: '#adff2f',  # Cfb - Oceanic (green yellow)
    16: '#9acd32',  # Cfc - Subpolar oceanic (yellow green)
    
    # Continental (D) - Cyans/Light Blues
    17: '#ff00ff',  # Dsa - Continental dry summer hot (magenta)
    18: '#ba55d3',  # Dsb - Continental dry summer warm (medium orchid)
    19: '#9370db',  # Dsc - Continental dry summer cold (medium purple)
    20: '#8a2be2',  # Dsd - Continental dry summer very cold (blue violet)
    21: '#87ceeb',  # Dwa - Continental dry winter hot (sky blue)
    22: '#4682b4',  # Dwb - Continental dry winter warm (steel blue)
    23: '#1e90ff',  # Dwc - Continental dry winter cold (dodger blue)
    24: '#0000cd',  # Dwd - Continental dry winter very cold (medium blue)
    25: '#00ffff',  # Dfa - Continental humid hot summer (cyan)
    26: '#40e0d0',  # Dfb - Continental humid warm summer (turquoise)
    27: '#008b8b',  # Dfc - Subarctic (dark cyan)
    28: '#2f4f4f',  # Dfd - Subarctic very cold (dark slate gray)
    
    # Polar (E) - Grays
    29: '#d3d3d3',  # ET - Tundra (light gray)
    30: '#696969'   # EF - Ice cap (dim gray)
}

# Legend groups matching scientific classification
legend_groups = {
    'A - Tropical': {
        'color': '#0f4c75',
        'codes': [
            ('Af', 'Tropical rainforest', 1),
            ('Am', 'Tropical monsoon', 2),
            ('Aw', 'Tropical savannah', 3)
        ]
    },
    'B - Arid': {
        'color': '#ff8c00', 
        'codes': [
            ('BWh', 'Hot desert', 4),
            ('BWk', 'Cold desert', 5),
            ('BSh', 'Hot semi-arid', 6),
            ('BSk', 'Cold semi-arid', 7)
        ]
    },
    'C - Temperate': {
        'color': '#32cd32',
        'codes': [
            ('Csa', 'Mediterranean hot summer', 8),
            ('Csb', 'Mediterranean warm summer', 9),
            ('Cwa', 'Humid subtropical', 11),
            ('Cwb', 'Subtropical highland', 12),
            ('Cfa', 'Humid subtropical', 14),
            ('Cfb', 'Oceanic', 15)
        ]
    },
    'D - Cold': {
        'color': '#87ceeb',
        'codes': [
            ('Dwa', 'Cold dry winter', 21),
            ('Dwb', 'Cold dry winter warm', 22),
            ('Dfa', 'Cold humid hot summer', 25),
            ('Dfb', 'Cold humid warm summer', 26)
        ]
    },
    'E - Polar': {
        'color': '#d3d3d3',
        'codes': [
            ('ET', 'Tundra', 29),
            ('EF', 'Ice cap', 30)
        ]
    }
}

def coords_to_svg(lon, lat, west, east, north, south, svg_width, svg_height):
    """Convert geographic coordinates to SVG coordinates"""
    x = ((lon - west) / (east - west)) * svg_width
    y = ((north - lat) / (north - south)) * svg_height
    return x, y

def create_svg_path(polygon, west, east, north, south, svg_width, svg_height):
    """Convert shapely polygon to SVG path"""
    try:
        if polygon.is_empty or polygon.area < 0.001:
            return None
            
        coords = list(polygon.exterior.coords)
        if not coords:
            return None
            
        path_data = []
        for i, (lon, lat) in enumerate(coords):
            x, y = coords_to_svg(lon, lat, west, east, north, south, svg_width, svg_height)
            if i == 0:
                path_data.append(f"M {x:.1f} {y:.1f}")
            else:
                path_data.append(f"L {x:.1f} {y:.1f}")
        
        path_data.append("Z")
        return " ".join(path_data)
        
    except Exception:
        return None

def create_scientific_layout(tif_paths, output_path, show_sites=True, show_labels=True):
    """Create scientific 3-panel layout"""
    
    # SVG setup - wider layout for 3 maps
    total_width, total_height = 1800, 1200
    map_width, map_height = 500, 600
    margin = 50
    
    dwg = svgwrite.Drawing(output_path, size=(total_width, total_height))
    
    # White background
    dwg.add(dwg.rect(insert=(0, 0), size=(total_width, total_height), fill='white'))
    
    # Process each time period
    titles = ['Current Climate\n1991-2020 Baseline', 'Moderate Warming\nSSP1-2.6 2041-2070', 'Extreme Warming\nSSP1-2.6 2071-2099']
    scenario_colors = ['#2d5a3d', '#cc7a00', '#cc1f36']  # Green, Orange, Red
    
    for i, (tif_path, title, color) in enumerate(zip(tif_paths, titles, scenario_colors)):
        if not os.path.exists(tif_path):
            print(f"Skipping {tif_path} - file not found")
            continue
            
        x_offset = margin + i * (map_width + margin)
        y_offset = margin + 50
        
        print(f"Processing {tif_path}...")
        
        with rasterio.open(tif_path) as src:
            # Southern Africa bounds
            window = from_bounds(10.0, -35.0, 40.0, -5.0, src.transform)
            data = src.read(1, window=window)
            transform = src.window_transform(window)
            
            height, width = data.shape
            west, north = transform * (0, 0)
            east, south = transform * (width, height)
        
        # Create group for this map
        map_group = dwg.g(id=f'map_{i}')
        
        # Map background
        map_group.add(dwg.rect(
            insert=(x_offset, y_offset),
            size=(map_width, map_height),
            fill='#f8f9fa',
            stroke='#dee2e6',
            stroke_width=1
        ))
        
        # Process climate zones with reduced sampling for performance
        sample_factor = max(1, width // 500)  # Adaptive sampling
        
        for climate_value in sorted(np.unique(data[data > 0])):
            if climate_value in koppen_colors:
                mask = (data == climate_value).astype(np.uint8)
                
                # Extract polygons
                try:
                    polygon_gen = shapes(mask, mask=mask, transform=transform)
                    polygons = []
                    
                    for geom, value in polygon_gen:
                        if value == 1:
                            poly = shape(geom)
                            if poly.area > 0.01:  # Filter small polygons
                                polygons.append(poly)
                    
                    if polygons:
                        merged = unary_union(polygons)
                        
                        if hasattr(merged, 'geoms'):
                            for poly in merged.geoms:
                                svg_path = create_svg_path(poly, west, east, north, south, map_width, map_height)
                                if svg_path:
                                    map_group.add(dwg.path(
                                        d=svg_path,
                                        fill=koppen_colors[climate_value],
                                        stroke='none',
                                        transform=f'translate({x_offset}, {y_offset})'
                                    ))
                        else:
                            svg_path = create_svg_path(merged, west, east, north, south, map_width, map_height)
                            if svg_path:
                                map_group.add(dwg.path(
                                    d=svg_path,
                                    fill=koppen_colors[climate_value],
                                    stroke='none',
                                    transform=f'translate({x_offset}, {y_offset})'
                                ))
                                
                except Exception as e:
                    print(f"Error processing zone {climate_value}: {e}")
        
        # Add study sites
        if show_sites:
            for site in study_sites:
                x, y = coords_to_svg(site['lon'], site['lat'], west, east, north, south, map_width, map_height)
                
                # Site marker
                map_group.add(dwg.circle(
                    center=(x_offset + x, y_offset + y),
                    r=6,
                    fill='white',
                    stroke='black',
                    stroke_width=2
                ))
                
                # Label if requested
                if show_labels:
                    map_group.add(dwg.text(
                        site['name'],
                        insert=(x_offset + x, y_offset + y - 12),
                        text_anchor='middle',
                        font_family='Arial, sans-serif',
                        font_size='12px',
                        fill='black',
                        font_weight='bold'
                    ))
        
        # Map title with colored box
        title_y = y_offset - 30
        map_group.add(dwg.rect(
            insert=(x_offset, title_y - 20),
            size=(map_width, 25),
            fill=color,
            opacity=0.8
        ))
        
        map_group.add(dwg.text(
            title.split('\n')[0],
            insert=(x_offset + map_width//2, title_y - 5),
            text_anchor='middle',
            font_family='Arial, sans-serif',
            font_size='14px',
            fill='white',
            font_weight='bold'
        ))
        
        map_group.add(dwg.text(
            title.split('\n')[1],
            insert=(x_offset + map_width//2, title_y + 10),
            text_anchor='middle',
            font_family='Arial, sans-serif',
            font_size='12px',
            fill='white'
        ))
        
        dwg.add(map_group)
    
    # Add Köppen-Geiger Classification legend
    legend_y = map_height + margin + 100
    
    # Main legend title
    dwg.add(dwg.text(
        'Köppen-Geiger Climate Classification',
        insert=(total_width // 2, legend_y),
        text_anchor='middle',
        font_family='Arial, sans-serif',
        font_size='20px',
        fill='black',
        font_weight='bold'
    ))
    
    # Legend groups
    legend_y += 40
    group_width = total_width // len(legend_groups)
    
    for i, (group_name, group_data) in enumerate(legend_groups.items()):
        group_x = i * group_width + margin
        
        # Group title
        dwg.add(dwg.text(
            group_name,
            insert=(group_x + group_width//2, legend_y),
            text_anchor='middle',
            font_family='Arial, sans-serif',
            font_size='14px',
            fill='black',
            font_weight='bold'
        ))
        
        # Legend items
        item_y = legend_y + 25
        for code, description, value in group_data['codes']:
            if value in koppen_colors:
                # Color square
                dwg.add(dwg.rect(
                    insert=(group_x + 20, item_y - 8),
                    size=(15, 12),
                    fill=koppen_colors[value],
                    stroke='#333',
                    stroke_width=0.5
                ))
                
                # Text
                dwg.add(dwg.text(
                    f'{code} - {description}',
                    insert=(group_x + 45, item_y),
                    font_family='Arial, sans-serif',
                    font_size='11px',
                    fill='black'
                ))
                
                item_y += 18
    
    # Data source citation
    citation_y = total_height - 60
    dwg.add(dwg.text(
        'Data Source',
        insert=(total_width // 2, citation_y),
        text_anchor='middle',
        font_family='Arial, sans-serif',
        font_size='14px',
        fill='black',
        font_weight='bold'
    ))
    
    dwg.add(dwg.text(
        'Beck, H.E. et al. (2023). High-resolution (1 km) Köppen-Geiger maps for 1901–2099 based on constrained CMIP6 projections. Scientific Data 10, 724.',
        insert=(total_width // 2, citation_y + 20),
        text_anchor='middle',
        font_family='Arial, sans-serif',
        font_size='10px',
        fill='#666'
    ))
    
    dwg.add(dwg.text(
        'DOI: 10.1038/s41597-023-02549-6',
        insert=(total_width // 2, citation_y + 35),
        text_anchor='middle',
        font_family='Arial, sans-serif',
        font_size='10px',
        fill='#666'
    ))
    
    dwg.save()
    print(f"Created scientific layout: {output_path}")

def main():
    base_dir = "/Users/craig/Library/Mobile Documents/com~apple~CloudDocs/RP2_presentation/presentation_assets/images/koppen_extracted"
    output_dir = "/Users/craig/Library/Mobile Documents/com~apple~CloudDocs/RP2_presentation/presentation_assets/images"
    
    # File paths for the three time periods
    tif_paths = [
        os.path.join(base_dir, '1991_2020', 'koppen_geiger_0p1.tif'),
        os.path.join(base_dir, '2041_2070/ssp126', 'koppen_geiger_0p1.tif'),
        os.path.join(base_dir, '2071_2099/ssp126', 'koppen_geiger_0p1.tif')
    ]
    
    # Create versions with different labeling
    create_scientific_layout(
        tif_paths,
        os.path.join(output_dir, 'koppen_scientific_sites_only.svg'),
        show_sites=True,
        show_labels=False
    )
    
    create_scientific_layout(
        tif_paths,
        os.path.join(output_dir, 'koppen_scientific_labeled.svg'),
        show_sites=True,
        show_labels=True
    )
    
    create_scientific_layout(
        tif_paths,
        os.path.join(output_dir, 'koppen_scientific_clean.svg'),
        show_sites=False,
        show_labels=False
    )

if __name__ == "__main__":
    main()