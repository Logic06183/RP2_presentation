#!/usr/bin/env python3
import rasterio
import numpy as np
import svgwrite
from rasterio.windows import from_bounds
from rasterio.features import shapes
from shapely.geometry import shape, Point
from shapely.ops import unary_union
import os

# Study sites
study_sites = [
    {'name': 'Cape Town', 'lat': -33.9249, 'lon': 18.4241},
    {'name': 'Mount Darwin', 'lat': -16.7833, 'lon': 31.5833}, 
    {'name': 'Blantyre', 'lat': -15.7870, 'lon': 35.0055}
]

# Köppen color mapping
koppen_colors = {
    1: '#0000FF',   # Af - Tropical rainforest
    2: '#0078FF',   # Am - Tropical monsoon
    3: '#46AAFA',   # Aw - Tropical savannah
    4: '#FF0000',   # BWh - Arid desert hot
    5: '#FF9696',   # BWk - Arid desert cold
    6: '#F5A500',   # BSh - Arid steppe hot
    7: '#FFDC64',   # BSk - Arid steppe cold
    8: '#FFFF00',   # Csa - Mediterranean hot summer
    9: '#C8C800',   # Csb - Mediterranean warm summer
    10: '#969600',  # Csc - Mediterranean cold summer
    11: '#96FF96',  # Cwa - Humid subtropical
    12: '#64C864',  # Cwb - Subtropical highland
    13: '#329632',  # Cwc - Temperate dry winter cold
    14: '#C8FF50',  # Cfa - Humid subtropical no dry season
    15: '#64FF50',  # Cfb - Oceanic
    16: '#32C800',  # Cfc - Subpolar oceanic
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
    29: '#B2B2B2',  # ET - Tundra
    30: '#666666'   # EF - Ice cap
}

def coords_to_svg(lon, lat, west, east, north, south, svg_width, svg_height):
    """Convert geographic coordinates to SVG coordinates"""
    x = ((lon - west) / (east - west)) * svg_width
    y = ((north - lat) / (north - south)) * svg_height
    return x, y

