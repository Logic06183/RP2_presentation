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

# Standard Köppen-Geiger colors (Peel et al. standard)
koppen_colors = {
    # Tropical (A) - Blues
    1: '#0000FE',   # Af - Tropical rainforest
    2: '#0078FF',   # Am - Tropical monsoon
    3: '#46AAFA',   # Aw - Tropical savannah
    
    # Arid (B) - Reds/Oranges  
    4: '#FF0000',   # BWh - Hot desert
    5: '#FF9696',   # BWk - Cold desert
    6: '#F5A500',   # BSh - Hot semi-arid
    7: '#FFDC64',   # BSk - Cold semi-arid
    
    # Temperate (C) - Greens/Yellows
    8: '#FFFF00',   # Csa - Mediterranean hot summer
    9: '#C8C800',   # Csb - Mediterranean warm summer
    10: '#969600',  # Csc - Mediterranean cold summer
    11: '#96FF96',  # Cwa - Humid subtropical
    12: '#64C864',  # Cwb - Subtropical highland  
    13: '#329632',  # Cwc - Temperate dry winter cold
    14: '#C8FF50',  # Cfa - Humid subtropical no dry season
    15: '#64FF50',  # Cfb - Oceanic
    16: '#32C800',  # Cfc - Subpolar oceanic
    
    # Continental (D) - Cyans/Purples
    17: '#FF00FF',  # Dsa - Continental dry summer hot
    18: '#C800C8',  # Dsb - Continental dry summer warm
    19: '#963296',  # Dsc - Continental dry summer cold
    20: '#966496',  # Dsd - Continental dry summer very cold
    21: '#AABFFF',  # Dwa - Continental dry winter hot
    22: '#5A78DC',  # Dwb - Continental dry winter warm
    23: '#4B50B4',  # Dwc - Continental dry winter cold
    24: '#320087',  # Dwd - Continental dry winter very cold
    25: '#00FFFF',  # Dfa - Continental humid hot summer
    26: '#37C8FF',  # Dfb - Continental humid warm summer
    27: '#007D7D',  # Dfc - Subarctic
    28: '#00465F',  # Dfd - Subarctic very cold
    
    # Polar (E) - Grays
    29: '#B2B2B2',  # ET - Tundra
    30: '#666666'   # EF - Ice cap
}

# Scientific legend organization
legend_data = {
    'A - Tropical': {
        'color': '#0078FF',
        'items': [
            ('Af', 'Tropical rainforest', 1),
            ('Am', 'Tropical monsoon', 2),
            ('Aw', 'Tropical savannah', 3)
        ]
    },
    'B - Arid': {
        'color': '#FF6B00',
        'items': [
            ('BWh', 'Hot desert', 4),
            ('BWk', 'Cold desert', 5), 
            ('BSh', 'Hot semi-arid', 6),
            ('BSk', 'Cold semi-arid', 7)
        ]
    },
    'C - Temperate': {
        'color': '#32CD32',
        'items': [
            ('Csa', 'Mediterranean hot summer', 8),
            ('Csb', 'Mediterranean warm summer', 9),
            ('Cwa', 'Humid subtropical', 11),
            ('Cwb', 'Subtropical highland', 12),
            ('Cfa', 'Humid subtropical', 14),
            ('Cfb', 'Oceanic', 15)
        ]
    },
    'D - Cold': {
        'color': '#4682B4',
        'items': [
            ('Dwa', 'Cold dry winter hot', 21),
            ('Dwb', 'Cold dry winter warm', 22),
            ('Dfa', 'Cold humid hot summer', 25),
            ('Dfb', 'Cold humid warm summer', 26)
        ]
    },
    'E - Polar': {
        'color': '#808080',
        'items': [
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

def create_optimized_scientific_layout(tif_paths, output_path, show_sites=True, show_labels=True):
    """Create optimized scientific layout using full canvas"""
    
    # Larger canvas with better space utilization
    total_width, total_height = 2000, 1400
    map_width, map_height = 600, 700  # Larger maps
    top_margin = 80
    side_margin = 50
    map_spacing = 60
    
    dwg = svgwrite.Drawing(output_path, size=(total_width, total_height))
    
    # White background
    dwg.add(dwg.rect(insert=(0, 0), size=(total_width, total_height), fill='white'))
    
    # Main title
    dwg.add(dwg.text(
        'Köppen-Geiger Climate Classification: Southern Africa',
        insert=(total_width // 2, 35),
        text_anchor='middle',
        font_family='Arial, sans-serif',
        font_size='24px',
        fill='#2c3e50',
        font_weight='bold'
    ))
    
    # Subtitle
    dwg.add(dwg.text(
        'Climate Change Projections for CCSA Study Sites',
        insert=(total_width // 2, 60),
        text_anchor='middle',
        font_family='Arial, sans-serif',
        font_size='16px',
        fill='#7f8c8d'
    ))
    
    # Process each time period
    titles = ['Current Climate\n1991-2020 Baseline', 'Moderate Warming\nSSP1-2.6 2041-2070', 'Extreme Warming\nSSP1-2.6 2071-2099']
    scenario_colors = ['#27ae60', '#f39c12', '#e74c3c']  # Scientific green, orange, red
    
    for i, (tif_path, title, color) in enumerate(zip(tif_paths, titles, scenario_colors)):
        if not os.path.exists(tif_path):
            continue
            
        x_offset = side_margin + i * (map_width + map_spacing)
        y_offset = top_margin + 40
        
        print(f"Processing {tif_path}...")
        
        with rasterio.open(tif_path) as src:
            # Southern Africa focus
            window = from_bounds(10.0, -35.0, 40.0, -5.0, src.transform)
            data = src.read(1, window=window)
            transform = src.window_transform(window)
            
            height, width = data.shape
            west, north = transform * (0, 0)
            east, south = transform * (width, height)
        
        # Map border
        dwg.add(dwg.rect(
            insert=(x_offset - 2, y_offset - 2),
            size=(map_width + 4, map_height + 4),
            fill='none',
            stroke='#2c3e50',
            stroke_width=2
        ))
        
        # Process climate zones
        sample_factor = max(1, width // 400)
        
        for climate_value in sorted(np.unique(data[data > 0])):
            if climate_value in koppen_colors:
                mask = (data == climate_value).astype(np.uint8)
                
                try:
                    polygon_gen = shapes(mask, mask=mask, transform=transform)
                    polygons = []
                    
                    for geom, value in polygon_gen:
                        if value == 1:
                            poly = shape(geom)
                            if poly.area > 0.005:  # Filter small artifacts
                                polygons.append(poly)
                    
                    if polygons:
                        merged = unary_union(polygons)
                        
                        if hasattr(merged, 'geoms'):
                            for poly in merged.geoms:
                                svg_path = create_svg_path(poly, west, east, north, south, map_width, map_height)
                                if svg_path:
                                    dwg.add(dwg.path(
                                        d=svg_path,
                                        fill=koppen_colors[climate_value],
                                        stroke='none',
                                        transform=f'translate({x_offset}, {y_offset})'
                                    ))
                        else:
                            svg_path = create_svg_path(merged, west, east, north, south, map_width, map_height)
                            if svg_path:
                                dwg.add(dwg.path(
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
                
                # White circle with black border (standard scientific style)
                dwg.add(dwg.circle(
                    center=(x_offset + x, y_offset + y),
                    r=8,
                    fill='white',
                    stroke='black',
                    stroke_width=2
                ))
                
                # Label if requested
                if show_labels:
                    # White background for text readability
                    text_width = len(site['name']) * 7
                    dwg.add(dwg.rect(
                        insert=(x_offset + x - text_width//2 - 3, y_offset + y - 25),
                        size=(text_width + 6, 16),
                        fill='white',
                        stroke='black',
                        stroke_width=1,
                        opacity=0.9
                    ))
                    
                    dwg.add(dwg.text(
                        site['name'],
                        insert=(x_offset + x, y_offset + y - 12),
                        text_anchor='middle',
                        font_family='Arial, sans-serif',
                        font_size='12px',
                        fill='black',
                        font_weight='bold'
                    ))
        
        # Scenario title box
        title_lines = title.split('\n')
        title_box_height = 45
        title_y = y_offset - title_box_height - 10
        
        dwg.add(dwg.rect(
            insert=(x_offset, title_y),
            size=(map_width, title_box_height),
            fill=color,
            stroke='#2c3e50',
            stroke_width=1
        ))
        
        dwg.add(dwg.text(
            title_lines[0],
            insert=(x_offset + map_width//2, title_y + 18),
            text_anchor='middle',
            font_family='Arial, sans-serif',
            font_size='16px',
            fill='white',
            font_weight='bold'
        ))
        
        dwg.add(dwg.text(
            title_lines[1],
            insert=(x_offset + map_width//2, title_y + 35),
            text_anchor='middle',
            font_family='Arial, sans-serif',
            font_size='13px',
            fill='white'
        ))
    
    # Köppen-Geiger legend (optimized spacing)
    legend_start_y = y_offset + map_height + 40
    
    # Legend title
    dwg.add(dwg.text(
        'Köppen-Geiger Climate Classification',
        insert=(total_width // 2, legend_start_y),
        text_anchor='middle',
        font_family='Arial, sans-serif',
        font_size='18px',
        fill='#2c3e50',
        font_weight='bold'
    ))
    
    # Legend groups in horizontal layout
    legend_y = legend_start_y + 30
    group_width = (total_width - 2 * side_margin) // len(legend_data)
    
    for i, (group_name, group_info) in enumerate(legend_data.items()):
        group_x = side_margin + i * group_width
        
        # Group header
        dwg.add(dwg.text(
            group_name,
            insert=(group_x + group_width//2, legend_y),
            text_anchor='middle',
            font_family='Arial, sans-serif',
            font_size='14px',
            fill='#2c3e50',
            font_weight='bold'
        ))
        
        # Legend items
        item_y = legend_y + 25
        for code, description, value in group_info['items']:
            if value in koppen_colors:
                # Color swatch
                dwg.add(dwg.rect(
                    insert=(group_x + 10, item_y - 10),
                    size=(18, 14),
                    fill=koppen_colors[value],
                    stroke='#333',
                    stroke_width=0.5
                ))
                
                # Code
                dwg.add(dwg.text(
                    code,
                    insert=(group_x + 35, item_y - 2),
                    font_family='Arial, sans-serif',
                    font_size='11px',
                    fill='black',
                    font_weight='bold'
                ))
                
                # Description
                dwg.add(dwg.text(
                    description,
                    insert=(group_x + 35, item_y + 10),
                    font_family='Arial, sans-serif',
                    font_size='10px',
                    fill='#555'
                ))
                
                item_y += 25
    
    # Data source and citation (bottom)
    citation_y = total_height - 80
    
    dwg.add(dwg.text(
        'Data Source',
        insert=(total_width // 2, citation_y),
        text_anchor='middle',
        font_family='Arial, sans-serif',
        font_size='14px',
        fill='#2c3e50',
        font_weight='bold'
    ))
    
    dwg.add(dwg.text(
        'Beck, H.E. et al. (2023). High-resolution (1 km) Köppen-Geiger maps for 1901–2099 based on constrained CMIP6 projections.',
        insert=(total_width // 2, citation_y + 20),
        text_anchor='middle',
        font_family='Arial, sans-serif',
        font_size='11px',
        fill='#7f8c8d'
    ))
    
    dwg.add(dwg.text(
        'Scientific Data 10, 724. DOI: 10.1038/s41597-023-02549-6',
        insert=(total_width // 2, citation_y + 35),
        text_anchor='middle',
        font_family='Arial, sans-serif',
        font_size='11px',
        fill='#7f8c8d'
    ))
    
    # Research context
    dwg.add(dwg.text(
        'Climate Centre for Southern Africa • Wellcome Trust Grant Application',
        insert=(total_width // 2, citation_y + 55),
        text_anchor='middle',
        font_family='Arial, sans-serif',
        font_size='10px',
        fill='#95a5a6',
        font_style='italic'
    ))
    
    dwg.save()
    print(f"Created optimized scientific layout: {output_path}")

def main():
    base_dir = "/Users/craig/Library/Mobile Documents/com~apple~CloudDocs/RP2_presentation/presentation_assets/images/koppen_extracted"
    output_dir = "/Users/craig/Library/Mobile Documents/com~apple~CloudDocs/RP2_presentation/presentation_assets/images"
    
    # File paths for the three time periods
    tif_paths = [
        os.path.join(base_dir, '1991_2020', 'koppen_geiger_0p1.tif'),
        os.path.join(base_dir, '2041_2070/ssp126', 'koppen_geiger_0p1.tif'),
        os.path.join(base_dir, '2071_2099/ssp126', 'koppen_geiger_0p1.tif')
    ]
    
    # Create final versions
    create_optimized_scientific_layout(
        tif_paths,
        os.path.join(output_dir, 'koppen_final_sites_only.svg'),
        show_sites=True,
        show_labels=False
    )
    
    create_optimized_scientific_layout(
        tif_paths,
        os.path.join(output_dir, 'koppen_final_labeled.svg'),
        show_sites=True,
        show_labels=True
    )
    
    create_optimized_scientific_layout(
        tif_paths,
        os.path.join(output_dir, 'koppen_final_clean.svg'),
        show_sites=False,
        show_labels=False
    )

if __name__ == "__main__":
    main()