def create_vectorized_svg(tif_path, output_path, title, show_sites=True, show_labels=True):
    """Create vectorized SVG from Köppen-Geiger data using polygon boundaries"""
    
    print(f"Processing {tif_path}...")
    
    with rasterio.open(tif_path) as src:
        # Southern Africa bounds
        window = from_bounds(10.0, -35.0, 40.0, -5.0, src.transform)
        data = src.read(1, window=window)
        transform = src.window_transform(window)
        
        height, width = data.shape
        west, north = transform * (0, 0)
        east, south = transform * (width, height)
        
        print(f"Data shape: {height}x{width}, Bounds: {west:.2f}, {south:.2f}, {east:.2f}, {north:.2f}")
    
    # SVG setup
    svg_width, svg_height = 1200, 900
    dwg = svgwrite.Drawing(output_path, size=(svg_width, svg_height))
    
    # Background
    dwg.add(dwg.rect(insert=(0, 0), size=(svg_width, svg_height), fill='#e6f3ff'))
    
    # Convert raster to vector polygons for each climate zone
    for climate_value in sorted(np.unique(data[data > 0])):
        if climate_value in koppen_colors:
            # Create mask for this climate zone
            mask = (data == climate_value).astype(np.uint8)
            
            # Extract polygon shapes from raster
            polygon_generator = shapes(mask, mask=mask, transform=transform)
            polygons = []
            
            for geom, value in polygon_generator:
                if value == 1:  # Only process polygons with the climate value
                    poly = shape(geom)
                    if poly.area > 0.01:  # Filter out tiny polygons
                        polygons.append(poly)
            
            # Merge overlapping polygons
            if polygons:
                try:
                    merged_poly = unary_union(polygons)
                    
                    # Convert to SVG paths
                    if hasattr(merged_poly, 'geoms'):  # MultiPolygon
                        for poly in merged_poly.geoms:
                            svg_path = create_svg_path(poly, west, east, north, south, svg_width, svg_height)
                            if svg_path:
                                dwg.add(dwg.path(
                                    d=svg_path,
                                    fill=koppen_colors[climate_value],
                                    stroke='none',
                                    opacity=0.8
                                ))
                    else:  # Single Polygon
                        svg_path = create_svg_path(merged_poly, west, east, north, south, svg_width, svg_height)
                        if svg_path:
                            dwg.add(dwg.path(
                                d=svg_path,
                                fill=koppen_colors[climate_value],
                                stroke='none',
                                opacity=0.8
                            ))
                except Exception as e:
                    print(f"Error processing climate zone {climate_value}: {e}")
    
    # Add study sites
    if show_sites:
        for site in study_sites:
            x, y = coords_to_svg(site['lon'], site['lat'], west, east, north, south, svg_width, svg_height)
            
            # Site marker
            dwg.add(dwg.circle(
                center=(x, y),
                r=8,
                fill='#000',
                stroke='#fff',
                stroke_width=3
            ))
            
            # Label if requested
            if show_labels:
                # Background for text
                text_width = len(site['name']) * 8
                dwg.add(dwg.rect(
                    insert=(x - text_width//2, y - 25),
                    size=(text_width, 18),
                    fill='white',
                    fill_opacity=0.9,
                    stroke='#ccc',
                    rx=3
                ))
                
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
    title_width = len(title) * 12
    dwg.add(dwg.rect(
        insert=(svg_width//2 - title_width//2, 5),
        size=(title_width, 35),
        fill='white',
        fill_opacity=0.95,
        stroke='#ccc',
        rx=5
    ))
    
    dwg.add(dwg.text(
        title,
        insert=(svg_width // 2, 28),
        text_anchor='middle',
        font_family='Arial, sans-serif',
        font_size='18px',
        fill='#333',
        font_weight='bold'
    ))
    
    dwg.save()
    print(f"Created {output_path}")

def create_svg_path(polygon, west, east, north, south, svg_width, svg_height):
    """Convert shapely polygon to SVG path string"""
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
                path_data.append(f"M {x:.2f} {y:.2f}")
            else:
                path_data.append(f"L {x:.2f} {y:.2f}")
        
        path_data.append("Z")  # Close path
        return " ".join(path_data)
        
    except Exception as e:
        print(f"Error creating SVG path: {e}")
        return None

def main():
    base_dir = "/Users/craig/Library/Mobile Documents/com~apple~CloudDocs/RP2_presentation/presentation_assets/images/koppen_extracted"
    output_dir = "/Users/craig/Library/Mobile Documents/com~apple~CloudDocs/RP2_presentation/presentation_assets/images"
    
    periods = [
        ('1991_2020', '1991-2020 (Baseline)'),
        ('2041_2070/ssp126', '2041-2070 (SSP1-2.6)'),
        ('2071_2099/ssp126', '2071-2099 (SSP1-2.6)')
    ]
    
    for period_dir, title in periods:
        # Use the highest resolution data available
        tif_path = os.path.join(base_dir, period_dir, 'koppen_geiger_0p00833333.tif')
        
        if os.path.exists(tif_path):
            period_name = period_dir.replace('/', '_').replace('-', '_')
            
            # Version 1: Sites only (no labels)
            create_vectorized_svg(
                tif_path,
                os.path.join(output_dir, f'koppen_vector_{period_name}_sites_only.svg'),
                title,
                show_sites=True,
                show_labels=False
            )
            
            # Version 2: Sites with labels
            create_vectorized_svg(
                tif_path,
                os.path.join(output_dir, f'koppen_vector_{period_name}_labeled.svg'),
                title,
                show_sites=True,
                show_labels=True
            )
            
            # Version 3: Clean (no sites)
            create_vectorized_svg(
                tif_path,
                os.path.join(output_dir, f'koppen_vector_{period_name}_clean.svg'),
                title,
                show_sites=False,
                show_labels=False
            )

if __name__ == "__main__":
    main()